Function Sort-MessageStream
{
    [CmdletBinding()]
    param($HexString)
    $MultiPart = [ordered]@{}
    $ID = 0
    $b = 0
    #$part holds the substring stream of the entire hex array
    $Part = New-Object System.Collections.Generic.List[System.Object]
    #in the raw stream, for each byte, inspect for <STX> and <ETX>
    ForEach ($byte in $HexString) {
        $Part.Add($HexString[$b])
        if ($HexString[$b] -match "aa") {
            if (($HexString[$b + 1]) -eq "55") {
                $MultiPart.Add($ID,$Part)
                $ID++
                $Part = New-Object System.Collections.Generic.List[System.Object]
                Write-Verbose "New Message Continues"
            }
            else
            {
                $MultiPart.Add($ID,$Part)
                $ID++
                Write-Verbose "No New Messages"
            }
        }
        $b++
        }
    return $MultiPart
}
