
Function Get-BMSCharsFromHexStream {
    [CmdletBinding()]
    param($HexString)

    $ComputablePayloadLength = ([convert]::toint16($HexString[3],16) + 3)
    $MessageStream = ($HexString[4..$ComputablePayloadLength])

    ($MessageStream | ForEach-Object{[char][convert]::toint16($_,16)}) -join ""
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
            $SegmentLength = [int]4
        }
        Default {
            throw ("Requested float precision " + $BMSInstructionSet.Config.Message.FloatPrecision + " is not available.")
        }
    }

    Write-Verbose ("Parsing float as [" + $SegmentLength + "] Byte Stream")
    $ComputablePayloadLength = ([convert]::toint16($HexString[3],16) + 3)
    $MessageStream = ($HexString[4..$ComputablePayloadLength]) 
    #write-verbose ([string]$MessageStream.length)
    $ByteStream = ($MessageStream | ForEach-Object{$_}) | %{[byte][int16]("0x" + $_)}
    
    if ($ByteStream.Count -eq $SegmentLength) {
        [BitConverter]::ToSingle($ByteStream, 0)
    }
    else {
        #Initalize byte stream counter
        $i = 0
        #initialize byte segment counter
        $b = 0
        #initialize first byte segment array based on FloatingPrecisionBits
        $ByteSegment = [byte[]]::new($SegmentLength)
        do {
            # if byte count is greater than segment size
            if ($b -eq $SegmentLength) {
                #emit the converted value (single)
                [BitConverter]::ToSingle($ByteSegment, 0)
                #then reset the byte counter for the next segment
                $b = 0
                #reset the byte array for the next segment
                $ByteSegment = [byte[]]::new($SegmentLength)
            }
            $ByteSegment[$b] = $ByteStream[$i]
            $b++
            $i++
        } until ($i -gt $ByteStream.Length)
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
        $ComputablePayloadLength = ([convert]::toint16($iO.HexStreamReceive.ParsedStream[$i][3],16) + 3)
        $CRCTask = ($iO.HexStreamReceive.ParsedStream[$i][1..$ComputablePayloadLength]) -join ""
        $OldCRC = ($iO.HexStreamReceive.ParsedStream[$i][($ComputablePayloadLength +1)..($ComputablePayloadLength +2)]) -join ""
        $NewCRC = (Get-CRC16 $CRCTask) -join ""
        Write-Verbose ("String to Compute: [" + $CRCTask + "]`r`n" + "Received CRC: [" + $OldCRC + "]`r`n" + "Computed CRC: [" + $NewCRC + "]")
        
        if ($NewCRC -notmatch $OldCRC) {
                $CRCStream.Add($i,$false)
                Write-Error ("CRC DOES NOT MATCH. Expected: " + $OldCRC + "Computed: " + $NewCRC)
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

Function Parse-BMSMessage
{   
    [cmdletbinding()]
    Param($iO,[switch]$ExtraInfo)
    begin {
        if (!$iO.HexStreamReceive)
        {
            Throw "This Instruction Object does not contain a received hex stream to decode."
        }
    }
    process {
        Write-Verbose ("Instruction Decoding Handler: [" + $iO.Instruction.Return.Value + "]")
        Write-Verbose ("Instruction Description: [" + $iO.Instruction.Alias + "]")
        switch ($iO.Instruction.Return.Value) {
            string {
                $iO | Add-Member -MemberType NoteProperty -Name BMSData -Value (Get-BMSCharsFromHexStream $iO.HexStreamReceive.ParsedStream.0)
                Write-Verbose $iO.Instruction.Return.Description
                Write-Verbose $iO.Instruction.Return.Unit
                Write-Verbose ([string]$iO.BMSData)
            }
        
            float  {
                $iO | Add-Member -MemberType NoteProperty -Name BMSData -Value (Get-BMSCharsFromHexStream $iO.HexStreamReceive.ParsedStream.0)
                #$data = [float]([BitConverter]::ToSingle($iO.BMSData,0))
                Write-Verbose $iO.Instruction.Return.Description
                Write-Verbose $iO.Instruction.Return.Unit
                Write-Verbose ("{0:N}" -f ([float]$iO.BMSData))
            }
        
            char {
                $iO | Add-Member -MemberType NoteProperty -Name BMSData -Value (Get-BMSCharsFromHexStream $iO.HexStreamReceive.ParsedStream.0)
                Write-Verbose $iO.Instruction.Return.Description
                Write-Verbose $iO.Instruction.Return.Unit
                Write-Verbose ([char]$iO.BMSData)
            }
        
            int  {
                $iO | Add-Member -MemberType NoteProperty -Name BMSData -Value (Get-BMSCharsFromHexStream $iO.HexStreamReceive.ParsedStream.0)
                Write-Verbose $iO.Instruction.Return.Description
                Write-Verbose $iO.Instruction.Return.Unit
                Write-Verbose ([int]("{0:N}" -f ([int]$iO.BMSData)))
            }
        
            intarray  {
                
                # the first part of an array type message
                $Data = $null
                switch ($iO.Instruction.Return.Unit.Array[0].Value) {
                    char {
                        #note that we just have a handler for char types, because bms appears to send segment 0 data types as ascii values that are cast to integers
                        $Data = [int](Get-BMSCharsFromHexStream $iO.HexStreamReceive.ParsedStream.0)
                    }
                    Default {
                        Write-Error ("Unknown Value Type Declaration: " + $iO.Instruction.Return.Unit.Array[0].Value)
                    }
                }
                
                # present the count types as either count of bytes or counts of bms units depending on library data
                switch ($iO.Instruction.Return.Unit.Array[0].Unit) {
                    UnitCount {
                        Write-Verbose ("Number of BMS Units in Data: [" + $Data + "]")
                    }
                    ByteCount {
                        Write-Verbose ("Number of Bytes in Data: [" + $Data + "]")
                    }
                    Default {Write-Error ("Unknown Unit Declaration: " + $iO.Instruction.Return.Unit.Array[0].Unit)}
                }
                Write-Verbose ("Instruction Identification: [" + $iO.Instruction.Return.Unit.Array[0].Description + "]")
                
                # the second part of the array type message
                
                $iO | Add-Member -MemberType NoteProperty -Name BMSData -Value (Get-BMSIntFromHexStream $iO.HexStreamReceive.ParsedStream.1)
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
                
                # the first part of an array type message
                $Data = $null
                switch ($iO.Instruction.Return.Unit.Array[0].Value) {
                    char {
                        #note that we just have a handler for char types, because bms appears to send segment 0 data types as ascii values that are cast to integers
                        $Data = [int](Get-BMSCharsFromHexStream $iO.HexStreamReceive.ParsedStream.0)
                    }
                    Default {
                        Write-Error ("Unknown Value Type Declaration: " + $iO.Instruction.Return.Unit.Array[0].Value)
                    }
                }
                
                # present the count types as either count of bytes or counts of bms units depending on library data
                switch ($iO.Instruction.Return.Unit.Array[0].Unit) {
                    UnitCount {
                        Write-Verbose ("Number of BMS Units in Data: [" + $Data + "]")
                    }
                    ByteCount {
                        Write-Verbose ("Number of Bytes in Data: [" + $Data + "]")
                    }
                    Default {Write-Error ("Unknown Unit Declaration: " + $iO.Instruction.Return.Unit.Array[0].Unit)}
                }
                Write-Verbose ("Instruction Identification: [" + $iO.Instruction.Return.Unit.Array[0].Description + "]")
                
                # the second part of the array type message
                
                $iO | Add-Member -MemberType NoteProperty -Name BMSData -Value (Get-BMSBytesFromHexStream $iO.HexStreamReceive.ParsedStream.1)
            }
        
            Default  {
                Write-Warning ("No handler for type [" + $iO.Instruction.Return.Value + "]")
                break
            }
        }
        $iO 
    }
}

