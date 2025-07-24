function Start-AzVm {
	# Supply a VM name (or an unambiguous part of it) and start the machine.
	<#
	.SYNOPSIS
	Start an Azure VM whose name contains the input string.
	
	.DESCRIPTION
	If we can unambiguously determine a single VM name inside the subscription
	we are logged into through the input string, we will stop and deallocate
	the machine.
	
	This function was built as we want to have terse input and a counterpart
	to Stop-AzVm.
	
	.INPUTS
	String. The name or unambiguous part of the name of the VM we intend to
	start.
	
	.OUTPUTS
	String. Status messages and the actual AzureCLI outputs.
	#>
	Param (
		[Parameter(
			Mandatory=$true,
			ValueFromPipelineByPropertyName=$true,
			HelpMessage="String that is a VM name or is part of one unambiguous VM",
			Position=0
			)
		]
		[ValidateLength(1,64)]
		[string]
        $VmName
	)
	$ErrorActionPreference = 'Stop'
	$myvm = azvmidentify -VmName $VmName
	# Since az vm start is taking quite its time even when the machine is started, we should check ourselves whether the machine is running:
	if ( (az vm show -d -g $myvm.resourceGroup -n $myvm.name -o json | COnvertFrom-Json).powerState.Contains('running')) {
		Write-Host "VM $($myvm.name) (RG: $($myvm.resourceGroup)) is already running."
	} else {
		Write-Host "Starting $($myvm.name) (RG: $($myvm.resourceGroup)):"
		az vm start -g $myvm.resourceGroup -n $myvm.name
		Write-Host "...done."
	}
}