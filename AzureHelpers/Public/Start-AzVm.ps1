function Start-AzVm {
	# Supply a VM name (or an unambiguous part of it) and start the machine.
	<#
	.SYNOPSIS
	Start an Azure VM whose name contains the input string.
	
	.DESCRIPTION
	If we can unambiguously determine a single VM name inside the subscription
	we are logged into through the input string, we will start
	the machine.
	
	This function was built as we want to have terse input and a counterpart
	to Stop-AzVm.
	
	.INPUTS
	String. The names or unambiguous parts of the names of the VMs we intend to
	start.
	
	.OUTPUTS
	String. Status messages and the actual AzureCLI outputs.
	#>
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
	$resVms = @()
	Write-Host "Checking state of VM(s)..."
	foreach ($singlevm in $VmName) {
		$myvm = azvmidentify -VmName $singlevm
		# Since az vm start is taking quite its time even when the machine is started, we should check ourselves whether the machine is running:
		if ( (az vm show -d -g $myvm.resourceGroup -n $myvm.name -o json | COnvertFrom-Json).powerState.Contains('running')) {
			Write-Host "VM $($myvm.name) (RG: $($myvm.resourceGroup)) is already running."
		} else {
			Write-Host "VM $($myvm.name) (RG: $($myvm.resourceGroup)) is not started."
			$resVms += $myvm
		}
	}
	Write-Host "Starting remaining $($resVms.Count) machine(s)..."
	$jobs = (
		$resVms | ForEach-Object {
			# Write-Host "Starting $($_.name) (RG: $($_.resourceGroup)):"
			$myvm = $_
			Start-ThreadJob -ScriptBlock {
				$this = $using:myvm
				az vm start -o jsonc -g $this.resourceGroup -n $this.name
			}
			# Write-Host "...done."
		}
	)
	$jobs | Receive-Job -Wait -AutoRemoveJob
}
