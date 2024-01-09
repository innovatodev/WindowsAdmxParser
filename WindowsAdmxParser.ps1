Import-Module .\Module\WindowsAdmxParser.psd1 -Force

$Policies = Invoke-WindowsAdmxParser -DefinitionsPath "C:\Windows\PolicyDefinitions" -IgnoredAdmx "inetres" # Ignoring Internet Exporer
$Policies | ConvertTo-Json -Depth 100 | Out-File "$env:USERPROFILE\Downloads\AllPolicies.json" -Force
