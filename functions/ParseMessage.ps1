
Function Get-BMSCharsFromHexStream {
    [CmdletBinding()]
    param($HexString)

    $ComputablePayloadLength = ([convert]::toint16($HexString[3],16) + 3)
    $MessageStream = ($HexString[4..$ComputablePayloadLength])

    ($MessageStream | ForEach-Object{[char][convert]::toint16($_,16)}) -join ""
}

Function Get-BMSIntMixedBytesFromHexStream {
    [CmdletBinding()]
    param($HexString)

    $ComputablePayloadLength = ([convert]::toint16($HexString[3],16) + 3)
    $MessageStream = ($HexString[4..$ComputablePayloadLength])

    ($MessageStream | ForEach-Object{[convert]::toint16($_,16)})
}

Function Get-BMSIntFromHexStream {
    [CmdletBinding()]
    param($HexString)

    $ComputablePayloadLength = ([convert]::toint16($HexString[3],16) + 3)
    $MessageStream = ($HexString[4..$ComputablePayloadLength])

    ($MessageStream | ForEach-Object{[convert]::toint16($_,16)})
}

Function Get-BMSBytesFromHexStream {
    [CmdletBinding()]
    param($HexString)
    #assign floating point byte array size
    switch ($BMSInstructionSet.Config.Message.FloatPrecision) {
        single {
            #single signed float is 4 bytes long
            $SegmentOffset = [int]4
        }
        Default {
            throw ("Requested float precision " + $BMSInstructionSet.Config.Message.FloatPrecision + " is not available.")
        }
    }


    #End offset length index -1 for array count, and -2 for crc and -1 for etx 
    $Offset = ($HexString.Length -4)

    #Front offset is +1 
    $MessageStream = $HexString[4..($Offset)]
    
    Write-Verbose ("Parsing float as [" + $SegmentLength + "] Byte Stream")
    Write-Verbose ("Payload Length: [" + ($MessageStream.Count) + "]")
    $ByteStream = ($MessageStream | ForEach-Object{$_}) | %{[byte][int16]("0x" + $_)}
    
    if ($ByteStream.Count -eq $SegmentLength) {
        [BitConverter]::ToSingle($ByteStream, 0)
    }
    else {

        $i = 1
        #Initalize byte stream counter
        $LSB = 0
        $MSB = ($SegmentOffset -1)
        #initialize byte segment counter
        $b = 1
        #initialize first byte segment array based on FloatingPrecisionBits
        #$ByteSegment = [byte[]]::new($SegmentLength)
        do {
            try {
                [BitConverter]::ToSingle($ByteStream[$LSB..$MSB], 0)
            }
            catch {
                Throw "Segment offset out of bounds!"
            }
            
            $LSB+=$SegmentOffset
            $MSB+=$SegmentOffset
            $i++
        } until ($i -gt ($ByteStream.Count / $SegmentOffset))
    }
    

    
    
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
            #offset length index -1 for array count, and -2 for crc and -1 for etx 
            $CRCOffset = ($iO.HexStreamReceive.ParsedStream[$i].Length -4)
            #get bytes for crc calculation
            $CRCTask = $iO.HexStreamReceive.ParsedStream[$i][1..($CRCOffset)]

            #Old crc is two bytes before etx
            $OldCRC = $iO.HexStreamReceive.ParsedStream[$i][($CRCOffset +1)..($CRCOffset +2)] -join ""

            #recalculate crc
            $NewCRC = Get-CRC16 $CRCTask -join ""

            #compare crc
            Write-Verbose ("String to Compute: [" + $CRCTask + "]`r`n" + "Received CRC: [" + $OldCRC + "]`r`n" + "Computed CRC: [" + $NewCRC + "]")
            if (!($NewCRC -eq $OldCRC)) {
                    $CRCStream.Add($i,$false)
                    Write-Error ("CRC DOES NOT MATCH. Expected: " + $OldCRC + "Computed: " + $NewCRC)
                }
                else {
                    $CRCStream.Add($i,$true)
                }
            $i++
    } 
    until ($iO.HexStreamReceive.ParsedStream.Count -eq $i)

    $iO.HexStreamReceive.Add("CRCStream",$CRCStream)
    return $iO
    #compute/add CRC
    #CRC-16 is calculated [in these bytes] <STX>[<DST><SND><LEN><MSG>[<QRY>]]<CRC><CRC><ETX>
}

Function Parse-BMSMessage
{   
    [cmdletbinding()]
    Param($iO,[switch]$ExtraInfo)
    begin {
        if (!$iO.HexStreamReceive)
        {
            Throw "This Instruction Object does not contain a received hex stream to decode."
        }
        Function LabelHeaderValues {
            [CmdletBinding()]
            param($iO)
            $Header = $null
            $Descriptor = $iO.Instruction.Return.Unit.Array | ?{$_.Position -eq 0}
            switch ($Descriptor.Value) {
                char {
                    #note that we just have a handler for char types, because bms appears to send segment 0 data types as ascii values that are cast to integers
                    $h = [int](Get-BMSCharsFromHexStream $iO.HexStreamReceive.ParsedStream[0])
                    $Header = @{
                        "Unit" = $Descriptor.Unit;
                        "Value" = $h;
                        "Description" = $Descriptor.Description
                    }
                }
                Default {
                    Write-Error ("Unknown Value Type Declaration: " + $iO.Instruction.Return.Unit.Array[0].Value)
                }
            }
            
            # present the count types as either count of bytes or counts of bms units depending on library data
            Write-Verbose ("Instruction Identification: [" + $Descriptor.Description + "]")
            Return ([PSCustomObject]$Header)
        }

        Function LabelDataArrayValues {
            [CmdletBinding()]
            param($iO)
            $Data = @()
            switch ($iO.Instruction.Return.Unit.Type) {
                Int {
                    Write-Verbose "Using Int array parser"
                    $Values = Get-BMSIntFromHexStream $iO.HexStreamReceive.ParsedStream[1]
                }
                Byte {
                    Write-Verbose "Using Bytes array parser"
                    $Values = Get-BMSBytesFromHexStream $iO.HexStreamReceive.ParsedStream[1]
                }
                IntMixedBytes {
                    Write-Verbose "Using Int Mixed with Bytes array parser"
                    $Values = Get-BMSIntMixedBytesFromHexStream $iO.HexStreamReceive.ParsedStream[1]
                }
                Char {
                    Write-Verbose "Using Char array parser"
                    $Values = Get-BMSCharsFromHexStream $iO.HexStreamReceive.ParsedStream[1]
                }
                Default {
                    Throw "I don't know how to handle that array object class. :("
                }
            }
            if ($iO.Instruction.Return.Unit.Array | ?{$_.Position -eq "template"}) {
                #store the template
                $Descriptor = @()
                $Template = ($iO.Instruction.Return.Unit.Array | ?{$_.Position -eq "template"})
                #assign template to position 1 in array
                
                #add a copy of template with position ID $Values.Count -1 times
                $i = 1
                #add a dingus to the top of descriptor array. in other non-template arrays,
                #the first index [0] is the header data and is skipped. This keeps template type arrays
                #aligned with non-template style arrays.
                Write-Verbose ("Processing: [" + $Values.Count + "] values")
                $Descriptor += $Template.PSObject.Copy()
                do {
                    $TemplateCopy = $Template.PSObject.Copy()
                    $TemplateCopy.Position = $i
                    $TemplateCopy.Description = ($TemplateCopy.Description + ": [" + $i + "]")
                    $Descriptor += $TemplateCopy
                    $i++
                } until ($i -gt $Values.Count)
            }
            else {
                $Descriptor = ($iO.Instruction.Return.Unit.Array | Sort-Object -Property Position)
            }

            $i = 0
            do {
                #for each descriptor index, process the value
                $Row = @{
                    "Unit" = $Descriptor[($i+1)].Unit;
                    "Value" = $Values[$i];
                    "Description" = $Descriptor[($i+1)].Description;
                }
                $Data += [PSCustomObject]$Row
                $i++
            } until ($i -gt ($Descriptor.Count -1))
           

            
            Return ($Data)
        }
    }
    process {
        Write-Verbose ("Instruction Decoding Handler: [" + $iO.Instruction.Return.Value + "]")
        Write-Verbose ("Instruction Description: [" + $iO.Instruction.Alias + "]")
        switch ($iO.Instruction.Return.Value) {
            string {
                $Data = [string](Get-BMSCharsFromHexStream $iO.HexStreamReceive.ParsedStream[0])
                $iO | Add-Member -MemberType NoteProperty -Name BMSData -Value $Data
                Write-Verbose $iO.Instruction.Return.Description
                Write-Verbose $iO.Instruction.Return.Unit
                Write-Verbose ([string]$iO.BMSData)
            }
        
            float {
                $Data = ("{0:N}" -f [float](Get-BMSCharsFromHexStream $iO.HexStreamReceive.ParsedStream[0]))
                $iO | Add-Member -MemberType NoteProperty -Name BMSData -Value $Data
                Write-Verbose $iO.Instruction.Return.Description
                Write-Verbose $iO.Instruction.Return.Unit
                Write-Verbose ("{0:N}" -f ([float]$iO.BMSData))
            }
        
            char {
                $Data = [char](Get-BMSCharsFromHexStream $iO.HexStreamReceive.ParsedStream[0])
                $iO | Add-Member -MemberType NoteProperty -Name BMSData -Value $Data
                Write-Verbose $iO.Instruction.Return.Description
                Write-Verbose $iO.Instruction.Return.Unit
                Write-Verbose ([char]$iO.BMSData)
            }
        
            int  {
                $Data = ("{0:N}" -f [int](Get-BMSCharsFromHexStream $iO.HexStreamReceive.ParsedStream[0]))
                $iO | Add-Member -MemberType NoteProperty -Name BMSData -Value $Date
                Write-Verbose $iO.Instruction.Return.Description
                Write-Verbose $iO.Instruction.Return.Unit
                Write-Verbose ([int]("{0:N}" -f ([int]$iO.BMSData)))
            }
        
            array  {
                
                # each type of array has two parts (hex stream messages):
                # first part is some sort of metadata about the BMS ID, or number of instructions/values expected
                # there is some inconsistency in the first value, so handler cases are necessary for this.
                #
                # because there isn't an expectation of this structure to change very much, there isn't any type of function recursion
                # for managing these use cases.
                #
                # the second part is the value array, which can be dynamic from a single value (like BMS controller temperature),
                # to several values such as error reporting, to many values, such as cell voltages
                

                
                
                $BMSData = [PSCustomObject]@{"0"=(LabelHeaderValues $iO);"1"=(LabelDataArrayValues $iO)}
                $iO | Add-Member -MemberType NoteProperty -Name BMSData -Value $BMSData
            }
        
            Default  {
                Write-Warning ("No handler for type [" + $iO.Instruction.Return.Value + "]")
                break
            }
        }
        return $iO.PSObject.Copy()
    }
}

