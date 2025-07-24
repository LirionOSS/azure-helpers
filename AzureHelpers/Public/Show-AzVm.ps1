function Show-AzVm {
	<#
	.SYNOPSIS
	List all details of an Azure VM whose name contains an input string.

	.DESCRIPTION
	We'll find out all VMs inside the subscription we are logged into
	which contain the string $VmName (i.e. 'yVirtua' will yield 'myVirtualMachine').

	If we find more than one result, we will throw an exception telling this.

	If there is one match, a more or less terse output will be generated displaying
	the VM details.	

	.INPUTS
	String. The VM name we want to investigate. Part of the name is sufficient if
	unambiguous inside the active subscription.
	
	.OUTPUTS
	String. A coloured JSON output showing a more or less terse list of
	the virtual machine's parameters.
	#>
	[Alias(
		'azvmdeets',
		'azvmdetails',
		'azvmd'
	)]
	Param(
		[Parameter(
			Mandatory=$true,
			ValueFromPipeline=$true,
			HelpMessage="Exact name of a VM",
			Position=0
			)
		]
		[ValidateLength(1,64)]
		[string]
        $VmName
	)
	foreach ($myvm in $VmName) {
		# az vm list -d -o jsonc --query "[?name == `'$myvm`']" `
		# 	| ConvertFrom-Json `
		# 	| Select-Object name,powerState,privateIps,publicIps,resourceGroup,tags
		# Something like a zone also doesn't come with list -d, we need show for THAT,
		# and show needs the resource group.
		# also, az vm list -d is raging slow (5+ seconds at times).
		# ALSO, az vm show -d is raging slow.
		# We need one of these to see BASIC stuff like IPs or power state. Cheerio.
		# So: list the VM with the name, extract resource group, switch to az vm show.
		$resvms = (az vm list -d -o jsonc --query "[?name == `'$myvm`']" | ConvertFrom-Json) `
			| Select-Object name,resourceGroup,powerState,privateIps,publicIps
		if ( [String]$resvms.GetType() -ne 'System.Management.Automation.PSCustomObject' ) {
			foreach ($resvm in $resvms) {
				az vm show -d -g $resvm.resourceGroup -n $resvm.name -o jsonc `
					--query '{name: name, id: id, powerState: powerState, resourceGroup: resourceGroup, zones: zones, privateIps: privateIps, publicIps: publicIps, tags: tags}'
				# $resvm | Select-Object powerState,privateIps,publicIps
			}
		} else {
			az vm show -d -g $resvms.resourceGroup -n $resvms.name -o jsonc `
				--query '{name: name, id: id, powerState: powerState, resourceGroup: resourceGroup, zones: zones, privateIps: privateIps, publicIps: publicIps, tags: tags}'
			# $resvms | Select-Object powerState,privateIps,publicIps
		}
	}
}