Function Get-BMSLibraryInstance {
    (gc .\instructionset.json | ConvertFrom-Json)
}

Function Get-BMSInstructionList {
    [CmdletBinding()]
    Param([ValidateSet(
        "String",
        "Array",
        "Range",
        "Configurable",
        "Common"
        )]$Type,
        [ValidateSet(
            "Amperage",
            "BMS",
            "Cell",
            "Error",
            "Identification",
            "Information",
            "Pack",
            "SOC",
            "Temperature",
            "Victron"
        )]$Category,
        [switch]$FullCommand)

    process {

        Switch ($Type) {
            String {$Selection = $global:BMSInstructionSet.Command | ?{$_.Handler -match "String"}}
            Array {$Selection = $global:BMSInstructionSet.Command | ?{$_.Handler -match "Array"}}
            Range {$Selection = $global:BMSInstructionSet.Command | ?{$_.Handler -match "Range"}}
            Configurable {$selection = $global:BMSInstructionSet.Command | ?{$_.ReadOnly -eq $false}}
            Common {$global:BMSInstructionSet.Command | ?{$_.Common -eq $true}}
            
            Default {
                $Selection = $global:BMSInstructionSet.Command
            }
        }
        
        if ($Category) {
            $Selection = $Selection | ?{$_.Category -match $Category}
        }

        if ($FullCommand) {
            Return $Selection.PSObject.Copy()
        }
        else {
            ($Selection | Select-Object -Property Alias,Instruction,Category,Handler).PSObject.Copy()
        }

    }
    
}

Function Get-BMSParameter {
    [CmdletBinding()]
    Param([switch]$Extra)
        DynamicParam {
     
            # Set the dynamic parameters' name
            $ParameterName = 'Instruction'
    
            # Create the dictionary
            $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
    
            # Create the collection of attributes
            $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
    
            # Create and set the parameters' attributes
            $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
            $ParameterAttribute.Mandatory = $true
            $ParameterAttribute.Position = 1
    
            # Add the attributes to the attributes collection
            $AttributeCollection.Add($ParameterAttribute)
    
            # Generate and set the ValidateSet
            $arrSet = (Get-BMSInstructionList).Instruction
            $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)
    
            # Add the ValidateSet to the attributes collection
            $AttributeCollection.Add($ValidateSetAttribute)
    
            # Create and return the dynamic parameter
            $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [array], $AttributeCollection)
            $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
            return $RuntimeParameterDictionary
        }
    
        begin {
            $Instruction = $PSBoundParameters[$ParameterName]
            trap {
                $Error[0].Exception
                $Error[0].InvocationInfo
                break
            }
        }
        
        
        process {
            $r = 0
            do {
                try {
                    $Data = Parse-BMSMessage (
                        Send-BMSMessage (
                            Build-BMSMessage (
                                Assert-BMSMessage -Command $Instruction
                            )
                        )
                    )
                    break
                }
                catch [System.Management.Automation.MethodInvocationException] {
                    $port.BaseStream.Dispose()
                    Remove-Variable port -Scope Global
                    Write-Warning "Retrying $r"
                }    
                $r++
            }
            until ($r -eq $BMSInstructionSet.Config.Session.Retries)
                if ($Extra) {
                    $Data.PSObject.Copy()
                    break
                }
                else {
                    ForEach ($iOInstance in $Data)
                    {
                        ($iOInstance.BMSData.0).PSObject.Copy()
                        if ($iOInstance.BMSData.1) {
                            ($iOInstance.BMSData.1).PSObject.Copy()
                        }
                    }

                }
        }
}



Function Set-BMSParameter {
    [CmdletBinding()]
    Param([Parameter(Mandatory=$true)]$Value)
    DynamicParam {
     
        # Set the dynamic parameters' name
        $ParameterName = 'Instruction'

        # Create the dictionary
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        # Create the collection of attributes
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]

        # Create and set the parameters' attributes
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $true
        $ParameterAttribute.Position = 0

        # Add the attributes to the attributes collection
        $AttributeCollection.Add($ParameterAttribute)

        # Generate and set the ValidateSet
        $arrSet = (Get-BMSInstructionList -Type Configurable).Instruction
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)

        # Add the ValidateSet to the attributes collection
        $AttributeCollection.Add($ValidateSetAttribute)

        # Create and return the dynamic parameter
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
        return $RuntimeParameterDictionary
    }

    begin {
        $Instruction = $PSBoundParameters[$ParameterName]
        trap {
            $Error[0].Exception
            $Error[0].InvocationInfo
            break
        }
    }
    
    
       
    process {

        $Instruction = Build-BMSMessage (Assert-BMSMessage -Command @{$Instruction=$Value})
        Write-Warning "This command does not work properly yet.`r`nData returns as `'ERROR 1`' with assumed correct data."
        $confirmation = Read-Host -Prompt "Enter the name of the instruction you are attempting to set and press [Enter]"
        if ($Confirmation -cne $Instruction.Command) {
            Throw "Command not confirmed."
        }

        $r = 0
        do {
            try {
                $Data = Send-BMSMessage $Instruction
                break
            }
            catch [System.Management.Automation.MethodInvocationException] {
                $port.BaseStream.Dispose()
                Remove-Variable port -Scope Global
                Write-Warning "Retrying $r"
            }    
            $r++
        }
        until ($r -eq $BMSInstructionSet.Config.Session.Retries)
        $Data
    }
}
