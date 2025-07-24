#!powershell
# vim:syntax=ps1:ts=4
# Do not remove the shebang or vim lines above. It helps software
# (e.g. Notepad++ or rouge-based, not only vim) identifying the syntax. JUST DON'T.

# This helps a user creating a base module structure.

<#
	.SYNOPSIS
	
	Helps a user create a PowerShell module.
	
	.DESCRIPTION
	
	This script helps creating a base module structure, creating folders and some
	base files.
	
	.EXAMPLE
	
	PS> .\moduleHelper.ps1 -ModuleName 'FooBar' -ModuleAuthor 'LaFoo Barson' -ModuleDescription "I foo'ed a bar."
	
	.LINK
	
	https://ramblingcookiemonster.github.io/Building-A-PowerShell-Module/
#>

Param (
	[Parameter(
		Mandatory=$true,
		ValueFromPipelineByPropertyName=$true,
		HelpMessage="The name of the module to create inside this folder.",
		Position=0
		)
	]
	[ValidateLength(1,64)]
	[string]
	$ModuleName,
	[Parameter(
		Mandatory=$true,
		ValueFromPipelineByPropertyName=$true,
		HelpMessage="The name of the module author.",
		Position=1
		)
	]
	[ValidateLength(1,64)]
	[string]
	$ModuleAuthor,
	[Parameter(
		Mandatory=$true,
		ValueFromPipelineByPropertyName=$true,
		HelpMessage="A short description of the module. Max. 140 characters.",
		Position=2
		)
	]
	[ValidateLength(1,140)]
	[string]
	$ModuleDescription,
	[Parameter(
		Mandatory=$false,
		ValueFromPipelineByPropertyName=$true,
		HelpMessage="The name of the module to create inside this folder.",
		Position=3
		)
	]
	[ValidateLength(1,64)]
	[string]
	$CompanyName,
	[Parameter(
		Mandatory=$false,
		ValueFromPipelineByPropertyName=$true,
		HelpMessage="The module's version. Validated against being SemVer. Default: 0.1",
		Position=4
		)
	]
	[ValidateLength(1,16)]
	[string]
	$ModuleVersion = '0.1',
	[Parameter(
		Mandatory=$false,
		ValueFromPipelineByPropertyName=$true,
		HelpMessage="Link to the licence. Defaults to a Wikipedia link about proprietary software.",
		Position=5
		)
	]
	[ValidateLength(1,64)]
	[string]
	$LicenseUri = 'https://en.wikipedia.org/wiki/Proprietary_software',
	[Parameter(
		Mandatory=$false,
		ValueFromPipelineByPropertyName=$true,
		HelpMessage="Use Formats Process file? If unsure, ignore this option. If so, set to true.",
		Position=6
		)
	]
	[boolean]
	$FormatsProcess = $false,
	[Parameter(
		Mandatory=$false,
		ValueFromPipelineByPropertyName=$true,
		HelpMessage="Minimum PowerShell version this module works on. Validated against being SemVer.",
		Position=7
		)
	]
	[ValidateLength(1,16)]
	[string]
	$PSVersion = '5.1'
)

$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
# Based off https://ramblingcookiemonster.github.io/Building-A-PowerShell-Module/,
# here comes the actual "let's do this!".
$ModulePath = "${scriptPath}\$ModuleName"
# $ModuleName = 'PSStackExchange'
# $ModuleAuthor = 'RamblingCookieMonster'
$Description = 'PowerShell module to query the StackExchange API'

# The RegEx to validate version numbers against. We imply semantiv versioning, with
# or without leading "v".
[regex]$versRex = '^v?[0-9]{1,}(\.[0-9]{1,}){0,2}$'

# Never accept failures, it will lead to subsequent confusion and errors.
$ErrorActionPreference = 'Stop'

# Create the module and private function directories
# Write down the array in order of creation, i.e. DIR comes before DIR\SUBDIR.
$ModuleDirs = @(
	"$ModulePath"
	"${ModulePath}\Private"
	"${ModulePath}\Public"
	"${ModulePath}\en-US" # For about_Help files
	"${ModulePath}\Tests"
)
foreach ($ModuleDir in $ModuleDirs) {
	if ( -not (Test-Path "$ModuleDir") ) {
		New-Item -ItemType Directory -Path "$ModuleDir" | Out-Null
	}
}

#Create the module and related files
$ModuleFiles = @(
	"${ModulePath}\${ModuleName}.psd1"
	"${ModulePath}\${ModuleName}.psm1"
	"${ModulePath}\en-US\about_${ModuleName}.help.txt"
	"${ModulePath}\Tests\${ModuleName}.Tests.ps1"
)
foreach ($ModuleFile in $ModuleFiles) {
	if ( -not (Test-Path "$ModuleFile") ) {
		New-Item -ItemType File -Path $ModuleFile | Out-Null
	}
}
if ($FormatsProcess) {
	New-Item -ItemType File -Path "${ModulePath}\${ModuleName}.Format.ps1xml"
}

# Set some defaults
if ( ($ModuleVersion -eq $null) ) {
	$ModuleVersion = '0.1'
}
if ( ($LicenseUri -eq $null) ) {
	$LicenseUri = 'https://en.wikipedia.org/wiki/Proprietary_software'
}
if ( ($PSVersion -eq $null) ) {
	# Yeah, PS7 is still beta and has lots more features, but consider the conservative
	# versions that are rolled on Windows server (alongside Xbox extensions, priorities of this company...)
	# Better stick to 5 as a default. Anything earlier implies EOL systems, so NOPE.
	$PSVersion = '5.1'
}

# Input Validation
if ( -not ($ModuleVersion -match $versRex) ) {
	throw [System.ArgumentException]::New("Not a version string: ${ModuleVersion}")
}
if ( -not ($PSVersion -match $versRex) ) {
	throw [System.ArgumentException]::New("Not a version string: ${PSVersion}")
}

# The module UUID ("GUID")
# New-Guid produces an object with a single attribute, "Guid", containing the string. Here we go.
$moduleGuid = (New-Guid).Guid

# Declare the Manifest hash:
$ManifestHash = @{
	RootModule = "${ModuleName}.psm1"
	Author = $ModuleAuthor
	CompanyName = $CompanyName
	ModuleVersion = $ModuleVersion
	Guid = $moduleGuid
	PowerShellVersion = $PSVersion
	Description = $ModuleDescription
	PrivateData = @{
		PSData = @{
			LicenseUri = $LicenseUri
			# A URL to the main website for this project.
			# ProjectUri = ''
			# A URL to an icon representing this module.
			# IconUri = ''
			# ReleaseNotes of this module
			# ReleaseNotes = ''
		} # End of PSData hashtable
	} # End of PrivateData hashtable
}
if ($FormatsProcess) {
	$ManifestHash += @{ FormatsToProcess = "${ModuleName}.Format.ps1xml" }
}

# Create the Module:
# New-ModuleManifest produced a result that does not comply with the standard and fails restricted language settings.
# Lel. Since Microsoft never cared about an actual module creator and this just creates ModuleName.psd1, let's do This
# ourselves, we will not fail :-)
# New-ModuleManifest @ManifestHash
# here we go. Only caveat: ofc PS can only output well-known formats, but they HAD to have a different syntax for
# PowerShell internally.
if ( (Test-Path -Path "${ModulePath}\${ModuleName}.psd1") ) {
	Remove-Item -Force -Path "${ModulePath}\${ModuleName}.psd1"
}
($ManifestHash | ConvertTo-Json) -replace '^{','@{' -replace ':',' = ' -replace ',','' -replace '=\ +{', '= @{' | Out-File "${ModulePath}\${ModuleName}.psd1"
# Beware: this will look a bit ugly, but it will work. This is on Windows, we have no sophisticated development environments. If you want that - install Linux ;-)


# Test and output the result:
Write-Host "`nRESULT:"
Write-Host "======"
Test-ModuleManifest -Path "${ModulePath}\${ModuleName}.psd1" | Select-Object Name,Path,Description,Guid,ModuleBase,PrivateData,Version,ModuleType,Author,AccessMode,ExportedFormatFiles

# Copy the public/exported functions into the public folder, private functions into private folder