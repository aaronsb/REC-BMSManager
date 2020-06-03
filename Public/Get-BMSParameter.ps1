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
                    #Write-Warning "Retrying $r"
                }    
                $r++
            }
            until ($r -eq $BMSInstructionSet.Config.Session.Retries)


        }

        end {
            if ($Extra) {
                return $Data.PSObject.Copy()
                break
            }
            else {
                ForEach ($iOInstance in $Data)
                {
                    if ($BMSInstructionSet.Config.Battery.MultiBMS -eq $false) {
                        #the header data only makes sense for multi-module installations
                        #each REC-BMS 1Q has 16 balance lines, and additional children can be connected for "Very Large Batteries"
                        #therefore multiple arrays of data are possibly returned, and need identifiers to know which module
                        #the values come from.
                        #I haven't tested this due to a lack of a "Very Large Battery" :(

                        #logic is: multibms is false, and a multipart header is found, only assert/emit the second part of the multipart data
                        if ($iOInstance.BMSData.1) {
                            ($iOInstance.BMSData.1).PSObject.Copy()
                        }
                        else {
                            #if a second part isn't found, then only assert/emit the first part (this would be a single range value return)
                            ($iOInstance.BMSData.0).PSObject.Copy()
                        }
                    }
                    else {
                        #if multipart is true, give all the things possible
                        if ($iOInstance.BMSData.1) {
                            ($iOInstance.BMSData.0).PSObject.Copy()
                            ($iOInstance.BMSData.1).PSObject.Copy()
                        }
                        else {
                            ($iOInstance.BMSData.0).PSObject.Copy()
                        }
                    }
                }

            }

        }
}