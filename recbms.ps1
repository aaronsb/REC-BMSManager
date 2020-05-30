#manifest

# Preprocessor for determining instruction type input and constructing a valid message
. .\functions\CMDPreProcessor.ps1

# Instruction message assertion code, generates valid query data structures
. .\functions\AssertMessage.ps1

# CRC functions for signing byte data streams
. .\functions\CRC16.ps1

# Hex -> Decimal and Decimal -> Hex converter helpers
. .\functions\HexConverters.ps1

# Instruction message builder to suit instruction command structure syntax
. .\functions\BuildMessage.ps1

# Serial communication functions for sending and receieving instructions and telemetry
. .\functions\SendMessage.ps1

# Message parser for converting instruction response bytestreams into value streams
. .\functions\ParseMessage.ps1

# Stream processor functions for intermediary and final data presentation
. .\functions\MessageStream.ps1

# Helper functions for simplified UX and presentation
. .\functions\HelperFunctions.ps1


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



