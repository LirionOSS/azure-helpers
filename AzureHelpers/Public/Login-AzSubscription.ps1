function Login-AzSubscription {
	<#
	.SYNOPSIS
		Log in to a predefined set of tenants+subscription combinations.
		
	.DESCRIPTION
		The sets define abstract subscription "shortnames" which will also
		yield its tenant. To find out which just use tabulator expansion.
		
		This function eases the login procedure. While Azure and AzureCLI
		are still beta implementations, we need to work around a lot of
		stuff, which is why this function has grown quite some in size.
		Its usage will remain easy, however :-)
		
		We expect ./private/vars.ps1 to be populated. It consists of:
		  - [Hashtable]$tenantMap = @{ subscrName = tenantUUID; ... }
		  - [Hashtable]$subscrMap = @{ subscrName = subscriptionUUID; ... }
		 (subscrName is a name chosen by you, it can be the actual name or
		  some mnemonic, whatever you prefer. The UUID(GUID) is the one in Azure.)
		
	.EXAMPLE
		Login-AzSubscription mysubscription
	
	.PARAMETER subscrName
	The subscription name. Its mapping has to exist in ./private/vars.ps1
	(the module containing this function is delivered with an example).
	#>
	[Alias(
		'Login-AzTenant',
		'azlogin'
	)]
	Param (
		[Parameter(
			Mandatory=$true,
			ValueFromPipeline=$true,
			HelpMessage="The name (our alias) of the subscription you intend to login to.",
			Position=0
			)
		]
		[ValidateLength(1,64)]
		[string]
		# [azSubscriptions]
        $subscrName
		# $subscrEnum
	)
	# # Since PowerShell Enum doesn't give a fuck about sub-types, we better cast to string here.
	# # Before, we tried to access $tenantMap[$subscrEnum] below and failed, so better keep it that way :-)
	# $subscrName = [String]$subscrEnum
	[regex]$uuidRex = '(?im)^[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}$'
	if ( -not $tenantMap.Contains($subscrName) ) {
		Write-Host "Exception. Did you populate /private/vars.ps1?"
		throw [System.ArgumentException]::New("Known tenants do not include `"$($SubscrName)`"!")
	}
	if ( -not $subscrMap.Contains($subscrName) ) {
		Write-Host "Exception. Did you populate /private/vars.ps1?"
		throw [System.ArgumentException]::New("Known subscriptionss do not include `"$($SubscrName)`"!")
	}
	# PowerShell again: The below simple statement in any other language would work. Here you receive
	# "System.Collections.Hashtable[learn]" instead of the value string assigned to key $TenantName:
	# az login --tenant $tenantMap[$TenantName]
	# ...here, we need an additional detour and assignment (WiP):
	$tuuid = [String]$tenantMap[$subscrName]
	if ( -not ($tuuid -match $uuidRex) ) {
		# PowerShell again. Cannot just combine strings with strings directly (like "value of variable: ${variable}, right here").
		# Most languages can. PS can't.
		$throwstr = "Tenant ID string is not a UUID! ("
		$throwstr += $tuuid
		$throwstr += ")"
		throw [System.ArgumentException]::New($throwstr)
	}
	$suuid = [String]$subscrMap[$subscrName]
	if ( -not ($suuid -match $uuidRex) ) {
		# PowerShell again. Cannot just combine strings with strings directly (like "value of variable: ${variable}, right here").
		# Most languages can. PS can't.
		$throwstr = "Subscription ID string is not a UUID! ("
		$throwstr += $suuid
		$throwstr += ")"
		throw [System.ArgumentException]::New($throwstr)
	}
	if ( ((az account list --only-show-errors -o json) | ConvertFrom-Json).Count -ne 0 ) {
		Write-Host "Already logged in to an Azure subscription."
		# For some very odd reason (bad coding in PS?* :-) ), this output would appear LAST. meaning after the last call of the function. (wtf?)
		#   * or do the round brackets do some kind of subshelling? other than what people told me? to be researched.
		# (az account show --only-show-errors -o json | ConvertFrom-Json) | Select-Object tenantId,name
		# ---
		# Here's the thing with AzureCLI as a whole: Microsoft don't even adhere to their own frickin standards. If "az something"* fails, they won't throw an exception, and
		# "az account" does not know about "-ErrorAction" (which is a de-facto standard!). Finally, PowerShell itself does not use error codes like everybody else, so you're stuck
		# on some output to interpret. Morons. We hence just try to assign a variable to this command, and if the variable is empty, tadaaa error. Lel.
		#   * no, seriously, try "az something". "something" is unknown, and even then there is no darn exception**, just red text. No try/catch possible. Hilarious.
		#   ** Even better, "az something" does not complain about "-ErrorAction", it simply ignores it in this case. Absolute pros at work :D ("az account" at least states it does not adhere to that...)
		$mytok = (az account get-access-token -o json 2>$null | ConvertFrom-Json )
		if ( $mytok -eq $null ) {
			[Console]::ForegroundColor = 'red'
			Write-Host "Token possibly invalid, AzureCLI has no means of renewing tokens (sic),"
			Write-Host "hence logging you out."
			[Console]::ResetColor()
			az logout
			Write-Host "...done. Please log in again."
		} else {
			# Do not have sensitive data lingering about:
			Clear-Variable mytok
			# Set subscription:
			Write-Host "Setting active subscription to $($suuid)...`n"
			az account set -o jsonc --subscription $suuid
		}
	} else {
		$loginex = $("" | Out-String)
		$loginex += "Not logged in, trying to log in.`n"
		Write-Host $loginex
		Write-Host "Tenant: $tuuid"
		Write-Host "Subscription: `"$SubscrName`" = $tuuid"
		if ( $tuuid -ne $null ) {
			# TODO: research --use-device-code
			# We cannot log in stating we are azure user user@whatnot, this would lead to not using MFA.
			# Great design, Microsoft, I just want to enter my creds but not the frickin username every time. -.-'
			# (Also, what about user-based vaulting (incl. an Enterprise Vault) and then using a TOTP?
			#  Microsoft won't even do a proper TOTP, they hide that behind their "Authenticator" (which is EFFING MANDATORY).
			#  Also, Microsoft take a huge dump on established standards like the aforementioned, or browser plugins for vaults.
			#  And many people still think this is good design. ಠ_ಠ  (Do you?)
			# )
			# az login --username (Get-ConsolutAzLoginName) --tenant $tuuid
			# ...so back to using that UI designed for noobs (its existence isn't bad - dictating it is, and makes devs more inefficient.)
			# TODO: Can we work around with managed identities? And should we consider this at all, from a security perspective?
			Write-Host "Logging in..."
			az login -o jsonc --tenant $tuuid
			Write-Host "...logged in."
			Write-Host "Setting active subscription to $($suuid)..."
			az account set -o jsonc --subscription $suuid
		} else {
			# PowerShell is just sitting on the zombie hydra that .NET is. --> https://powershellexplained.com/2017-04-07-all-dotnet-exception-list/#systemargumentnullexception
			throw [System.ArgumentNullException]::New("UUID for tenant not found: $SubscrName")
		}
	}
	Write-Host "Access token:"
	az account get-access-token -o jsonc --query '{expiresOn: expiresOn, expires_on: expires_on, subscription: subscription, tenant: tenant, tokenType: tokenType}'
	Write-Host "Active subscription:"
	az account show -o jsonc --query '{name: name, id: id, tenantId: tenantId, user: user}'
}