function List-AzVmRgSnapshots {
	<#
	.SYNOPSIS
	List the snapshots inside the resource group an Azure VM is living in.
	
	.DESCRIPTION
	If we can unambiguously determine a single VM name inside the subscription
	we are logged into through the input string, we will list all snapshots
	inside its hosting resource group.
	
	TODO: Maybe filter by VM name (through .creationData.sourceResourceId)
	
	.INPUTS
	String. The VM name to identify the resource group by.
	
	.OUTPUTS
	String. Status messages and the actual AzureCLI outputs.
	#>
	[Alias(
		'azvmsnapshotlist',
		'azvmsnaplist'
	)]
	Param(
		[Parameter(
			Mandatory=$true,
			ValueFromPipeline=$true,
			HelpMessage="String that is a VM name or is part of one unambiguous VM",
			Position=0
			)
		]
		[ValidateLength(1,64)]
		[string]
        $VmName
	)
	$ErrorActionPreference = 'Stop'
	$myvm = Find-AzVm -VmName $VmName
	az snapshot list -o jsonc -g $myvm.resourceGroup `
		--query '[].{creationData: creationData, diskSizeGB: diskSizeGB, diskState: diskState, encryptionType: encryption.type, hyperVGeneration: hyperVGeneration, id: id, incremental: incremental, name: name, resourceGroup: resourceGroup, publicNetworkAccess: publicNetworkAccess}'
}