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
        $InstructionPair = Build-BMSMessage (Assert-BMSMessage -Command @{$Instruction=$Value})
        $OldParameter = Get-BMSParameter $Instruction
        ("--------- Existing Value ---------")
        ("Name: [" + $OldParameter.Description + "]")
        ("Value: [" + $OlDParameter.Value + " " + $OldParameter.Unit + "]")
        ("--------- Proposed Value ---------")
        ("Name: [" + $InstructionPair.Instruction.Name + "]")
        ("Value: [" + $InstructionPair.Plain + " " + $InstructionPair.Instruction.Return.Unit + "]")
        ("---------------------------------- ")
        
        Write-Warning "Setting BMS parameters to incorrect values can permanently damage equipment! `r`nExceeding chemistry boundries can cause fire and explosion risk."
        $confirmation = Read-Host -Prompt "Confirm the name of the instruction you are attempting to set and press [Enter]`r`nPressing [Enter] without confirmation word will abort."
        if ($Confirmation -cne $InstructionPair.Command) {
            Throw "Command not confirmed."
        }
        
        $r = 0
        do {
            try {
                $SetParameter = Convert-BMSMessage (Send-BMSMessage $InstructionPair)
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
        
        Switch (($SetParameter.BMSData.0).Value) {
            SET {
                #get the value again from the BMS to check if it changed
                $NewParameter = Get-BMSParameter $Instruction

                #because the "Set" object is carried forward from a string value, we need to get the value type
                #according to the library definition, then format accordingly so they compare properly.
                Switch ($NewParameter.Instruction.Return.Value) {
                    float {$SetValue = [single]("{0:N}" -f [float]$SetParameter.Plain)}
                    int {$SetValue = [int]("{0:D}" -f [int]$SetParameter.Plain)}
                    Default {$SetValue = $SetParameter.Plain}
                }

                $Result = @{
                    "Description" = $NewParameter.Description;
                    "Unit"= $NewParameter.Unit;
                    "Set" = $SetValue;
                    "Get" = $NewParameter.Value
                }

                #cast comparison to string because some cases compare single to double
                #or some are comparing an integer to a char, and there's no reason to write a robust handler
                #for those cases.
                if ([string]$Result.Get -eq [string]$Result.Set) {
                    $Result.Add("Success",$true)
                }
                else {
                    $Result.Add("Success",$false)
                }
            }

            ERROR1 {
                Write-Error ("BMS Returned [ERROR1] during parameter set attempt. Value Unchanged.")
            }

            Default {
                Write-Error ("Unknown state found: [" + ($SetParameter.BMSData.0).Value + "]")
            }
        }
        
    }

    end {
        return [PSCustomObject]$Result
    }
}
