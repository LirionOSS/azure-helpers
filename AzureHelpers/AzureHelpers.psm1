#!powershell
# vim:syntax=ps1:ts=4
# Source functions from elswehere.
$Private = (Get-ChildItem -Path (Join-Path $PSScriptRoot '.\Private') -Filter *.ps1)
$Public = (Get-ChildItem -Path (Join-Path $PSScriptRoot '.\Public') -Filter *.ps1 -Recurse)

foreach ($Script in $Public) {
	. $Script.FullName
	Export-ModuleMember $Script.BaseName -Alias *
}

foreach ($Script in $Private) {
	. $Script.FullName
}