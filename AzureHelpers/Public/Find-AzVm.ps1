function Find-AzVm {
	<#
	.SYNOPSIS
	Return an Azure VM object if we find exactly one match for a given VM name string.

	.DESCRIPTION
	We'll search for all VMs inside the subsctription we are logged into containing
	the input string. If we find exactly one match, we will output an object as
	delivered by `az vm list`.

	.EXAMPLE
		Find-AzVm -VmName "substring-01"

	.INPUTS
	String. The VM name we want to investigate. Part of the name is sufficient if
	unambiguous inside the active subscription.

	.OUTPUTS
	PSCustomObject. `az vm list` object of the resulting Azure virtual machine.	
	#>
	[OutputType([PSCustomObject])]
	[Alias(
		'azvmidentify',
		'azvmf',
		'azvmi'
	)]
	Param (
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
	$count = 0
	$result = @()
	foreach ($myvm in (List-AzVms | ConvertFrom-Json) ) {
		if ($myvm.name.Contains($VmName)) {
			$count++
			$result += $myvm
		}
	}
	switch ($result.Count) {
		0 {
			throw [System.ArgumentNullException]::New("No VM found with its name containing `"$($VmName)`"")
		}
		1 {
			$true | Out-Null
		}
		Default {
			throw [System.ArgumentException]::New("More than one VM found with their names containing `"$($VmName)`"")
		}
	}
	# We throw exceptions whenever we don't have exactly one element - here we return the first element as there
	# should be only one at this stage.
	# Also, Powershell (again!): If you "return" something from a function anything else that produces output
	# will also be returned. Why, Microsoft, why ლ(ಠ_ಠლ)
	# > PowerShell has really wacky return semantics - at least when viewed from a more traditional programming perspective. There are two main ideas to wrap your head around:
	# >   * All output is captured, and returned
    # >   * The return keyword really just indicates a logical exit point
	# ( https://stackoverflow.com/a/10288256 )
	# This sorry state of a "shell" or "programming language" ...
	return $result[0]
}