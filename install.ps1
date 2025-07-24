#!powershell
# vim:syntax=ps1:ts=4

# We deploy to the user directory (yep, Documents, cheers MS :D):
$UserPSPath	= "${env:USERPROFILE}\Documents\WindowsPowerShell"
$ModulePath	= "${UserPSPath}\Modules"
# $InstPath	= "${ModulePath}\hpf-cons"

$instMods = @(
	'AzureHelpers'
)

# Where are we? (Ensures we can be called from just anywhere, the 90s want
# their "cd something && .\whatever" back.)
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition

# Ensure we stop on any error. We just write simple commands sequentially,
# so we need this.
$ErrorActionPreference = 'Stop'

if ( -not (Test-Path "$UserPSPath") ) {
	New-Item -ItemType Directory -Path "$UserPSPath"
}
if ( -not (Test-Path "$ModulePath") ) {
	New-Item -ItemType Directory -Path "$ModulePath"
}
# if ( -not (Test-Path "$InstPath") ) {
# 	New-Item -ItemType Directory -Path "$InstPath"
# }

# We could now use robocopy to ensure timestamps and stuff, but since this will
# eventually pull from git, this is irrelevant - so we can resort to the more
# primitive .NET-Cmdlets.
# To ensure files that don't exist anymore, we'd need robocopy again :-)
foreach ($instMod in $instMods) {
	Write-Host "Copying items..."
	Copy-Item -Recurse -Path "${scriptPath}\${instMod}" -Destination "$ModulePath" -Force
	Write-Host "...done."
}

# Done!
