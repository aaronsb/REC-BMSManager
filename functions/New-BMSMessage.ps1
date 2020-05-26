Function New-BMSMessage {
    [CmdletBinding()]
    Param($iO)
    begin {
        #instance instruction library
        $config = Get-BMSConfigMeta
        #zzz todo merge config and library calls together 
        $Library = $config.Command
        Write-Verbose ("Instruction count" + $iO.Count)
        if ($iO.Count -gt $Config.Config.Session.MaxMessagesPer) {
            Throw ("Maximum number of encoded messages per session allowed is " + $Config.Config.Session.MaxMessagesPer + ".`r`nTry again with fewer messages.")
        }
        #clear any previous object name $iO
        $iO = $null

        Function private:Add-HexStreamStack {
            Param($iO)
            ForEach ($Row in $iO) {
                $Stream = @()
                $Stream += ($Row.Command.ToCharArray() | %{"{0:x2}" -f [int16][char]$_})
                $Stream += $Row.Hex
                $Row | Add-Member -MemberType NoteProperty -Name HexStream -Value $Stream
            }
            return $iO
        }

        Function private:Add-HandlerEventCounts {
            Param($iO)
            foreach ($Row in $iO) {
                $HandlerCount = 0
                $Book = $null
                $Book = $Library | ?{$_.Instruction -eq $Row.Command}
                if ($Book.Return.Value -ne "Array") {
                    $HandlerCount = $HandlerCount + $Book.Return.Unit.Count
                }
                else {
                    $HandlerCount = $HandlerCount + ($Book.Return.Unit.Array.Part | Sort-Object -Unique).Count
                }
                $Row | Add-Member -MemberType NoteProperty -Name HandlerEvents -Value $HandlerCount
            }
            return $iO
        }

        
    }

    process {
        #load configuration metadata for use
        
        #Generate the InstructionObject container that holds the entire instruction stack and metadata
        #$Instructions should be verified with Approve-BMSInstructionList, which emits a hash array of instruction:command pairs
        #after verifying each against an instruction dictionary (encyclopedia?)
        
        <#
                if (!$iO)
        {
            #if no instruction given, just barf out all of them. What could go wrong?
            Throw "Need at least one instruction hash pair object. Preferably validated with Approve-BMSInstructionList first."
        }
        
        #>

        Add-HexStreamStack -Instructions $iO
        Add-HandlerEventCounts -Instructions $iO
        
        
        Write-Verbose ("Found" + $iO.Count + " instructions to serialize.")
        #region enumerate instructions
        #assemble header
        #message is the entire message to be sent, including Start, End, checksums, etc.
        #instruction is just the instrction portion of the message.
        
        #Instance array for hexstream
        $HexStream = New-Object System.Collections.Generic.List[System.Object]
        
        #assemble the header, add to message.
        $HexStream.Add($config.Config.Message.Components.STX.ToLower())
        $HexStream.Add($config.Config.Message.Components.DST.ToLower())
        $HexStream.Add($config.Config.Message.Components.SND.ToLower())
        Write-Verbose ("[HexStream]: Header (STX)(DST)(SND) appended")

        #assemble the instruction subarray

        #make the hex stream here

        #count length of all cmd:data bytes in payload, add to message.
        $HexStream.Add("{0:x2}" -f [int16](($io.Hexstack.Stream | %{$_}) | %{"{0:x2}" -f $_}).Count)
        Write-Verbose ("[HexStream]: Instruction bytecount appended")


        ForEach ($HexByte in (($io.Hexstack.Stream | %{$_}) | %{"{0:x2}" -f $_})) {
            $HexStream.Add($HexByte)
        }
        Write-Verbose ("[HexStream]: (cmd:value) Instruction(s) appended")

        #compute/add CRC
        #CRC-16 is calculated [in these bytes] <STX>[<DST><SND><LEN><MSG>[<QRY>]]<CRC><CRC><ETX>
        $CRC = (Get-CRC16 ($HexStream[1..($HexStream.count)] -Join "")) -replace '..', "$& " -split " "
        Write-Verbose ("[HexStream]: CRC caclulated: " + $CRC)
        
        
        #add crc bytes
        ForEach ($HexByte in $CRC[0..1]) {
            $HexStream.Add($HexByte)
        }
        Write-Verbose ("[HexStream]: CRC Bytes appended")

        #add end transmission
        $HexStream.Add($config.Config.Message.Components.ETX.ToLower())  
        Write-Verbose ("[HexStream]: Footer assembled (ETX)")

        Write-Verbose "[HexStream]: Assembly complete"
        #return the message as a hash array
        #next better version of this should be to define a custom class for this.
        
        $HexDataInspection = ((Convert-HexToByteArray -HexString ($HexStream -join "") | %{[char][int16]$_}) -join "") | Format-Hex
        $iO | Add-Member -Name "HexStreamSend" -Type NoteProperty -Value (@{"HandlerEventCount"=(Add-HandlerEventCounts $iO);"RawStream"=$HexStream;"InspectedStream"=$HexDataInspection;"ParsedStream"=(Sort-MessageStream $HexStream)})
        return $iO
    }
}