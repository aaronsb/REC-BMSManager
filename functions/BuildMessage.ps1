

Function Add-HexStreamEncapsulation {
    Param($iO)
    foreach ($row in $iO) {
        Write-Verbose ("[MsgBuilder]: Processing command encapsulation: [" + $iO.Command + "]")
        # requires $global:BMSInstructionSet defined
        #assemble header
        #message is the entire message to be sent, including Start, End, checksums, etc.
        #instruction is just the instrction portion of the message.
        
        #Instance array for hexstream
        $HexStream = New-Object System.Collections.Generic.List[System.Object]
        
        #Clear instance of bytestream
        $ByteStream = $null

        #assemble the header, add to message.
        $HexStream.Add($BMSInstructionSet.Config.Message.Components.STX.ToLower())
        $HexStream.Add($BMSInstructionSet.Config.Message.Components.DST.ToLower())
        $HexStream.Add($BMSInstructionSet.Config.Message.Components.SND.ToLower())
        Write-Verbose ("[MsgBuilder]:" + ($HexStream -join "") + " Header (STX)(DST)(SND) appended")

        #count length of all cmd:data bytes in payload, add to message.
        $ByteCount = "{0:x2}" -f [int16]($Row.Hex.Count)
        $HexStream.Add($ByteCount)
        Write-Verbose ("[MsgBuilder]:" + ($ByteCount -join "") + " Instruction byte count appended")

        #add payload bytes to hexstream from instruction object row
        $Row.Hex | %{$HexStream.Add($_)}
        Write-Verbose ("[MsgBuilder]:" + ($Row.Hex -join "") + " Instructions appended")

        #compute/add CRC
        #CRC-16 is calculated [in these bytes] <STX>[<DST><SND><LEN><MSG>[<QRY>]]<CRC><CRC><ETX>
        $CRC = (Get-CRC16 -HexData ($HexStream[1..($HexStream.count)] -Join "")) -replace '..', "$& " -split " "
        
        
        #add crc bytes
        ForEach ($HexByte in $CRC[0..1]) {
            $HexStream.Add($HexByte)
            
        }
        Write-Verbose ("[MsgBuilder]:" + $CRC + "Bytes appended")
        
        
        #add end transmission
        $HexStream.Add($BMSInstructionSet.Config.Message.Components.ETX.ToLower())  
        Write-Verbose ("[MsgBuilder]:" + (($BMSInstructionSet.Config.Message.Components.ETX.ToLower() -join "")) + " Footer assembled (ETX)")

        Write-Verbose ("[MsgBuilder]: Assembly complete")

        $ByteStream = $HexStream | %{[convert]::ToByte($_,16)}
        $ByteStreamSend = (@{
            "RawStream"=$ByteStream;
            "InspectedStream"=($ByteStream | Format-Hex -Encoding ascii)
        })

        $Row | Add-Member -Name "ByteStreamSend" -Type NoteProperty -Value $ByteStreamSend
    }
    return $iO
}

Function Build-BMSMessage {
    [CmdletBinding()]
    Param($iO)

    process {
        Write-Verbose ("[MsgBuilder]: Found [" + $iO.Count + "] instructions to serialize.")
        $iO = Add-HexStreamEncapsulation -iO $iO
        return $iO
    }
}