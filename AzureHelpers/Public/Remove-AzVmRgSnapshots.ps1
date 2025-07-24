function Remove-AzVmRgSnapshot {
	<#
	.SYNOPSIS
	Delete a snapshot inside the resource group an Azure VM is living in.
	
	.DESCRIPTION
	If we can unambiguously determine a single VM name inside the subscription
	we are logged into through the input string, we will remove a snapshot
	with a given name.
	
	.INPUTS
	System.Object. @{ VmName = VMNAME; SnapshotName = SNAPSHOTNAME }
	
	.OUTPUTS
	String. Status messages and the actual AzureCLI outputs.
	#>
	[Alias(
		'Delete-AzVmOsSnapshot',
		'azvmsnapdel'
	)]
	Param(
		[Parameter(
			Mandatory=$true,
			ValueFromPipelineByPropertyName=$true,
			HelpMessage="String that is a VM name or is part of one unambiguous VM",
			Position=0
			)
		]
		[ValidateLength(1,64)]
		[string]
        $VmName,
		[Parameter(
			Mandatory=$true,
			ValueFromPipelineByPropertyName=$true,
			HelpMessage="Name of the snapshot",
			Position=1
			)
		]
		[ValidateLength(1,64)]
		[string]
        $SnapshotName
	)
	$ErrorActionPreference = 'Stop'
	$myvm = Find-AzVm -VmName $VmName
	Write-Host "Identified VM: ${myvm.name}"
	Write-Host "Deleting OS disk snapshot `"${SnapshotName}`""
	az snapshot delete -o jsonc -g $myvm.resourceGroup --name $SnapshotName
}