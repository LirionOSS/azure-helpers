function List-AzVms {
	<#
	.SYNOPSIS
	List all VMs inside the Azure subscription we are logged into.
	
	.DESCRIPTION
	This simply uses `az vm list` with a few parameters. Main purpose: coloured
	and terse output.
	
	.INPUTS
	None. (Also, no parameters.)
	
	.OUTPUTS
	String. A coloured JSON output showing a more or less terse list of VMs.
	#>
	[Alias(
		'azvmlist',
		'azvml'
	)]
	# PowerShell will throw an exception "Unexpected attribute 'Alias'." if you don't define Param() below. If you do, everything is fine.
	# POWERSHELL IS SO SOPHISTICATED AND GOOD, the number of times I've heard this bollocks definitely equals the quality
	Param(
	)
	az vm list -o jsonc --query '[].{name: name,resourceGroup: resourceGroup,tenantId: identity.tenantId,principalId: identity.principalId}'
}