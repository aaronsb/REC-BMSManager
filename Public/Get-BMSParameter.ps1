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
                    $Data = Convert-BMSMessage (
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