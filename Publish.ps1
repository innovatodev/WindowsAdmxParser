New-Item "$env:UserProfile\Documents\WindowsPowerShell\Modules\WindowsAdmxParser" -ItemType Directory
Copy-Item -Path ".\Module\*" -Destination "$env:UserProfile\Documents\WindowsPowerShell\Modules\WindowsAdmxParser" -Recurse
Import-Module "$env:UserProfile\Documents\WindowsPowerShell\Modules\WindowsAdmxParser\WindowsAdmxParser.psd1"
Publish-Module -Name WindowsAdmxParser -NuGetApiKey $env:PSGALLERY_KEY
