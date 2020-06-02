
Function Get-BMSCharsFromByteStream {
    [CmdletBinding()]
    param($Bytes)

    $L = ([int]$Bytes[3] + 3)
    (($Bytes[4..$L]) | ForEach-Object{[char]$_}) -join ""
}

Function Get-BMSIntMixedBytesFromByteStream {
    [CmdletBinding()]
    param($Bytes)
    $L = ([int]$Bytes[3] + 3)
    ($Bytes[4..$L])
}

Function Get-BMSIntFromByteStream {
    [CmdletBinding()]
    param($String)
    $L = ([int]$Bytes[3] + 3)
    ($Bytes[4..$L]) | ForEach-Object{[int]$_}
}

Function Get-BMSBytesFromByteStream {
    [CmdletBinding()]
    param($Bytes)
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
    $Offset = ($Bytes.Length -4)

    Write-Verbose ("[Parser]: Parsing float as [" + $SegmentOffset + "] Byte Arrays")
    Write-Verbose ("[Parser]: Payload Length: [" + ($MessageStream.Count) + "]")

    #Front offset is +1 
    $ByteStream = $Bytes[4..($Offset)]
    
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
            $CRCOffset = ($iO.ByteStreamReceive.ParsedStream[$i].Length -4)
            #get bytes for crc calculation
            $CRCTask = $iO.ByteStreamReceive.ParsedStream[$i][1..($CRCOffset)]

            #Old crc is two bytes before etx
            $OldCRC = ($iO.ByteStreamReceive.ParsedStream[$i][($CRCOffset +1)..($CRCOffset +2)] | ForEach-Object {"{0:x2}" -f $_}) -join ""

            #recalculate crc
            $NewCRC = Get-CRC16 -ByteData $CRCTask

            #compare crc
            Write-Verbose ("[CRC]: String to Compute: [" + $CRCTask + "]")
            Write-Verbose ("[CRC]: Received CRC: [" + $OldCRC + "]")
            Write-Verbose ("[CRC]: Computed CRC: [" + $NewCRC + "]")
            if (!($NewCRC -eq $OldCRC)) {
                    $CRCStream.Add($i,$false)
                    Write-Error ("CRC DOES NOT MATCH. Expected: " + $OldCRC + "Computed: " + $NewCRC)
                }
                else {
                    $CRCStream.Add($i,$true)
                }
            $i++
    } 
    until ($iO.ByteStreamReceive.ParsedStream.Count -eq $i)

    $iO.ByteStreamReceive.Add("CRCStream",$CRCStream)
    return $iO
    #compute/add CRC
    #CRC-16 is calculated [in these bytes] <STX>[<DST><SND><LEN><MSG>[<QRY>]]<CRC><CRC><ETX>
}

Function Parse-BMSMessage
{   
    [cmdletbinding()]
    Param($iO,[switch]$ExtraInfo)
    begin {
        if (!$iO.ByteStreamReceive)
        {
            Throw "This Instruction Object does not contain received byte stream(s) to decode."
        }
        Function LabelHeaderValues {
            [CmdletBinding()]
            param($iO)
            $Header = $null
            switch ($iO.Instruction.Handler) {
                array {
                    $Descriptor = $iO.Instruction.Return.Unit.Array | ?{$_.Position -eq 0}
                    switch ($Descriptor.Value) {
                        char {
                            #note that we just have a handler for char types, because bms appears to send segment 0 data types as ascii values that are cast to integers
                            $h = [int](Get-BMSCharsFromByteStream $iO.ByteStreamReceive.ParsedStream[0])
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
                }
                Default {
                    $Descriptor = $iO.Instruction.Return
                    $Header = @{
                        "Unit" = $Descriptor.Unit;
                        "Value" = $Descriptor.Value;
                        "Description" = $iO.Instruction.Description
                    }
                }
            }
            
            # present the count types as either count of bytes or counts of bms units depending on library data
            Write-Verbose ("[Parser]: Instruction Identification: [" + $Descriptor.Description + "]")
            Return ([PSCustomObject]$Header)
        }

        Function LabelDataArrayValues {
            [CmdletBinding()]
            param($iO)
            $Data = @()
            switch ($iO.Instruction.Return.Unit.Type) {
                Int {
                    Write-Verbose "[Parser]: Using Int array parser"
                    $Values = Get-BMSIntFromByteStream $iO.ByteStreamReceive.ParsedStream[1]
                }
                Byte {
                    Write-Verbose "[Parser]: Using Bytes array parser"
                    $Values = Get-BMSBytesFromByteStream $iO.ByteStreamReceive.ParsedStream[1]
                }
                IntMixedBytes {
                    Write-Verbose "[Parser]: Using Int Mixed with Bytes array parser"
                    $Values = Get-BMSIntMixedBytesFromByteStream $iO.ByteStreamReceive.ParsedStream[1]
                }
                Char {
                    Write-Verbose "[Parser]: Using Char array parser"
                    $Values = Get-BMSCharsFromByteStream $iO.ByteStreamReceive.ParsedStream[1]
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
                Write-Verbose ("[Parser]: Processing: [" + $Values.Count + "] values")
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
                    "Description" = $Descriptor[($i+1)].Description;
                    "Value" = $Values[$i];
                    "Unit" = $Descriptor[($i+1)].Unit
                }
                $Data += [PSCustomObject]$Row
                $i++
            } until ($i -gt ($Descriptor.Count -1))
           

            
            Return ($Data)
        }

    }
    process {
        Write-Verbose ("[Parser]: Instruction Decoding Handler: [" + $iO.Instruction.Return.Value + "]")
        Write-Verbose ("[Parser]: Instruction Description: [" + $iO.Instruction.Alias + "]")
        switch ($iO.Instruction.Return.Value) {
            string {
                $BMSData = [PSCustomObject]@{"0"=(LabelHeaderValues $iO)}
                ($BMSData.0).Value = [string](Get-BMSCharsFromByteStream $iO.ByteStreamReceive.ParsedStream[0])
            }
        
            float {
                $BMSData = [PSCustomObject]@{"0"=(LabelHeaderValues $iO)}
                ($BMSData.0).Value =  ("{0:N}" -f [float](Get-BMSCharsFromByteStream $iO.ByteStreamReceive.ParsedStream[0]))
            }
        
            char {
                $BMSData = [PSCustomObject]@{"0"=(LabelHeaderValues $iO)}
                ($BMSData.0).Value = [char](Get-BMSCharsFromByteStream $iO.ByteStreamReceive.ParsedStream[0])
            }
        
            int  {
                $BMSData = [PSCustomObject]@{"0"=(LabelHeaderValues $iO)}
                ($BMSData.0).Value = ("{0:N}" -f [int](Get-BMSCharsFromByteStream $iO.ByteStreamReceive.ParsedStream[0]))
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
                
                #special fix/hack for LCD3, which packs a value in individual LSB-MSB values 
                if ($iO.Command -eq "LCD3") {
                    $Ah = [bitconverter]::ToInt16(($BMSData.1)[7..8].value,0)
                    $BMSData.1 = ($BMSData.1)[0..5]
                    $BMSData.1 += [PSCustomObject]@{
                        "Unit" = "Ah";
                        "Value" = $Ah;
                        "Description" = "Amp Hours since last charge"
                    }
                }
            }
        
            Default  {
                Write-Warning ("[Parser]: No handler for type [" + $iO.Instruction.Return.Value + "]")
                break
            }
            
        }
        if ($BMSData.1) {
            Write-Verbose ("[Parser]: " + (($BMSData.1)[0]).Description)
            Write-Verbose ("[Parser]: " + (($BMSData.1)[0]).Unit)
            Write-Verbose ("[Parser]: " + (($BMSData.1)[0]).Value)
            Write-Verbose ("[Parser]: Values continue: [" + (($BMSData.1).Count -1) + "] more in data")
        }
        else {
            Write-Verbose ("[Parser]" + ($BMSData.0).Description)
            Write-Verbose ("[Parser]" + ($BMSData.0).Unit)
            Write-Verbose ("[Parser]" + ($BMSData.0).Value)
        }

        $iO | Add-Member -MemberType NoteProperty -Name BMSData -Value $BMSData
        return $iO.PSObject.Copy()
    }
}

