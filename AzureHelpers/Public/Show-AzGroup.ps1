function Show-AzGroup {
	<#
	.SYNOPSIS
	List details of an Azure resource group containing an input string.

	.DESCRIPTION
	We'll find out all resource group inside the subscription we are logged into
	which contain the string $GroupName (i.e. 'yGrou' will yield 'myGroup').

	If we find more than one result, we will throw an exception telling this.

	If there is one match, a more or less terse output will be generated displaying
	the group details.	

	.INPUTS
	String. The resource group name we want to investigate. Part of the name is
	sufficient if unambiguous inside the active subscription.
	
	.OUTPUTS
	String. A coloured JSON output showing a more or less terse list of
	the resource group's parameters.
	#>
	[Alias(
		'azgroup',
		'azrg'
	)]
	Param(
		[Parameter(
			Mandatory=$true,
			ValueFromPipeline=$true,
			HelpMessage="String that is a resource group name or is part of one unambiguous RG",
			Position=0
			)
		]
		[ValidateLength(1,64)]
		[string]
        $GroupName
	)
	$groups = @()
	foreach ($group in (List-AzGroups)) {
		if ($group.name.Contains($GroupName)) {
			$groups += $group
		}
	}
	switch ($groups.Count) {
		0 {
			throw [System.ArgumentNullException]::New("No resource group found with its name containing `"$($GroupName)`"")
		}
		1 {
			$true | Out-Null
		}
		Default {
			throw [System.ArgumentException]::New("More than one resource group found with their names containing `"$($GroupName)`"")
		}
	}
	az group show -g $group[0].name --query '{id: id, location: location, managedBy: managedBy, properties: properties, tags: tags}'
}