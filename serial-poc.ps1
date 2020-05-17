
Function Convert-ByteArrayToHex {

    [cmdletbinding()]

    param(
        [parameter(Mandatory=$true)]
        [Byte[]]
        $Bytes
    )

    $HexString = [System.Text.StringBuilder]::new($Bytes.Length * 2)

    ForEach($byte in $Bytes){
        $HexString.AppendFormat("{0:x2}", $byte) | Out-Null
    }

    $HexString.ToString()
}

Function Convert-HexToByteArray {

    [cmdletbinding()]

    param(
        [parameter(Mandatory=$true)]
        [String]
        $HexString
    )

    $Bytes = [byte[]]::new($HexString.Length / 2)

    For($i=0; $i -lt $HexString.Length; $i+=2){
        $Bytes[$i/2] = [convert]::ToByte($HexString.Substring($i, 2), 16)
    }

    $Bytes
}

Function QueryBMS {
$endMessage = "0xAA"
$hexdata = ("55,01,00,05,2a,49,44,4e,3f,a6,fb,aa").Split(",")
#$hexdata = ("55,01,00,05,4c,43,44,31,3f,46,d0,aa").Split(",")
# [55 (Start Transmission)],[01 (Destination Address)],[00 (Sender Address)],[05 (Numner of bytes in payload)],[LCD1? (ascii, instruction)],[46,d0(crc-16)],[aa (End Transmission])]
#calculate crc-16 [in these bytes] 55,[01,00,05,4c,43,44,31,3f],46,d0,aa
$bytes = Convert-HexToByteArray ($hexdata -join "")
$DelaySeconds=1
$PORT='COM6'  
$BAUDRATE=56000  
$Parity=[System.IO.Ports.Parity]::None # System.IO.Ports.Parity  
$dataBits=8  
$StopBits=[System.IO.Ports.StopBits]::one # System.IO.Ports.StopBits  
# END PARAMETERS ---------------------------------  
  
  
$period = [timespan]::FromSeconds($DelaySeconds)  
$port= new-Object System.IO.Ports.SerialPort $PORT,$BAUDRATE,$Parity,$dataBits,$StopBits
$port.ReadTimeout = 1000
$port.WriteTimeout = -1
$port.Open()  
$port.ReadExisting() | Out-Null #clear existing buffer




# Debug  
#Write-Output 'PORT OPENED'  
$StartTime = Get-Date  
# Gets the data from the com port for the specified interval 
$byte = $null
$port.Write([byte[]] $bytes, 0, ($bytes.count))
while ((Get-Date) - $StartTime -lt $period) {   
    $byte = $port.ReadByte()
    if ($byte -eq ""){
        write-warning "no byte found"
    }
    else {
        '{0:x2}' -f $byte
    }
}
$port.Close()  
}


