function New-AzVmOsSnapshot {
	<#
	.SYNOPSIS
	Create a snapshot of the OS disk of an Azure VM.
	
	.DESCRIPTION
	If we can unambiguously determine a single VM name inside the subscription
	we are logged into through the input string, we will create a snapshot
	of its OS disk.
	
	.INPUTS
	System.Object. @{ VmName = VMNAME; SnapshotName = SNAPSHOTNAME }
	
	.OUTPUTS
	String. Status messages and the actual AzureCLI outputs.
	#>
	[Alias(
		'Create-AzVmOsSnapshot',
		'azvmsnapshot',
		'azvmsnap'
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
	$myDisk = (az vm show -g $myvm.resourceGroup -n $myvm.name --query "storageProfile.osDisk.managedDisk.id" -o json | ConvertFrom-Json)
	Write-Host "Identified VM: ${myvm.name}"
	Write-Host "Creating OS disk snapshot `"${SnapshotName}`""
	az snapshot create -o jsonc -g $myvm.resourceGroup --source $myDisk --name $SnapshotName `
		--query '[].{creationData: creationData, diskSizeGB: diskSizeGB, encryptionType: encryption.type, hyperVGeneration: hyperVGeneration, id: id, name: name, resourceGroup: resourceGroup, publicNetworkAccess: publicNetworkAccess}'
}