

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



#REQUIRES -Version 3.0
Function Get-CRC16($hexdata) {
    [CmdletBinding()]
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
    
     
    
        ForEach ($l in $bytes) 
    
        {
    
     
    
          $part1=$CRCTable[($tempCRC -bxor $l) -band 0xff]
    
          if ($tempCRC -ge 0) {$part2=($tempCRC -shr 8)} else {$part2=($tempCRC -shr 8)+(2 -shl (-bnot 8))}
    
     
    
          $tempCRC =$part1 -bxor $part2  
    
        }
    
    "{0:x4}" -f ($tempCRC)
    
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
    gc .\config.json | ConvertFrom-Json
}

Function Approve-BMSInstructionList {
    [CmdletBinding(DefaultParameterSetName='Command')]
    param (
        [Parameter(ValueFromPipeline)]
        [Parameter(Mandatory = $true, ParameterSetName = 'Command')]$Command
    )

    begin {
        #begin region
        #check to see if input object is of one of the required types
        #I'm conflicted between requiring an ordered dictionary hashtable and just a regular old hashtable
        #I think it makes sense from a "less complexity" perspective to use a hashtable since a multi-instruction
        #sentence doesn't really matter the order in which it's sent to the BMS controller
        #before the object is consumed by the serial stream processor function, it's cast internally into an ordered
        #dictionary since I need to keep track of which command was executed in which order for decoding purposes

        switch ($Command.GetType().BaseType.Name) {
            "Hashtable" {
                Write-Verbose "Case: Command Type Hashtable"
                Write-Verbose ("Processing " + $Command.Keys.Count + " command(s)")
                Write-Verbose ("Commands to execute: " + $Command.Keys)
            }
            "String" {
                Write-Verbose "Case: Command Type String"
                #give an option of just typing an instruction in - this will be cast into a single hashtable
                #with the instruction set as a query only
                Write-Verbose ("Casting command string to single query")
                $Command = @{$Command=""}
            }
            "Array" {
                Write-Verbose "Case: Command Type Array of Strings"
                #give an option of just typing instructions in a comma delimited form in - this will be cast into a hashtable
                #with the instruction set as a query only
                $CommandList = @{}
                forEach ($item in $Command) {
                    $CommandList.Add($item.ToString(),"?")
                }
                $Command = $CommandList
            }
            Default {
                #maaaybe make this more helpful
                Throw ("Command syntax error. :)")
            }
        }
        #instance instruction library
        $Library = (gc .\instructionset.json | ConvertFrom-Json).Command
        
        #instance the instructionObject as an ordered dictionary
        $iO = New-Object PSCustomObject
        
        #instance an ordered array to contain packaged instruction(s)
        $InstructionStack = New-Object System.Collections.Generic.List[System.Object]

        #define a private validation function

        Function MinMaxValidate{
            param($instructionValue, $Book)
            if ([double]$Command.$Key -ge [double]$Book.Range.Min) {
                if ([double]$Command.$Key -le [double]$Book.Range.Max) {
                    Write-Verbose ("[" + $Command.$Key + " <= " + $Book.Range.Max + "]: RangeMax Accepted")
                    $thisMinMax.Max = $true
                }
                else {
                    $thisMinMax.Max = $false
                    Write-Verbose ("[" + $Command.$Key + " !<= " + $Book.Range.Max + "]: RangeMax NOT Accepted")
                }
                Write-Verbose ("[" + $Command.$Key + " >= " + $Book.Range.Min + "]: RangeMin Accepted")
                $thisMinMax.Min = $true
            }
            else {
                $thisMinMax.Min = $false
                Write-Verbose ("[" + $Command.$Key + " !>= " + $Book.Range.Min + "]: RangeMin NOT Accepted")
            }
            Write-Verbose ("[" + $Book.Return.Value + "]: Instruction type validated")
            return $thisMinMax
        }

        Function private:ValidateInstructionStack{
            param($Command)
            $CommandCopy = @{}
            foreach ($Key in $Command.Keys)
            {
                Write-Verbose ("[" + $Key + ":" + $Command.$Key + "]: Instruction Validation")
                #get instruction book from library
                $Book = $null
                
                $Book = ($Library | ?{$_.Instruction -eq $Key.ToUpper()})
                if (!$Book) {
                    Write-Verbose ("[" + $Key + ":" + $Command.$Key + "]: Instruction is Unknown")
                    #throw the book?
                    Write-Warning ("[" + $Key + ":" + $Command.$Key + "]: Instruction is Unknown")
                }
                else {
                    Write-Verbose ("[" + $Key + ":" + $Command.$Key + "]: Instruction is Known")
                    Write-Verbose ("[" + $Key + ":" + $Command.$Key + "]: " + $Book.Name)

                    #region valdating command/query
                    if (($Command.$Key.Length -eq "0") -or ($Command.$Key -eq "?")) {
                        #if data is empty or query, turn it into a query or assert as a query
                        Write-Verbose ("[" + $Key + ":" + $Command.$Key + "]: Null Instruction Data: Asserting to Query")
                        $CommandCopy.Add(($Key),"?")
                    }
                    else {
                        Write-Verbose ("[" + $Key + ":" + $Command.$Key + "]: Validating Instruction DataType")
                        #validation code using the a page from the book aka return object parameters
                        #don't want to turn up the BMS to 11 accidently. is there a knob that goes that high?
                        if (($Book.ReadOnly -eq $true) -and ($Command.$Key -ne "?")) {
                            #respect readonly instruction flag definition. Discard any instruction data that is included.
                            #in a more strict implementation, this instruction should probably just be discarded.
                            Write-Warning ("[" + $Key + ":" + $Command.$Key + "]: Expected Query with ReadOnly Instruction")
                            Write-Warning ("[" + $Key + ":" + $Command.$Key + "]: Disallowed Instruction Data: Setting to Query")
                            $CommandCopy.Add(($Key),"?")
                        }
                        else {
                            #region verify instruction is of the correct value type (float, int, signed_float, etc)
                            #verify instruction is within the range of correct value for type.

                            #initialize flag object to tag verification
                            $thisMinMax = @{"Min"=$false;"Max"=$false}
                            $thisTypeValid = $false
                            switch ($Book.Return.Value) {
                                "float" {
                                    if ($Command.$Key -as [float]) {
                                        Write-Verbose ("[" + $Command.$Key + "]: Value Is float")
                                        $thisTypeValid = $true
                                        $thisMinMax = MinMaxValidate -instructionValue $Command.$Key -Book $Book
                                    }
                                    else {
                                        Write-Verbose ("[" + $Command.$Key + "]: Value Is NOT float")
                                    }
                                }
                                "int" {
                                    if ($Command.$Key -as [int]) {
                                        Write-Verbose ("[" + $Command.$Key + "]: Value Is int")
                                        $thisTypeValid = $true
                                        $thisMinMax = MinMaxValidate -instructionValue $Command.$Key -Book $Book
                                    }
                                    else {
                                        Write-Verbose ("[" + $Command.$Key + "]: Value Is NOT int")
                                    }
                                }
                                "null" {
                                    if ($Command.$Key -as [char]) {
                                        Write-Verbose ("[" + $Command.$Key + "]: Value Is char")
                                        $thisTypeValid = $true
                                        $thisMinMax = MinMaxValidate -instructionValue $Command.$Key -Book $Book
                                    }
                                    else {
                                        Write-Verbose ("[" + $Command.$Key + "]: Value Is NOT char")
                                    }
                                }
                                "array" {
                                    if ($Command.$Key -as [char]) {
                                        Write-Verbose ("[" + $Command.$Key + "]: Value Is char")
                                        $thisTypeValid = $true
                                        #array types are always read only, so min and max don't actually do anything. set to true.
                                        $thisMinMax.Max = $true
                                        $thisMinMax.Min = $true
                                    }
                                    else {
                                        Write-Verbose ("[" + $Command.$Key + "]: Value Is NOT char")
                                    }
                                }
                                "signed_float" {
                                    if ($Command.$Key -as [float]) {
                                        Write-Verbose ("[" + $Command.$Key + "]: Value Is signed_float")
                                        $thisTypeValid = $true
                                        $thisMinMax = MinMaxValidate -instructionValue $Command.$Key -Book $Book
                                    }
                                    else {
                                        Write-Verbose ("[" + $Command.$Key + "]: Value Is NOT signed_float")
                                    }
                                }
                                "unsigned_char" {
                                    if ($Command.$Key -as [char]) {
                                        Write-Verbose ("[" + $Command.$Key + "]: Value Is unsigned_char")
                                        $thisTypeValid = $true
                                        $thisMinMax = MinMaxValidate -instructionValue $Command.$Key -Book $Book
                                    }
                                    else {
                                        Write-Verbose ("[" + $Command.$Key + "]: Value Is NOT unsigned_char")
                                    }
                                }
                                Default {
                                    Write-Verbose ("[" + $Book.Return.Value + "]: No handler for this value type")
                                    Write-Error ("[" + $Book.Return.Value + "]: No handler for this value type. Verify Dictionary data.")
                                    $thisTypeValid = $false
                                    $thisMinMax.Max = $false
                                    $thisMinMax.Min = $false
                                }
                            }
                            if (($thisMinMax.Max -eq $true) -and ($thisMinMax.Min -eq $true) -and ($thisTypeValid -eq $true)) {
                                Write-Verbose ("[" + $Key + "]: Added to validated instruction stack")
                                $CommandCopy.Add(($Key),($Command.$Key))
                            }
                            else {
                                Write-Verbose ("[" + $Key + "]: NOT Added to validated instruction stack")
                            }
                            
                        }
    
                    }
                }
            }
            $CommandCopy
        }
    }
    #end of begin region

    #process region
    process {
        $InstructionStack = private:ValidateInstructionStack $Command
    }
    #end of process region

    #begin of end region
    end {
        return $InstructionStack
    }
    #end of end region. The End.
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
                $iO = New-BMSInstructionObject $instruction
            }
            catch {
                Throw ("Instruction " + $instruction + " is invalid. Check JSON library for errors.")
            }
        }
        Write-Verbose "Using Instruction:"
        Write-Verbose ($iO | ft | out-string)
        #region enumerate instructions
        #assemble header
        #message is the entire message to be sent, including Start, End, checksums, etc.
        #instruction is just the instrction portion of the message.
        
        #instance two arrays, one for message, and one for the instruction only.
        $hexdata = New-Object System.Collections.Generic.List[System.Object]
        $instruction = New-Object System.Collections.Generic.List[System.Object]

        #assemble the header, add to message.
        
        $hexdata.Add($config.Message.Components.STX.ToLower())
        $hexdata.Add($config.Message.Components.DST.ToLower())
        $hexdata.Add($config.Message.Components.SND.ToLower())
        Write-Verbose ("Header (STX)(DST)(SND) assembled: " + $hexdata )

        #assemble the instruction subarray
        $iO.Instruction.ToCharArray() | %{"{0:x}" -f [int16]$_} | %{$instruction.Add($_)}
        
        if ($value) {
            #zzz TODO: construct a "WRITE" message. For now, let's just concentrate on read only messages ;)
            #parse instruction set to package value being set here
            $Query = $false
            Write-Warning "Not Implemented. (yet!)"
            break
        }
        else
        {
            #no $value defined, so this will be a read only query.
            #add configured query value to subarray. It's default is am ASCII ? (0x3F)
            $instruction.Add($config.message.components.QRY.ToLower())
            $query = $true
            Write-Verbose ("Instruction is Query (?): " + $config.message.components.QRY.ToLower())
        }

        #count length of instruction bytes in payload, add to message.
        $hexdata.Add("{0:x2}" -f [int16]$instruction.count)
        Write-Verbose ("Instruction bytecount added: " + ("{0:x2}" -f [int16]$instruction.count))
        $instruction | %{$hexdata.Add($_)}
        Write-Verbose ("Instruction Assembled: " + $instruction)

        #compute/add CRC
        #CRC-16 is calculated [in these bytes] <STX>[<DST><SND><LEN><MSG>[<QRY>]]<CRC><CRC><ETX>
        $crc = (Get-CRC16 ($hexdata[1..($hexdata.count)] -Join "")) -replace '..', "$& " -split " "
        Write-Verbose ("CRC caclulated: " + $crc)
        #add First byte of CRC
        $hexdata.Add($crc[0])
        
        #add second byte of CRC
        $hexdata.Add($crc[1])
        
        #add end transmission
        $hexdata.Add($config.Message.Components.ETX.ToLower())  
        Write-Verbose ("Footer assembled (ETX): " + $config.Message.Components.ETX.ToLower())

        Write-Verbose "Assembly complete"
        #return the message as a hash array
        #next better version of this should be to define a custom class for this.
        $HexDataInspection = ((Convert-HexToByteArray -HexString ($hexdata -join "") | %{[char][int16]$_}) -join "") | Format-Hex
        $iO | Add-Member -Name "HexDataSend" -Type NoteProperty -Value (@{"RawStream"=$hexdata;"InspectedStream"=$HexDataInspection;"ParsedStream"=(Sort-MessageStream $hexdata)})
        return $iO
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

    }

    process {
        #Define a watch dog object to use in serial communication timeouts.
        $WatchDog = New-Object -TypeName System.Diagnostics.Stopwatch
        #convert the hex string to a byte array.
        $SendBytes = Convert-HexToByteArray ($iO.HexDataSend.RawStream -join "")
        #load configuration metadata for comm session
        $config = Get-BMSConfigMeta
        #define array for return data stream
        
        #enumerate the configurable list from the metadata
        #the items in the metadata exactly match properties for a System.IO.Ports.SerialPort object
        $SerialConfigurables = $config.client.psobject.properties.name
        #create a new serial port object.
        $Port = new-Object System.IO.Ports.SerialPort

        #set properties in the serial port.
        try {
            ForEach ($item in $SerialConfigurables) {
                $port.$item = $config.Client.$item
            }
        }
        catch {
            Throw "Couldn't set a System.IO.Ports.SerialPort configurable from configuration metadata"
        }
        
        
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
        Start-Sleep -m $config.Session.SessionThrottle
        
        #create a new pscustomobject array to store multiparts of stream
        $MultiPartObject = New-Object PSCustomObject
        
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
        
        #initalize total number of message parts expected as defined in library
        switch ($iO.Handler) {
            Range  {
                $partCount = 1
            }
            String {
                $partCount = 1
            }
            Array  {
                $partCount = ($iO.Return.Value.Array.Part | Sort-Object -unique).Count
            }
            Default {
                $partCount = $null
            }
        }
        Write-Verbose ("Serial Session Handler: [" + $iO.Handler  + "] Parts: ["+ $partCount + "]")

        #initalize message part index
        $IndexMessagePart = 1
        
        #initialize empty array to store all bytes
        $Stream = New-Object System.Collections.Generic.List[System.Object]

        if ($iO.Handler -match "Array")
        {
            Write-Verbose ("Expecting $partCount parts in bytestream")
        }

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


                if ($IndexMessagePart -gt $partCount)
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
                    $iO | Add-Member -Name "HexDataReceive" -Type NoteProperty -Value (@{"RawStream"=$Stream;"InspectedStream"=$HexDataInspection;"ParsedStream"=(Sort-MessageStream $Stream)})
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
                $io | Add-Member -Name "HexDataReceive" -Type NoteProperty -Value (@{"RawStream"=$Stream;"InspectedStream"=$HexDataInspection;"ParsedStream"=(Sort-MessageStream $Stream)})
                Verify-MessageCRC $iO | out-null
                return $iO
                #this error is a failure and can cause dependent calls to fall on their face
                #if (unlikely) any good data comes out, crc check will provide some validation
            }
        } until ($WatchDog.ElapsedMilliseconds -ge $config.Session.SessionTimeout)

        #this exit condition is one where watchdog caught the hard timeout.
        #clean up the port and report our findings.
        Write-Warning ("Serial timeout occured. Hard stop at " + $config.Session.SessionTimeout + " milliseconds")
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
        $iO | Add-Member -Name "HexDataReceive" -Type NoteProperty -Value (@{"RawStream"=$Stream;"InspectedStream"=$HexDataInspection;"ParsedStream"=(Sort-MessageStream $Stream)})
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
        $iO = Invoke-BMSCommunication -iO (New-BMSMessage -Instruction $Instruction)
        
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
        $ComputablePayloadLength = ([convert]::toint16($iO.HexDataReceive.ParsedStream[$i][3],16) + 3)
        $CRCTask = ($iO.HexDataReceive.ParsedStream[$i][1..$ComputablePayloadLength]) -join ""
        $OldCRC = ($iO.HexDataReceive.ParsedStream[$i][($ComputablePayloadLength +1)..($ComputablePayloadLength +2)]) -join ""
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
    while (($i + 1) -le $iO.HexDataReceive.ParsedStream.Count)

    $iO.HexDataReceive.Add("CRCStream",$CRCStream)
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
