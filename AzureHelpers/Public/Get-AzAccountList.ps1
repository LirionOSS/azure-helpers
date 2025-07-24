function Get-AzAccountList {
	<#
	.SYNOPSIS
	Show details about all subscriptions the Azure account we are logged into has access to.
	
	.INPUTS
	None.
	
	.OUTPUTS
	String. A coloured JSON output showing a more or less terse list of subscriptions.
	#>
	[Alias(
		'getazacclist',
		'azacclist',
		'azalist'
	)]
	# PowerShell will throw an exception "Unexpected attribute 'Alias'." if you don't define Param() below. If you do, everything is fine.
	# POWERSHELL IS SO SOPHISTICATED AND GOOD, the number of times I've heard this bollocks definitely equals the quality
	Param(
	)
	az account list -o jsonc --query '[].{name: name, id: id, state: state, homeTenantId: homeTenantId, tenantId: tenantId, user: user}'
}