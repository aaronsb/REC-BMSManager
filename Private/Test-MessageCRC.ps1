Function Test-MessageCRC {
    [CmdletBinding()]
    param($iOInstance)
    $CRCStream = [ordered]@{}
    $i=0
        do {
            #offset length index -1 for array count, and -2 for crc and -1 for etx 
            $CRCOffset = ($iOInstance.ByteStreamReceive.ParsedStream[$i].Length -4)
            #get bytes for crc calculation
            $CRCTask = $iOInstance.ByteStreamReceive.ParsedStream[$i][1..($CRCOffset)]

            #Old crc is two bytes before etx
            $OldCRC = ($iOInstance.ByteStreamReceive.ParsedStream[$i][($CRCOffset +1)..($CRCOffset +2)] | ForEach-Object {"{0:x2}" -f $_}) -join ""

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
    until ($iOInstance.ByteStreamReceive.ParsedStream.Count -eq $i)

    $iOInstance.ByteStreamReceive.Add("CRCStream",$CRCStream)
    return $iOInstance
    #compute/add CRC
    #CRC-16 is calculated [in these bytes] <STX>[<DST><SND><LEN><MSG>[<QRY>]]<CRC><CRC><ETX>
}