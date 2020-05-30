#manifest
. .\functions\Assert-BMSMessage.ps1
. .\functions\Build-BMSMessage.ps1
. .\functions\Send-BMSMessage.ps1
. .\functions\Parse-BMSMessage.ps1
. .\functions\Get-BMSInstructionlist.ps1
. .\functions\Get-CRC16.ps1
. .\functions\HexConverters.ps1
. .\functions\Invoke-CMDPreProcessor.ps1
. .\functions\Sort-MessageStream.ps1


Function Get-BMSLibraryInstance {
    (gc .\instructionset.json | ConvertFrom-Json)

}

#instance a library global
$global:BMSInstructionSet = Get-BMSLibraryInstance

Function Get-BMSParameter
{[CmdletBinding()]
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
            $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
            $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
            return $RuntimeParameterDictionary
        }
    
        begin {
            $Instruction = $PSBoundParameters[$ParameterName]
        }
    
        process {
            #just an invocation wrapper to make it easier, mostly.
            Parse-BMSMessage (
                Send-BMSMessage (
                    Build-BMSMessage (
                        Assert-BMSMessage -Command $Instruction
                    )
                )
            ) 
        }
}



