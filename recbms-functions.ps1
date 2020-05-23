

Class BMSInstruction
{
    [String]$Instruction
    [String]$Data
    BMSInstruction ([string]$instruction,[string]$Data) {
        $this.Instruction = $Instruction
        $this.Data = $Data
    }
}

filter isFloat() {
    return $_ -is [float] -or $_ -is [double] -or $_ -is [decimal]
}

filter isInt() {
    return $_ -is [int]
}

filter isChar() {
    return $_ -is [char] -or $_ -is [string]
}






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

Function Get-BMSInstructionList {
    [CmdletBinding()]
    Param([ValidateSet("String","Array","Range")][String]$Handler,[Switch]$Common)

    process {
        $object = gc .\instructionset.json | ConvertFrom-Json
        $selection = $object.Command | Select-Object -Property Alias,Instruction,Category,Handler
        if ($Common) {
            Write-Verbose ("Selected common instructions") 
                Write-Verbose "Can't use Category or Handler filters with Common switch."
                $selection = $object.Command | ?{$_.Common -eq $true} | Select-Object -Property Alias,Instruction,Category,Handler
        }
        else {
            if ($Category) {
                Write-Verbose ("Selected " + $Category + " category type") 
                $selection = $object.Command | ?{$_.Category -match $Category} | Select-Object -Property Alias,Instruction,Category,Handler
            }
            if ($Handler)
            {
                Write-Verbose ("Selected " + $Handler + " type handler")
                $selection = $object.Command | ?{$_.Handler -match $Handler} | Select-Object -Property Alias,Instruction,Category,Handler
            }
        }
    return $selection
    }
    
}




Function Get-BMSConfigMeta {
    (gc .\instructionset.json | ConvertFrom-Json)
}










Function New-BMSSessionObject {
    [CmdletBinding()]
    Param($Command)
    begin {
        $Command = Invoke-CmdPreprocessor $Command
        #instance instruction library
        $Config = Get-BMSConfigMeta
        #zzz todo merge config and library calls together 
        $sO = [pscustomobject]@{}
        $MaxMessagePerSession = $Config.Config.Session.MaxMessagesPer
        $StreamIndex = 0
        $FirstCommandIndex = 0
        $LastCommandIndex = 0
    }

    # MaxMessagePerSession = 3
    # (4 total commands)
    # Stream 0
    #   Command,Command,Command
    # Stream 1
    #   Command
    #
    # MaxMessagePerSession = 1
    # (4 total commands)
    # Stream 0
    #   Command
    # Stream 1
    #   Command
    # Stream 2
    #   Command
    # Stream 3
    #   Command
    
    process {

        $Command = Approve-BMSInstructionList -Command $Command
        
        do {
            $sO | Add-Member -MemberType NoteProperty -Name $StreamID -Value $null
            do {
                $LastCommandIndex = $LastCommandIndex + $MaxMessagePerSession
                if (($LastCommandIndex +1)-gt $Command.Count) {
                    $LastCommandIndex = $Command.Count
                }
                $BMSMessage = $Command[$FirstCommandIndex..$LastCommandIndex]
                #New-BMSMessage -Instructions
                $FirstCommandIndex = $LastCommandIndex + 1
                $CommandID++
            } until ($CommandID -gt $Command.Count)
            $sO.$StreamID = $BMSMessage
            $StreamID++
        } until ($CommandID -gt $Command.Count)

    end {
        return $sO
    }
}
}




Function Invoke-BMSCommunication {
[cmdletbinding()]
Param($iO)
    begin {
        #trap all errors.
        trap {
        Write-Error "Something died! Closing COM port."
        $port.Close()
        break
        }

        #Define a watch dog object to use in serial communication timeouts.
        $WatchDog = New-Object -TypeName System.Diagnostics.Stopwatch
        #convert the hex string to a byte array.
        $SendBytes = Convert-HexToByteArray ($iO.HexStreamSend.RawStream -join "")
        #load configuration metadata for comm session
        $config = Get-BMSConfigMeta
        #define array for return data stream
        
        #enumerate the configurable list from the metadata
        #the items in the metadata exactly match properties for a System.IO.Ports.SerialPort object
        $SerialConfigurables = $config.Config.Client.PSObject.Properties.Name
        #create a new serial port object.
        $Port = new-Object System.IO.Ports.SerialPort

        #set properties in the serial port.
        try {
            ForEach ($item in $SerialConfigurables) {
                $port.$item = $config.Config.Client.$item
            }
        }
        catch {
            Throw "Couldn't set a System.IO.Ports.SerialPort configurable from configuration metadata"
        }

    }

    process {
        
        
        
        
        #start the timer for transmit event.
        $WatchDog.Start()
        #open the port this session
        $port.Open()

        try {
           
            #clear existing buffer, just in case something is sending on the line
            #this could probably be built more robust, but for now it's at least an acknowledgement that the line should be clear.
            $port.ReadExisting() | Out-Null
            
            #Write the message on the line. Bon Voyage!
            Write-Verbose ("Sending " + $SendBytes.count + " bytes on " + $port.PortName)
            $port.Write([byte[]] $SendBytes, 0, ($SendBytes.count))
            Write-Verbose "Sucessful TX of instruction"
        }
        catch {
            #catch the rest of the errors related to opening serial ports.
            $Error[0]
            $port.Close()
            break
        }
        #port stays open
        #stop the timer for transmit event.
        $WatchDog.Stop()
        Write-Verbose ("Serial TX milliseconds: " + $WatchDog.ElapsedMilliseconds)
        #reset the timer for the next event.
        $WatchDog.Reset()

        #Wait a specified number of milliseconds. 250ms is the default configured in metadata.
        Start-Sleep -m $config.Config.Session.SessionThrottle
        
        #create a new pscustomobject array to store multiparts of stream
        $MultiPartObject = New-Object PSCustomObject
        
        #Number of expected message parts to be returned.
        #Usually arrays are 2 parts, informational then the data.
        #everything else is 1 part
        $PartCount = $iO.HexStreamSend.HandlerEventCount

        #initalize byte index
        $i = 0
        
        #estimated number of bytes for Stream
        $StreamLengthEstimate = 0
       
        #initalize start transmission (sub)index
        $thisSTX = 0

        #initalize end transmission (sub)index
        $thisETX = 0
        
        #initalize length (sub)index
        $thisLEN = 0
        
        #initalize (sub)length value 
        $StreamPartLength = 0

        #initalize message part index
        $IndexMessagePart = 1
        
        #initialize empty array to store all bytes
        $Stream = New-Object System.Collections.Generic.List[System.Object]

        Write-Verbose ("Expecting " + $PartCount + " parts in bytestream")


        #start the timer for the receieve event.
        $WatchDog.Start()
        
        do {
            #null this iteration of data collection in loop (to stay sanitary)
            $Data = $null
            try {
                #if the count of bytes collected in stream is greater than the estimated stream length
                #and
                #the index of message parts is greater than the parts count defined from the dictonary for this particular instruction
                #(because some instructions are multi part messages, and we get multiple ETX bytes in a single Received transsmission session)
                #then
                #bail from loop before the next ReadByte() so we don't incur a buffer exception.


                if ($IndexMessagePart -gt $PartCount)
                {
                    Write-Verbose ("Reached expected message part count defined for this instruction.")
                    $port.Close()
                    $WatchDog.Stop()
                    Write-Verbose ("Closed Port " + $port.PortName)
                    Write-Verbose ("Received " + $Stream.count + " bytes on " + $port.PortName)
                    Write-Verbose ("Serial RX milliseconds: " + $WatchDog.ElapsedMilliseconds)
                    $WatchDog.Reset()
                    Write-Verbose "Returning stream"
                    
                    #return the message as a hash array
                    #next better version of this should be to define a custom class for this.
                    $HexDataInspection = ((Convert-HexToByteArray -HexString ($Stream -join "") | %{[char][int16]$_}) -join "") | Format-Hex
                    $iO | Add-Member -Name "HexStreamReceive" -Type NoteProperty -Value (@{"RawStream"=$Stream;"InspectedStream"=$HexDataInspection;"ParsedStream"=(Sort-MessageStream $Stream)})
                    Verify-MessageCRC $iO | out-null
                    return $iO
                }

                #read a byte, format it as two position payload. If it reads a 4 position payload, something has gone wrong
                #with the serial port setup.
                $Data = "{0:x2}" -f $port.ReadByte()
                #add retrieved byte to stream array
                $Stream.Add($Data)

                #IF Case matches byte <STX>
                if (($Data) -match "55")
                {
                    #Save this index of STX from the stream index (which will keep incrementing)
                    $thisSTX = $i
                    #add 3 bytes of offset to get the index of length. We may not have Received this byte yet, this is a future lookup.
                    $thisLEN = $thisSTX + 3
                    Write-Verbose ("---------- <Detected: <STX>[$thisSTX]>---------- Begin Part " + $IndexMessagePart + " ---------- <")
                    #Write-Verbose ("Length value is probably: " + )
                }

                Write-Verbose ("PartIndex:[$IndexMessagePart] StreamIndex:[$i] ReadByte:[" + $Data + "]")

                #IF Case matches byte <ETX>
                if (($Data) -match "aa")
                {
                    #increment the completed message part counter
                    $thisETX = $i
                    Write-Verbose ("---------- <Detected: <ETX>[$thisETX]>---------- End Part " + $IndexMessagePart + " ---------- <")
    
                    #add the bytes stored in $MultiPartObject to our little PSCustomObject briefcase
                    #inncrement the message part count index, since we found <ETX> in the stream
                    $IndexMessagePart++
                }
                $i++
                
            }
            catch [System.TimeoutException]{
                #clean up the port and report error. :(
                Write-Error "End of buffer exception!"
                $port.Close()
                Write-Verbose ("Closed Port " + $port.PortName)
                $WatchDog.Stop()
                Write-Verbose ("Received " + $Stream.count + " bytes on " + $port.PortName)
                Write-Verbose ("Serial RX milliseconds: " + $WatchDog.ElapsedMilliseconds)
                $WatchDog.Reset()
                Write-Verbose "Returning stream"
                #return the message as a hash array
                #next better version of this should be to define a custom class for this.
                $HexDataInspection = ((Convert-HexToByteArray -HexString ($Stream -join "") | %{[char][int16]$_}) -join "") | Format-Hex
                $io | Add-Member -Name "HexStreamReceive" -Type NoteProperty -Value (@{"RawStream"=$Stream;"InspectedStream"=$HexDataInspection;"ParsedStream"=(Sort-MessageStream $Stream)})
                Verify-MessageCRC $iO | out-null
                return $iO
                #this error is a failure and can cause dependent calls to fall on their face
                #if (unlikely) any good data comes out, crc check will provide some validation
            }
        } until ($WatchDog.ElapsedMilliseconds -ge $config.Config.Session.SessionTimeout)

        #this exit condition is one where watchdog caught the hard timeout.
        #clean up the port and report our findings.
        Write-Warning ("Serial timeout occured. Hard stop at " + $config.Config.Session.SessionTimeout + " milliseconds")
        $port.Close()
        Write-Verbose ("Closed Port " + $port.PortName)
        $WatchDog.Stop()
        Write-Verbose ("Received " + $Stream.count + " bytes on " + $port.PortName)
        Write-Verbose ("Serial RX milliseconds: " + $WatchDog.ElapsedMilliseconds)
        $WatchDog.Reset()
        Write-Verbose "Returning stream"
        #return the message as a hash array
        #next better version of this should be to define a custom class for this.
        $HexDataInspection = ((Convert-HexToByteArray -HexString ($Stream -join "") | %{[char][int16]$_}) -join "") | Format-Hex
        $iO | Add-Member -Name "HexStreamReceive" -Type NoteProperty -Value (@{"RawStream"=$Stream;"InspectedStream"=$HexDataInspection;"ParsedStream"=(Sort-MessageStream $Stream)})
        Verify-MessageCRC $iO | out-null
        return $iO
        #this error is a failure and can cause dependent calls to fall on their face
        #if (unlikely) any good data comes out, crc check will provide some validation
    }
    
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
