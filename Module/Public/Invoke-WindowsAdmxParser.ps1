function Invoke-WindowsAdmxParser {
    param (
        [string]$DefinitionsPath,
        [string[]]$IgnoredAdmx
    )
    # Languages
    [string[]]$Languages = ""
    Get-ChildItem $DefinitionsPath -Directory | Where-Object { $_.Name -ne 'en-us' } | ForEach-Object {
        $Languages += $_.Name
    }
    $Languages += "en-US"

    # Function to get the text from ADML file
    function Get-AdmlText {
        param ([string]$id, [string]$ADMXBaseName)

        foreach ($lang in $Languages) {
            $ADMLPath = Join-Path $DefinitionsPath "$lang\$ADMXBaseName.adml"
            if (Test-Path $ADMLPath) {
                [xml]$admlContent = Get-Content -Path $ADMLPath
                $text = $admlContent.policyDefinitionResources.resources.stringTable.string | Where-Object { $_.id -eq $id }
                if ($text) {
                    return $text.'#text'
                }
            }
        }
        Write-Warning "Text not found for ID: $id" # Debugging statement
        return $null
    }

    $AllPolicies = @()

    # Search for ADMX files
    Get-ChildItem $DefinitionsPath -Filter "*.admx" | ForEach-Object {
        $ADMXBaseName = $_.BaseName
        Write-Host "Processing ADMX: $ADMXBaseName"
        [xml]$admxContent = Get-Content -Path $_.FullName
        $targetNameSpace = $admxContent.policyDefinitions.policyNamespaces.target.Namespace

        if ($ADMXBaseName -in $IgnoredAdmx) {
            Write-Warning "Ignoring ADMX: $ADMXBaseName"
        } else {
            # Process each policy in the ADMX file
            foreach ($policy in $admxContent.policyDefinitions.policies.policy) {
                $displayNameId = $policy.displayName -replace "\$\(string\.(.+)\)", '$1'
                $explainTextId = $policy.explainText -replace "\$\(string\.(.+)\)", '$1'
                $displayName = Get-AdmlText -id $displayNameId -ADMXBaseName $ADMXBaseName
                $explainText = (Get-AdmlText -id $explainTextId -ADMXBaseName $ADMXBaseName) -replace '\s+$', '' -replace "`n|`r|\\n", '' -replace ' {2,}', ' '
                $supportedOn = if ($policy.supportedOn ) { $policy.supportedOn.ref -replace ".*:", "" -replace "SUPPORTED_", '' } else { "Not specified" }

                if ($supportedOn -like '*OBSOLETE*' -or $explainText -like '*DEPRECATED*' -or $explainText -like '*UNSUPPORTED*') {
                    continue
                }

                $elements = @()
                if ($policy.elements) {
                    foreach ($element in $policy.elements.ChildNodes) {
                        switch ($element.Name) {
                            'decimal' {
                                $elements += @{
                                    Type      = 'Decimal'
                                    ValueName = $element.valueName
                                    MinValue  = $element.minValue
                                    MaxValue  = $element.maxValue
                                }
                            }
                            'boolean' {
                                $truevalue = $null
                                $falsevalue = $null
                                if ($null -eq $element.trueValue.decimal.value -or $null -eq $element.falseValue.decimal.value) {
                                    $truevalue = "1"
                                    $falsevalue = "0"
                                } else {
                                    $truevalue = $element.trueValue.decimal.value
                                    $falsevalue = $element.falseValue.decimal.value
                                }
                                $elements += @{
                                    Type       = 'Boolean'
                                    ValueName  = $element.valueName
                                    TrueValue  = $truevalue
                                    FalseValue = $falsevalue
                                }
                            }
                            'enum' {
                                $items = @()
                                foreach ($item in $element.item) {
                                    $displayNameId = $item.displayName -replace "\$\(string\.(.+)\)", '$1'
                                    $displayName = Get-AdmlText -id $displayNameId -ADMXBaseName $ADMXBaseName
                                    $value = if ($item.value.decimal) {
                                        $item.value.decimal.value
                                    } elseif ($item.value.string) {
                                        $item.value.string
                                    } else {
                                        $null
                                    }
                                    $items += @{
                                        DisplayName = $displayName
                                        Value       = $value
                                    }
                                }
                                $elements += [ordered]@{
                                    Type      = 'Enum'
                                    ValueName = $element.valueName
                                    Items     = $items
                                }
                            }
                            'text' {
                                $elements += @{
                                    Type      = 'Text'
                                    ValueName = $element.valueName
                                }
                            }
                            'list' {
                                $elements += @{
                                    Type  = 'List'
                                    Value = ""
                                }
                            }
                        }
                    }
                }

                if ($policy.enabledValue -or $policy.disabledValue) {
                    $enabledValue = $null
                    $disabledValue = $null

                    if ($policy.enabledValue) {
                        if ($policy.enabledValue.decimal) {
                            $enabledValue = @{
                                Type  = 'EnabledValue'
                                Value = $policy.enabledValue.decimal.value
                            }
                        } elseif ($policy.enabledValue.string) {
                            $enabledValue = @{
                                Type  = 'EnabledValue'
                                Value = $policy.enabledValue.string
                            }
                        }
                    }

                    if ($policy.disabledValue) {
                        if ($policy.disabledValue.decimal) {
                            $disabledValue = @{
                                Type  = 'DisabledValue'
                                Value = $policy.disabledValue.decimal.value
                            }
                        } elseif ($policy.disabledValue.string) {
                            $disabledValue = @{
                                Type  = 'DisabledValue'
                                Value = $policy.disabledValue.string
                            }
                        }
                    }

                    $elements += $enabledValue, $disabledValue | Where-Object { $_ -ne $null }
                }

                if ($policy.trueValue -or $policy.trueValue) {
                    $trueValue = $null
                    $falseValue = $null

                    if ($policy.trueValue) {
                        if ($policy.trueValue.decimal) {
                            $trueValue = @{
                                Type  = 'TrueValue'
                                Value = $policy.trueValue.decimal.value
                            }
                        } elseif ($policy.trueValue.string) {
                            $trueValue = @{
                                Type  = 'TrueValue'
                                Value = $policy.trueValue.string
                            }
                        }
                    }

                    if ($policy.falseValue) {
                        if ($policy.falseValue.decimal) {
                            $falseValue = @{
                                Type  = 'FalseValue'
                                Value = $policy.falseValue.decimal.value
                            }
                        } elseif ($policy.falseValue.string) {
                            $falseValue = @{
                                Type  = 'FalseValue'
                                Value = $policy.falseValue.string
                            }
                        }
                    }

                    $elements += $trueValue, $falseValue | Where-Object { $_ -ne $null }
                }

                $keyPath = $policy.key
                $keyName = $policy.valueName
                if ($null -eq $keyName) {
                    $keyPathParts = $keyPath -split '\\'
                    $keyName = $keyPathParts[-1]
                    $keyPath = ($keyPathParts[0..($keyPathParts.Length - 2)] -join '\')
                }

                $AllPolicies += [PSCustomObject]@{
                    File         = "$($_.BaseName).admx"
                    NameSpace    = $targetNameSpace
                    Class        = $policy.class
                    CategoryName = $policy.parentCategory.ref -replace ".*:", ""
                    DisplayName  = $displayName
                    ExplainText  = $explainText
                    Supported    = $supportedOn
                    KeyPath      = $keyPath
                    KeyName      = $keyName
                    Elements     = $elements
                }
            }
        }
    }
    return $AllPolicies
}
