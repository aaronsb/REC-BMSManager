Function Add-HexStreamEncapsulation {
    Param($iO)
    foreach ($row in $iO) {
        # requires $global:BMSInstructionSet defined
        #assemble header
        #message is the entire message to be sent, including Start, End, checksums, etc.
        #instruction is just the instrction portion of the message.
        
        #Instance array for hexstream
        $HexStream = New-Object System.Collections.Generic.List[System.Object]
        
        #assemble the header, add to message.
        $HexStream.Add($BMSInstructionSet.Config.Message.Components.STX.ToLower())
        $HexStream.Add($BMSInstructionSet.Config.Message.Components.DST.ToLower())
        $HexStream.Add($BMSInstructionSet.Config.Message.Components.SND.ToLower())
        Write-Verbose ("[HexStream]:" + ($HexStream -join "") + " Header (STX)(DST)(SND) appended")

        #count length of all cmd:data bytes in payload, add to message.
        $ByteCount = "{0:x2}" -f [int16]($Row.Hex.Count)
        $HexStream.Add($ByteCount)
        Write-Verbose ("[HexStream]:" + ($ByteCount -join "") + " Instruction byte count appended")

        #add payload bytes to hexstream from instruction object row
        $Row.Hex | %{$HexStream.Add($_)}
        Write-Verbose ("[HexStream]:" + ($Row.Hex -join "") + " Instructions appended")

        #compute/add CRC
        #CRC-16 is calculated [in these bytes] <STX>[<DST><SND><LEN><MSG>[<QRY>]]<CRC><CRC><ETX>
        $CRC = (Get-CRC16 ($HexStream[1..($HexStream.count)] -Join "")) -replace '..', "$& " -split " "
        
        
        #add crc bytes
        ForEach ($HexByte in $CRC[0..1]) {
            $HexStream.Add($HexByte)
            
        }
        Write-Verbose ("[HexStream]:" + $CRC + "Bytes appended")
        #add end transmission

        $HexStream.Add($BMSInstructionSet.Config.Message.Components.ETX.ToLower())  
        Write-Verbose ("[HexStream]:" + (($BMSInstructionSet.Config.Message.Components.ETX.ToLower() -join "")) + " Footer assembled (ETX)")

        Write-Verbose ("[HexStream]: Assembly complete")
        $HexDataInspection = $HexStream | %{[convert]::ToByte($_,16)} | Format-Hex
        $HexStreamSend = (@{
            "HandlerEventCount"=($Row.HandlerEventCount);
            "RawStream"=$HexStream;
            "InspectedStream"=$HexDataInspection;
            "ParsedStream"=(Sort-MessageStream $HexStream)
        })
        $Row | Add-Member -Name "HexStreamSend" -Type NoteProperty -Value $HexStreamSend
    }
    return $iO
}

Function Build-BMSMessage {
    [CmdletBinding()]
    Param($iO)

    process {
        Write-Verbose ("Found" + $iO.Count + " instructions to serialize.")
        Write-Verbose ("Processing command encapsulation(s)")
        $iO = Add-HexStreamEncapsulation -iO $iO
        return $iO
    }
}