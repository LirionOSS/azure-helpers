function Stop-AzVm {
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
			Write-Host "VM $($myvm.name) (RG: $($myvm.resourceGroup)) is already stopped."
			$deallocVms += $myvm
		} else {
			if ( ($myPowerState -match 'deallocated$') ) {
				Write-Host "VM $($myvm.name) (RG: $($myvm.resourceGroup)) is already deallocated."
			} else {
				$stopVms += $myvm
				$deallocVms += $myvm
			}
		}
	}
	Write-Host "Stopping $($stopVms.Count) machine(s)..."
	$jobs = (
		$stopVms | ForEach-Object {
			# Write-Host "Starting $($_.name) (RG: $($_.resourceGroup)):"
			$myvm = $_
			Start-ThreadJob -ScriptBlock {
				$this = $using:myvm
				# Write-Host "Stopping $($myvm.name) (RG: $($myvm.resourceGroup)):"
				az vm stop --output jsonc --resource-group $($this.resourceGroup) --name $($this.name)
				# Write-Host "...done."
			}
		}
	)
	$jobs | Receive-Job -Wait -AutoRemoveJob
	Write-Host "Deallocating $($deallocVms.Count) machine(s)..."
	$jobs = (
		$deallocVms | ForEach-Object {
			$myvm = $_
			Start-ThreadJob -ScriptBlock {
				$this = $using:myvm
				az vm deallocate --output jsonc --resource-group $($this.resourceGroup) --name $($this.name)
			}
		}
	)
	$jobs | Receive-Job -Wait -AutoRemoveJob
}
