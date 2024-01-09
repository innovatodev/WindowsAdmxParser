@{
    RootModule        = 'WindowsAdmxParser.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '6afa025d-2a43-4e5e-93a1-7c3cd5d53ac5'
    Author            = 'innovatodev'
    CompanyName       = 'innovatodev'
    Copyright         = '(c) innovatodev. All rights reserved.'
    Description       = 'Module to parse Admx Policies Settings from a given PolicyDefinitions folder.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Invoke-WindowsAdmxParser'
    )
    CmdletsToExport   = @()
    VariablesToExport = '*'
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{
            Tags         = @('Windows', 'Policy', 'Policies', 'ADMX', 'ADML', "LocalPolicy")
            LicenseUri   = 'https://raw.githubusercontent.com/innovatodev/WindowsAdmxParser/main/LICENSE'
            ProjectUri   = 'https://github.com/innovatodev/WindowsAdmxParser'
            IconUri      = 'https://raw.githubusercontent.com/innovatodev/WindowsAdmxParser/main/media/icon.png'
            ReleaseNotes = 'https://raw.githubusercontent.com/innovatodev/WindowsAdmxParser/main/CHANGELOG.md'
        }
    }
}
