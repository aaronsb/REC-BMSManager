Function Send-BMSMessage {
    [cmdletbinding()]
    Param($iO)
        begin {
            #trap all errors.
            trap {
            Write-Error $error[0]
            $port.Close()
            break
            }

            function Open-SerialPort {
                $r = 0
                do {
                    #open the port this session
                    try {
                        $port.Open()
                        if ($port.IsOpen) {
                            Write-Verbose ("Waited [$r] tries to open serial port")
                            break
                        }
                        
                    }
                    catch
                    {
                        write-warning "Couldn't open port, Retrying: $r"
                        $r++
                    }
                    Start-Sleep -Milliseconds $BMSInstructionSet.Config.Session.SessionTimeout
                } until ($r -gt $BMSInstructionSet.Config.Session.Retries)
                
                if (!$port.IsOpen) {
                    Throw "Couldn't open serial port. Retried $r times."
                }
            }

            Function Send-SerialBytes {
                param($SendBytes)
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
                    Throw "Couldn't send bytes on serial port"
                    break
                }
            }
            #Define a watch dog object to use in serial communication timeouts.
            $WatchDog = New-Object -TypeName System.Diagnostics.Stopwatch
            #convert the hex string to a byte array.
            $SendBytes = Convert-HexToByteArray ($iO.HexStreamSend.RawStream -join "")

            #define array for return data stream
            
            #enumerate the configurable list from the metadata
            #the items in the metadata exactly match properties for a System.IO.Ports.SerialPort object
            $SerialConfigurables = $BMSInstructionSet.Config.Client.PSObject.Properties.Name
            #create a new serial port object.
            $global:Port = new-Object System.IO.Ports.SerialPort
    
            #set properties in the serial port.
            try {
                    ForEach ($item in $SerialConfigurables) {
                    $port.$item = $BMSInstructionSet.Config.Client.$item
                    Write-Verbose ("[Serial]: " + $item + " : " + $port.$item)
                    }
                }
                catch {
                    Throw "Couldn't set a System.IO.Ports.SerialPort configurable from configuration metadata"
                }
        }
    
        process {
            
            
            
            
            Open-SerialPort

            #start the timer for transmit event.
            $WatchDog.Start()

            #port should stay open for immediate receieve
            Send-SerialBytes $SendBytes
            #stop the timer for transmit event.
            $WatchDog.Stop()
            Write-Verbose ("Serial TX milliseconds: " + $WatchDog.ElapsedMilliseconds)
            #reset the timer for the next event.
            $WatchDog.Reset()
    
            #Wait a specified number of milliseconds. 
            Start-Sleep -m $BMSInstructionSet.Config.Session.SessionThrottle
            
            #create a new pscustomobject array to store multiparts of stream
            $MultiPartObject = New-Object PSCustomObject
            
            #Number of expected message parts to be returned.
            #Usually arrays are 2 parts, informational then the data.
            #everything else is 1 part

    
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
    
            Write-Verbose ("Expecting " + $iO.HandlerCount + " parts in bytestream")
    
    
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
    
    
                    if ($IndexMessagePart -gt $iO.HandlerCount)
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
                    write-warning $port.IsOpen
                    #read a byte, format it as two position payload. If it reads a 4 position payload, something has gone wrong
                    #with the serial port setup.
                    if (!$port.IsOpen) {
                        Write-Warning "The serial port is unexpectedly closed"
                        try {
                            Write-Warning "Turning the port off and on again (TM)"
                            $port.Close()
                            Open-SerialPort
                        }
                        catch {
                            throw "The serial port was unexpectedly closed"
                        }
                    }
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
                    
                    #verify crc of messsage parts. Error is asserted if crc mismatch found, but object is still returned (for diagnostics? I guess...)
                    Verify-MessageCRC $iO | out-null
                    return $iO
                    #this error is a failure and can cause dependent calls to fall on their face
                    #if (unlikely) any good data comes out, crc check will provide some validation
                }
            } until ($WatchDog.ElapsedMilliseconds -ge $BMSInstructionSet.Config.Session.SessionTimeout)
    
            #this exit condition is one where watchdog caught the hard timeout.
            #clean up the port and report our findings.
            Write-Warning ("Serial timeout occured. Hard stop at " + $BMSInstructionSet.Config.Session.SessionTimeout + " milliseconds")
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

        end {
            $port.Close()
        }
        
    }