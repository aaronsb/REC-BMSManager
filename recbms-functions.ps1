
#REQUIRES -Version 3.0
Function Get-CRC16($hexdata) {

    $bytes = Convert-HexToByteArray ($hexdata -join "")
    $CRCTable = 0x0000, 0xC0C1, 0xC181, 0x0140, 0xC301, 0x03C0, 0x0280, 0xC241,

            0xC601, 0x06C0, 0x0780, 0xC741, 0x0500, 0xC5C1, 0xC481, 0x0440,

            0xCC01, 0x0CC0, 0x0D80, 0xCD41, 0x0F00, 0xCFC1, 0xCE81, 0x0E40,

            0x0A00, 0xCAC1, 0xCB81, 0x0B40, 0xC901, 0x09C0, 0x0880, 0xC841,

            0xD801, 0x18C0, 0x1980, 0xD941, 0x1B00, 0xDBC1, 0xDA81, 0x1A40,

            0x1E00, 0xDEC1, 0xDF81, 0x1F40, 0xDD01, 0x1DC0, 0x1C80, 0xDC41,

            0x1400, 0xD4C1, 0xD581, 0x1540, 0xD701, 0x17C0, 0x1680, 0xD641,

            0xD201, 0x12C0, 0x1380, 0xD341, 0x1100, 0xD1C1, 0xD081, 0x1040,

            0xF001, 0x30C0, 0x3180, 0xF141, 0x3300, 0xF3C1, 0xF281, 0x3240,

            0x3600, 0xF6C1, 0xF781, 0x3740, 0xF501, 0x35C0, 0x3480, 0xF441,

            0x3C00, 0xFCC1, 0xFD81, 0x3D40, 0xFF01, 0x3FC0, 0x3E80, 0xFE41,

            0xFA01, 0x3AC0, 0x3B80, 0xFB41, 0x3900, 0xF9C1, 0xF881, 0x3840,

            0x2800, 0xE8C1, 0xE981, 0x2940, 0xEB01, 0x2BC0, 0x2A80, 0xEA41,

            0xEE01, 0x2EC0, 0x2F80, 0xEF41, 0x2D00, 0xEDC1, 0xEC81, 0x2C40,

            0xE401, 0x24C0, 0x2580, 0xE541, 0x2700, 0xE7C1, 0xE681, 0x2640,

            0x2200, 0xE2C1, 0xE381, 0x2340, 0xE101, 0x21C0, 0x2080, 0xE041,

            0xA001, 0x60C0, 0x6180, 0xA141, 0x6300, 0xA3C1, 0xA281, 0x6240,

            0x6600, 0xA6C1, 0xA781, 0x6740, 0xA501, 0x65C0, 0x6480, 0xA441,

            0x6C00, 0xACC1, 0xAD81, 0x6D40, 0xAF01, 0x6FC0, 0x6E80, 0xAE41,

            0xAA01, 0x6AC0, 0x6B80, 0xAB41, 0x6900, 0xA9C1, 0xA881, 0x6840,

            0x7800, 0xB8C1, 0xB981, 0x7940, 0xBB01, 0x7BC0, 0x7A80, 0xBA41,

            0xBE01, 0x7EC0, 0x7F80, 0xBF41, 0x7D00, 0xBDC1, 0xBC81, 0x7C40,

            0xB401, 0x74C0, 0x7580, 0xB541, 0x7700, 0xB7C1, 0xB681, 0x7640,

            0x7200, 0xB2C1, 0xB381, 0x7340, 0xB101, 0x71C0, 0x7080, 0xB041,

            0x5000, 0x90C1, 0x9181, 0x5140, 0x9301, 0x53C0, 0x5280, 0x9241,

            0x9601, 0x56C0, 0x5780, 0x9741, 0x5500, 0x95C1, 0x9481, 0x5440,

            0x9C01, 0x5CC0, 0x5D80, 0x9D41, 0x5F00, 0x9FC1, 0x9E81, 0x5E40,

            0x5A00, 0x9AC1, 0x9B81, 0x5B40, 0x9901, 0x59C0, 0x5880, 0x9841,

            0x8801, 0x48C0, 0x4980, 0x8941, 0x4B00, 0x8BC1, 0x8A81, 0x4A40,

            0x4E00, 0x8EC1, 0x8F81, 0x4F40, 0x8D01, 0x4DC0, 0x4C80, 0x8C41,

            0x4400, 0x84C1, 0x8581, 0x4540, 0x8701, 0x47C0, 0x4680, 0x8641,

            0x8201, 0x42C0, 0x4380, 0x8341, 0x4100, 0x81C1, 0x8081, 0x4040
            
        $tempCRC = 0x0000
    
     
    
        Foreach ($l in $bytes) 
    
        {
    
     
    
          $part1=$CRCTable[($tempCRC -bxor $l) -band 0xff]
    
          if ($tempCRC -ge 0) {$part2=($tempCRC -shr 8)} else {$part2=($tempCRC -shr 8)+(2 -shl (-bnot 8))}
    
     
    
          $tempCRC =$part1 -bxor $part2  
    
        }
    
    "{0:x}" -f ($tempCRC)
    
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
    $object = gc .\instructionset.json | ConvertFrom-Json
    $object.command | Select-Object -Property Instruction,Name,Category
}


Function Get-BMSConfigMeta {
    gc .\config.json | ConvertFrom-Json
}

Function Get-BMSInstruction {
    [CmdletBinding()]
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
        #instance instruction library
        $object = gc .\instructionset.json | ConvertFrom-Json
        #save the instruction object as equaling the autocompleted instruction. 
        $instructionObject = $object.Command | ?{$_.Instruction -eq $instruction}
        #small fix for butthole character *, causes problems :)
        if ($instructionObject.Instruction -eq "_IDN")
        {$instructionObject.Instruction = "*IDN"}
        #return the selected instruction as an object from library
        if (!$InstructionObject)
        {
            throw "Named instruction not found. Check JSON library for errors."
        }
        else {
            return $instructionObject
        }
    }
}

Function New-BMSMessage {
[CmdletBinding()]
Param($value)
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
        #load configuration metadata for use
        $config = Get-BMSConfigMeta
    
    if (!$instruction)
    {
        #if no instruction given, just barf out all of them. What could go wrong?
        Get-BMSInstructionList
        return
    }
    else {
        #got an instruction name, try getting it
        try {
            $iO = Get-BMSInstruction $instruction
        }
        catch {
            Throw ("Instruction " + $instruction + " is invalid. Check JSON library for errors.")
        }
    }
   
   
    
    #region enumerate instructions
    #assemble header
    #message is the entire message to be sent, including Start, End, checksums, etc.
    #instruction is just the instrction portion of the message.
    
    #instance two arrays, one for message, and one for the instruction only.
    $message = New-Object System.Collections.Generic.List[System.Object]
    $instruction = New-Object System.Collections.Generic.List[System.Object]

    #assemble the header, add to message.
    $message.Add($config.Message.Components.STX.ToLower())
    $message.Add($config.Message.Components.DST.ToLower())
    $message.Add($config.Message.Components.SND.ToLower())
    
    #assemble the instruction subarray
    $iO.Instruction.ToCharArray() | %{"{0:x}" -f [int16]$_} | %{$instruction.Add($_)}
    
    if ($value) {
        #zzz TODO: construct a "WRITE" message. For now, let's just concentrate on read only messages ;)
        #parse instruction set to package value being set here
        Write-Warning "Not Implemented. (yet!)"
        break
    }
    else
    {
        #no $value defined, so this will be a read only query.
        #add configured query value to subarray. It's default is am ASCII ? (0x3F)
        $instruction.Add($config.message.components.QRY.ToLower())
    }

    #count length of instruction bytes in payload, add to message.
    $message.Add("{0:x2}" -f [int16]$instruction.count)
    $instruction | %{$message.Add($_)}
    
    #compute/add CRC
    #CRC-16 is calculated [in these bytes] <STX>[<DST><SND><LEN><MSG>[<QRY>]]<CRC><CRC><ETX>
    $crc = (Get-CRC16 ($message[1..($message.count)] -Join "")) -replace '..', "$& " -split " "
    
    #add First byte of CRC
    $message.Add($crc[0])
    
    #add second byte of CRC
    $message.Add($crc[1])
    
    #add end transmission
    $message.Add($config.Message.Components.ETX.ToLower())  
    
    #return the message
    return $message -join ""
    }
}


Function Invoke-BMSCommunication {
[cmdletbinding()]
Param($message)
    begin {
        #trap all errors.
        trap {
        Write-Error "Something died! Closing COM port."
        $port.Close()
        break
        }
    }
    
    process {
        #Define a watch dog object to use in serial communication timeouts.
        $WatchDog = New-Object -TypeName System.Diagnostics.Stopwatch
        #convert the hex string to a byte array.
        $bytes = Convert-HexToByteArray ($message -join "")
        #load configuration metadata for comm session
        $config = Get-BMSConfigMeta
        #define array for return data stream
        $Stream = New-Object System.Collections.Generic.List[System.Object]
        #enumerate the configurable list from the metadata
        #the items in the metadata exactly match properties for a System.IO.Ports.SerialPort object
        $SerialConfigurables = $config.client.psobject.properties.name
        #create a new serial port object.
        $Port = new-Object System.IO.Ports.SerialPort

        #set properties in the serial port.
        try {
            foreach ($item in $SerialConfigurables) {
                $port.$item = $config.Client.$item
            }
        }
        catch {
            Throw "Couldn't set a System.IO.Ports.SerialPort configurable from configuration metadata"
        }
        
        
        #start the timer for transmit event.
        $WatchDog.Start()
        try {
            #open the port
            $port.Open() 

            #clear existing buffer, just in case something is sending on the line
            #this could probably be built more robust, but for now it's at least an acknowledgement that the line should be clear.
            $port.ReadExisting() | Out-Null
            
            #Write the message on the line. Bon Voyage!
            Write-Verbose ("Sending " + $bytes.count + " bytes on " + $port.PortName)
            $port.Write([byte[]] $bytes, 0, ($bytes.count))
            Write-Verbose "Sucessful TX of instruction"
        }
        catch {
            #catch the rest of the errors related to opening serial ports.
            $Error[0]
            break
        }

        #stop the timer for transmit event.
        $WatchDog.Stop()
        Write-Verbose ("Serial TX milliseconds: " + $WatchDog.ElapsedMilliseconds)
        #reset the timer for the next event.
        $WatchDog.Reset()

        #Wait a specified number of milliseconds. 250ms is the default configured in metadata.
        Start-Sleep -m $config.Session.SessionThrottle
        
        #zzz todo
        #modify this stream parser so it's smarter
        #instead of exception at end of buffer,
        #try reading the stream and reading ahead only the bytes indicated in the stream 
        #ah, maybe eventually.

        #do loop for collecting data bytes off the wire. There is an inherent expectation/assumption that there is only
        #one response on the wire expected at a time. This connection is not chatty at all.
        
        #start the timer for the receieve event.
        $WatchDog.Start()
        do {
            #null this iteration of data collection in loop
            $Data = $null
            try {
                #read a byte, format it as two position payload. If it reads a 4 position payload, something has gone wrong
                #with the serial port setup.
                $Data = "{0:x2}" -f $port.ReadByte()
                
                #if there's data returned, add to return stream.
                if ($Data)
                {
                    #add byte to the array.
                    $Stream.Add($Data)
                }
            }
            catch [System.TimeoutException]{
                #this is how the do loop ends right now. we can do better. see the zzz todo about intelligent stream parsing.
                
                #clean up the port and report our findings.
                Write-Verbose "Caught end of buffer exception"
                $port.Close()
                $WatchDog.Stop()
                Write-Verbose ("Closed Port " + $port.PortName)
                Write-Verbose ("Recieved " + $Stream.count + " bytes on " + $port.PortName)
                Write-Verbose ("Serial RX milliseconds: " + $WatchDog.ElapsedMilliseconds)
                $WatchDog.Reset()
                Write-Verbose "Returning stream"
                return $Stream
            }
        } until ($WatchDog.ElapsedMilliseconds -ge $config.Session.SessionTimeout)
        #} until ($Data -eq $null)

        #this exit condition is one where watchdog caught the hard timeout.
        #clean up the port and report our findings.
        Write-Warning ("Serial timeout occured. Hard stop at " + $config.Session.SessionTimeout + " milliseconds")
        $port.Close()
        $WatchDog.Stop()
        Write-Verbose ("Closed Port " + $port.PortName)
        Write-Verbose ("Recieved " + $Stream.count + " bytes on " + $port.PortName)
        Write-Verbose ("Serial RX milliseconds: " + $WatchDog.ElapsedMilliseconds)
        $WatchDog.Reset()
        Write-Verbose "Returning stream"
        return $Stream
    }
    
}

Function New-BMSConversation
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
            Invoke-BMSCommunication (New-BMSMessage -Instruction $Instruction)
        }
}


<#
Some placeholder stuff for testing.
#$inst = ("LCD1","LCD3","CELL","PTEM","RINT","BTEM","ERRO")
#$inst | %{New-BMSConversation $_}
#$inst | %{New-BMSMessage -Instruction $_} | %{Invoke-BMSCommunication $_}
#Invoke-BMSCommunication (New-BMSMessage -Instruction _IDN)
#>