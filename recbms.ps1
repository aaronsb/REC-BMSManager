#manifest
. .\Get-BMSInstructionlist.ps1
. .\Get-CRC16.ps1
. .\HexConverters.ps1
. .\Invoke-BMSCommunication.ps1
. .\Invoke-CMDProcessor.ps1
. .\New-BMSMessage.ps1
. .\New-BMSSessionObject.ps1
. .\Sort-MessageStream.ps1

Function Get-BMSConfigMeta {
    (gc .\instructionset.json | ConvertFrom-Json)
}

Function Invoke-BMSConversation
{[CmdletBinding()]
    Param()
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
            return (Invoke-BMSCommunication (New-BMSMessage -Instruction $Instruction))
        }
}




Function Get-BMSParameter {
    [CmdletBinding()]
    Param([switch]$NoFormatList,[switch]$ExtraInfo)
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
        # get just instruction names from the library
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
        #give dynamic parameter a friendly parameter name
        $Instruction = $PSBoundParameters[$ParameterName]
    }

    process {

    }
    
}

Function Decode-BMSiO
{
    Param($iO)
    begin {
        if (!$iO.HexStreamReceive)
        {
            Throw "This Instruction Object does not contain a received hex stream to decode."
        }
    }
    process {
        
        Write-Verbose ("Instruction Decoding Handler: [" + $iO.Handler + "]")
        switch ($iO.Handler)
        {
            String {
                
                if ((Verify-MessageCRC $iO.ParsedStream) -eq $false)
                {
                    Throw "CRC FAILED"
                }
                $iO | Add-Member -MemberType NoteProperty -Name BMSValue -Value (Get-BMSCharFromHexStream $iO.ParsedStream.0)
                $DisplayTemplate = $iO.OriginInstruction.Instruction.Return
                $DisplayTemplate.value = $iO.BMSValue
            }
            Array  {
                Write-Verbose "Array Type Handler"
                ForEach ($Stream in $iO.ParsedStream) {
                    if ((Verify-MessageCRC $Stream) -eq $false) {
                        Throw "CRC FAILED"
                    }
                }
                Write-Warning "I don't know how to handle array type messages (quite) yet."
            }
            Range  {
                Write-Verbose "Range Type Handler"
                if ((Verify-MessageCRC $iO.ParsedStream) -eq $false)
                {
                    Throw "CRC FAILED"
                }
                $iO | Add-Member -MemberType NoteProperty -Name BMSValue -Value (Get-BMSCharFromHexStream $iO.ParsedStream.0)
                $DisplayTemplate = $iO.OriginInstruction.Instruction.Return
                $DisplayTemplate.value = $iO.BMSValue
            }
            Default  {
                Write-Warning ("No handler for type [" + $iO.Handler + "]")
                break
            }
        }
        if ($ExtraInfo) {
            $iO
            $DisplayTemplate
        }
        else {
            if ($NoFormatList) {
                $DisplayTemplate
            }
            else {
                $DisplayTemplate | Format-List
            }
            
        }
        
    }
}


Function Get-BMSCharFromHexStream{
    [CmdletBinding()]
    param($HexString)

    $ComputablePayloadLength = ([convert]::toint16($HexString[3],16) + 3)
    $MessageStream = ($HexString[4..$ComputablePayloadLength])

    ($MessageStream | ForEach-Object{[char][convert]::toint16($_,16)}) -join ""

    #saving this example for later: [BitConverter]::ToSingle([BitConverter]::GetBytes(0xc71e596b),0)
    #https://www.reddit.com/r/PowerShell/comments/bayfhx/hex_to_decimal/

    #also this one
    #$hexInput = 0x3FA8FE3B

    #$bytes = ([Net.IPAddress]$hexInput).GetAddressBytes()
    #$numericValue = [BitConverter]::ToSingle($bytes, 0)
}



Function Verify-MessageCRC {
    [CmdletBinding()]
    param($iO)
    
    $CRCStream = [ordered]@{}
    
    $i=0
        do {
        $ComputablePayloadLength = ([convert]::toint16($iO.HexStreamReceive.ParsedStream[$i][3],16) + 3)
        $CRCTask = ($iO.HexStreamReceive.ParsedStream[$i][1..$ComputablePayloadLength]) -join ""
        $OldCRC = ($iO.HexStreamReceive.ParsedStream[$i][($ComputablePayloadLength +1)..($ComputablePayloadLength +2)]) -join ""
        $NewCRC = (Get-CRC16 $CRCTask) -join ""
        Write-Verbose ("String to Compute: [" + $CRCTask + "]`r`n" + "Received CRC: [" + $OldCRC + "]`r`n" + "Computed CRC: [" + $NewCRC + "]")
        
        if ($NewCRC -notmatch $OldCRC) {
                $CRCStream.Add($i,$false)
                Write-Warning ("CRC DOES NOT MATCH. Expected: " + $OldCRC + "Computed: " + $NewCRC)
            }
            else {
                $CRCStream.Add($i,$true)
            }
        $i++
    } 
    while (($i + 1) -le $iO.HexStreamReceive.ParsedStream.Count)

    $iO.HexStreamReceive.Add("CRCStream",$CRCStream)
    return $iO
    #compute/add CRC
    #CRC-16 is calculated [in these bytes] <STX>[<DST><SND><LEN><MSG>[<QRY>]]<CRC><CRC><ETX>
}

Function Get-BMSStatus
{param()
    ForEach ($instruction in ((Get-BMSInstructionList -Common).Instruction))
    {
        Get-BMSParameter $instruction -NoFormatList
    }
}
