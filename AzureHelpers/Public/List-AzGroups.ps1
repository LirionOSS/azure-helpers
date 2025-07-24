function List-AzGroups {
	<#
	.SYNOPSIS
	List all resource groups inside the Azure subscription we are logged into.
	
	.DESCRIPTION
	This simply uses `az group list` with a few parameters. Main purpose: coloured
	and terse output.
	
	.INPUTS
	None. (Also, no parameters.)
	
	.OUTPUTS
	String. A coloured JSON output showing a more or less terse list of VMs.
	#>
	[Alias(
		'azgrouplist',
		'azrgl'
	)]
	Param (
	)
	az group list -o jsonc --query '[].{id: id, location: location, managedBy: managedBy, properties: properties, tags: tags}'
}