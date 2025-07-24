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
	String. The name or unambiguous part of the name of the VM we intend to
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
	# Since az vm stop is taking quite its time even when the machine is started, we should check ourselves whether the machine is running:
	$myPowerState = (az vm show -d -g $myvm.resourceGroup -n $myvm.name -o json | ConvertFrom-Json).powerState
	if ( ($myPowerState -match '(stopped|deallocated)$') ) {
		Write-Host "VM $($myvm.name) (RG: $($myvm.resourceGroup)) is already stopped."
	} else {
		Write-Host "Stopping $($myvm.name) (RG: $($myvm.resourceGroup)):"
		az vm stop -g $myvm.resourceGroup -n $myvm.name
		Write-Host "...done."
	}
	if ( ($myPowerState -match 'deallocated$') ) {
		Write-Host "VM $($myvm.name) (RG: $($myvm.resourceGroup)) is already deallocated."
	} else {
		Write-Host "Deallocating $($myvm.name) (RG: $($myvm.resourceGroup)):"
		az vm deallocate -g $myvm.resourceGroup -n $myvm.name
		Write-Host "...done."
	}
}