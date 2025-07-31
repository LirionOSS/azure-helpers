function Stop-AzureVm {
	# Supply a VM name (or an unambiguous part of it), stop, and deallocate the machine.
	<#
	.SYNOPSIS
	Stop **and** deallocate an Azure VM whose name contains the input string.
	
	.DESCRIPTION
	If we can unambiguously determine a single VM name inside the subscription
	we are logged into through the input string, we will stop and deallocate
	the machine.
	
	This function was built as we want to have terse input and we do not want to
	be billed for machines we stop, the latter requiring two actual commands.
	
	.INPUTS
	String. The names or unambiguous parts of the names of the VMs we intend to
	stop and deallocate.
	
	.OUTPUTS
	String. Status messages and the actual AzureCLI outputs.
	#>
	[Alias(
		'azvmstop',
		'azvmd',
		'Deallocate-AzVm'
	)]
	Param (
		[Parameter(
			Mandatory=$true,
			ValueFromPipelineByPropertyName=$true,
			HelpMessage="Strings that are VM names or are part of single unambiguous VMs",
			Position=0
			)
		]
		[ValidateLength(1,64)]
		[string[]]
		$VmName
	)
	$ErrorActionPreference = 'Stop'
	$stopVms = @()
	$deallocVms = @()
	Write-Host "Checking state of VM(s)..."
	foreach ($singlevm in $VmName) {
		$myvm = azvmidentify -VmName $singlevm
		# Since az vm stop is taking quite its time even when the machine is started, we should check ourselves whether the machine is running:
		$myPowerState = (az vm show -d -g $myvm.resourceGroup -n $myvm.name -o json | ConvertFrom-Json).powerState
		if ( ($myPowerState -match 'stopped$') ) {
			Write-Verbose "VM $($myvm.name) (RG: $($myvm.resourceGroup)) is already stopped."
			$deallocVms += $myvm
		} else {
			if ( ($myPowerState -match 'deallocated$') ) {
				Write-Verbose "VM $($myvm.name) (RG: $($myvm.resourceGroup)) is already deallocated."
			} else {
				$stopVms += $myvm
				$deallocVms += $myvm
			}
		}
	}
	Write-Host "Stopping $($stopVms.Count) machine(s)..."
	$jobs = (
		$stopVms | ForEach-Object {
			$myvm = $_
			Write-Verbose "Triggering stop of $($myvm.name) (RG: $($myvm.resourceGroup))..."
			Start-ThreadJob -ScriptBlock {
				$this = $using:myvm
				Write-Verbose "DEBUG: Threaded job got VM $($this.name) (RG: $($this.resourceGroup))..."
				# Sometimes az vm stop bugs out (it's Microsoft _and_ Azure, no surprises here) - so
				# for this command, we ignore errors %-) (read: do still complain, but continue).
				# Also, maybe it's not AzureCLI entirely:
				# "When an application prints to standard error, PowerShell will sometimes conclude that
				# application has failed. This is actually a design decision made by PowerShell developers.
				# IMHO, this is a mistake, because many reliable applications (such as curl) print useful
				# information to standard error in the course of normal operation. The consequence is that
				# PowerShell only plays well with other PowerShell scripts and can't be relied on to
				# interoperate with other applications. (https://stackoverflow.com/a/11826589)
				# Point of notice: it might be the warning(!) issued by az vm stop about a necessary deallocation.
				# POWERSHELL IS SO WELL DEVELOPED [1001]
				# Let's do both - Error handling and redirecting stderr to stdout. PS is chaos, face it with chaos.
				# TODO: Maybe the ErrorActionPreference has to be around the $jobs call? (Still due to
				# the reasons mentioned above.)
				$ErrorActionPreference = 'Continue'
				az vm stop --output jsonc --resource-group $($this.resourceGroup) --name $($this.name) 2>&1
				$ErrorActionPreference = 'Stop'
			}
		}
	)
	$jobs | Receive-Job -Wait -AutoRemoveJob
	Write-Host "Deallocating $($deallocVms.Count) machine(s)..."
	$jobs = (
		$deallocVms | ForEach-Object {
			$myvm = $_
			Write-Verbose "Triggering deallocation of $($myvm.name) (RG: $($myvm.resourceGroup))..."
			Start-ThreadJob -ScriptBlock {
				$this = $using:myvm
				Write-Verbose "DEBUG: Threaded job got VM $($this.name) (RG: $($this.resourceGroup))..."
				az vm deallocate --output jsonc --resource-group $($this.resourceGroup) --name $($this.name)
			}
		}
	)
	$jobs | Receive-Job -Wait -AutoRemoveJob
	Write-Host "...everything done."
}
