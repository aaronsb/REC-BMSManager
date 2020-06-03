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
