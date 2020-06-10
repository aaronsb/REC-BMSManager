Function Send-BMSMessage {
    [cmdletbinding()]
    Param($iO)
        begin {
            #trap errors, but try and close port always
            trap {
                Write-Error $error[0]
                $port.BaseStream.Dispose()
                break
            }

            #REGION private function definitions

            function Close-SerialPort {
                [cmdletbinding()]
                param()
                #Write-Progress -id 30 -Activity '[Serial]:[Close]' -Status "Closing Port"
                Write-Verbose ("[Serial]: Closing Port " + $port.PortName)
                #dispose of port properly (I imagine dropping a piece of soggy cardboard into a wastebasket...plop)
                $port.BaseStream.Dispose()
                #dispose of port
                Remove-Variable port -Scope Global
            }

            function Open-SerialPort {
                [cmdletbinding()]
                param()
                #Write-Progress -id 30 -Activity '[Serial]:[Init]' -Status "Initialising Port"
                #using System.IO.Ports.SerialPort.BaseStream method
                #https://www.sparxeng.com/blog/software/must-use-net-system-io-ports-serialport
                if (!$global:Port) {
                    #create a new serial port object.
                    Write-Verbose ("[Serial]: Created serial object")
                    $global:Port = new-Object System.IO.Ports.SerialPort
                }
                else {
                    Write-Verbose ("[Serial]: Existing serial port instance found. Resetting")
                    $port.BaseStream.Dispose()
                    Write-Verbose ("[Serial]: Waiting " + $BMSInstructionSet.Config.Session.SessionTimeout + " milliseconds for port restart")
                    Start-Sleep -Milliseconds $BMSInstructionSet.Config.Session.SessionTimeout
                    Remove-Variable port -Scope Global
                    $global:Port = new-Object System.IO.Ports.SerialPort
                }

                #REGION Serial Setup
        
                #Set up serial port parameters.
                #the items in the metadata exactly match properties for a System.IO.Ports.SerialPort object
                $SerialConfigurables = $BMSInstructionSet.Config.Client.PSObject.Properties.Name
                
                #REGION serial setup 
                try {
                        ForEach ($item in $SerialConfigurables) {
                        $port.$item = $BMSInstructionSet.Config.Client.$item
                        Write-Verbose ("[Serial]: " + $item + " : " + $port.$item)
                        }
                    }
                    catch {
                        Throw "Couldn't set a System.IO.Ports.SerialPort configurable from configuration metadata"
                    }
                #ENDREGION serial setup
                #Write-Progress -id 30 -Activity '[Serial]:[Open]' -Status "Opening Port"
                $r = 1
                do {
                    
                    #open the port this session
                    try {
                        if (!$port.IsOpen) {
                            #Write-Progress -id 30 -Activity '[Serial]:[Open]' -Status "Retry Port Open" -PercentComplete (($r / $BMSInstructionSet.Config.Session.Retries) * 100)
                            #Lazyish open of port
                            Write-Verbose ("[Serial]: Serial IsClosed(). Attempting to open.")
                            Start-Sleep -Milliseconds ($BMSInstructionSet.Config.Session.SessionTimeout * $r)
                            $port.Open()
                        }

                        if ($port.IsOpen) {
                            Write-Verbose ("[Serial]: Waited [$r] tries to open serial port")
                            #remove existind data on port if any
                            $port.BaseStream.Flush() | Out-Null
                            break
                        }
                    }
                    catch
                    {
                        Write-Error $Error[0]
                        $port.Close()
                        write-warning "[Serial]: Couldn't open port, Retrying: $r"
                        write-Verbose ($port | Format-Table | Out-String)
                        $r++
                    }
                    
                } until ($r -gt $BMSInstructionSet.Config.Session.Retries)
                
                if (!$port.IsOpen) {
                    $ErrorString = ("Couldn't open serial port. Retried " + $r + " times.")
                    Throw $ErrorString
                }
            }

            Function Send-SerialBytes {
                [cmdletbinding()]
                param($iOInstance)

                #internalize sendbytes
                $SendBytes = $iOInstance.ByteStreamSend.RawStream
                
                #Write the message on the line. Bon Voyage!
                Write-Verbose ("[SendByte]: [" + $SendBytes.count + "] bytes on [" + $port.PortName + "]")
                try {
                    #using System.IO.Ports.SerialPort.BaseStream method
                    #https://www.sparxeng.com/blog/software/must-use-net-system-io-ports-serialport
                    $port.BaseStream.Write([byte[]] $SendBytes, 0, ($SendBytes.count))
                    Write-Verbose "[SendByte]: Sucessful TX of instruction"
                }
                catch {
                    #catch the rest of the errors related to opening serial ports.
                    Throw "Couldn't send bytes on serial port"
                }
            }

            Function Read-SerialBytes {
                [cmdletbinding()]
                # $baz = Send-BMSMessage (Build-BMSMessage (Assert-BMSMessage -Command rint -verbose) -Verbose) -verbose
                #initalize message part index
                $WatchDog = New-Object -TypeName System.Diagnostics.Stopwatch
                $IndexMessagePart = 1

                #message part ordered keypair array container



                #receieved bms messages have up to two parts returned per instruction sent
                #this is a hard typed handler that only collects up to two parts
                #there's probably some trickery to make this continuously window byte arrays into collections
                #but I just don't really need it
                #initalize byte index

                $BufferSize = 512
                $Stream = [System.Byte[]]::new($BufferSize)
                $Indexes = [ordered]@{}
                $StreamComplete = $false
                $i = 0
                $byteSTX = [system.convert]::ToByte($BMSInstructionSet.Config.Message.Components.STX,16)
                $byteETX = [system.convert]::ToByte($BMSInstructionSet.Config.Message.Components.ETX,16)
                Write-Verbose ("--------------------------------------------------------------")
                Write-Verbose ("|Mesg type|Pointer ID| Descriptor|    (Conditionally) Data   |")
                Write-Verbose ("--------------------------------------------------------------")
                $WatchDog.Start()
                do {
                    #clear last data value before attempting another read
                    $Byte = $null

                    if ($StreamComplete -eq $false) {
                        #cast these bytes to hex, which makes it easy to test for difference between 
                        #null byte and a zero byte
                        #I had significant issues with this until I started using BaseStream method
                        #using System.IO.Ports.SerialPort.BaseStream method
                        #https://www.sparxeng.com/blog/software/must-use-net-system-io-ports-serialport
                        $Byte = $port.BaseStream.ReadByte()
                        
                        $Stream[$i] = $Byte
                        Write-Verbose ("[ReadByte]: Index: [" + $i + "]: Data:[" + ("{0:x2}" -f $Byte) + "]")
                    

                        #Write-Verbose ("[" + $i + "]: Null header byte found during port readbyte")
                        
                    }
                    else {
                        Write-Verbose "StreamComplete indicates true. Exiting serial read loop."
                        #return out of do loop because stream is complete
                        break
                    }

                


                    # behold my IF-THEN state machine. :)

                    #REGION: First message start (STX) pointer logic
                    if (($Stream[$i] -eq $byteSTX) -and ($i -le 1)) {
                        Write-Verbose ("[CtrlByte]: Index: [" + $i + "]: <STX> Start Message Received")
                        #first byte of the stream. only occurs once.
                        #crossing this event with index 0 ensures we don't get a false start positive in the stream later.
                        $firstIndexSTX = $i
                        $firstIndexLEN = $i + 3
                    }

                    #REGION: first message length byte read logic
                    if ($i -eq $firstIndexLEN) {
                        #time to calculate total bytes of this message
                        #7 bytes added to message length:
                        # 4 <STX><DST><SND><LEN> for message header
                        # 3 <CRC><CRC><ETX> for footer
                        $firstIndexMessageLength = (([int][byte]$Stream[$firstIndexLEN]) + 7)
                        #message length, added to firststx (0) minus 1 to index $i from zero
                        #the point of this exercise is to maybe get to a point of understanding how this works
                        #so I can make an unlimited parser instead of a two message parser
                        $firstIndexETX = (($firstIndexMessageLength + $firstIndexSTX) -1)
                        Write-Verbose ("[CtrlByte]: Index: [" + $i + "]: <LEN> (" + $firstIndexMessageLength + ") Received")
                    }

                    #REGION: end of first transmission logic
                    if ($i -eq $firstIndexETX) {
                        Write-Verbose ("[MesgFlow]: Index: [" + $i + "]: <ETX> End Message part 1")
                        #this should be the end of the first message part, since stream index equals byte count of (message + padding)
                    
                        if ($Stream[$i] -ne $byteETX) {
                            #expected end of stream, got something else
                            #something has gone wrong, break out
                            Write-Warning "Expected end of message byte 0xaa. Malformed message."
                            break
                        }
                        
                        if ($IndexMessagePart -eq ($iOInstance.HandlerCount)) {
                            #at end of message stream, if no more messages are expected,
                            #bail from loop
                            Write-Verbose ("[EXIT] No more message parts expected: MessageIndex: " + $IndexMessagePart)
                            Write-Verbose "[EXIT] Returning serial port collection loop"
                            $Indexes.Add($IndexMessagePart,@{"STX"=$firstIndexSTX;"ETX"=$firstIndexETX})
                            $StreamComplete = $true
                            break
                        }

                        if (($iOInstance.HandlerCount) -gt $IndexMessagePart) {
                            #if we haven't reached the count of handles (messages) for this instruction reception
                            #increment message part so we can process the next time we fall into a sensible <ETX> condition
                            #store indexes for first message part
                            $Indexes.Add($IndexMessagePart,@{"STX"=$firstIndexSTX;"ETX"=$firstIndexETX})
                            $IndexMessagePart++
                        }
                    }

                    #REGION End of first message, but now there's a second
                    if (($Stream[$i] -eq $byteSTX) -and ($Stream[$i -1] -eq $byteETX)) {
                        Write-Verbose ("[MesgFlow]: Index: [" + $i + "]: Next message continues")
                        Write-Verbose ("[CtrlByte]: Index: [" + $i + "]: <STX> received: Data: [" + ("{0:x2}" -f $Stream[$i]) + "]")
                        # clearly, this is the start of the second message
                        # index of (first <ETX> byte + 1) is the <STX> of second message.
                        # save index of of second <STX>
                        $secondIndexSTX = $i
                        # predict index of second message length in stream 
                        $secondIndexLEN = $i + 3
                    }

                    #REGION second message length read logic
                    if ($i -eq $secondIndexLEN) {
                        #time to calculate total bytes of this message
                        #7 bytes added to message length:
                        # 4 <STX><DST><SND><LEN> for message header
                        # 3 <CRC><CRC><ETX> for footer
                        $secondIndexMessageLength = ([int]$Stream[$secondIndexLEN] + 7)
                        #message length, added to firststx (0) minus 1 to index $i from zero
                        #the point of this exercise is to maybe get to a point of understanding how this works
                        #so I can make an unlimited parser instead of an only two message parser
                        $secondIndexETX = (($secondIndexMessageLength + $secondIndexSTX) -1)
                        Write-Verbose ("[MesgFlow]: Index: [" + $i + "]: Next message continues")
                        Write-Verbose ("[CtrlByte]: Index: [" + $i + "]: <LEN> (" + $secondIndexMessageLength + ") Received")
                    }

                    #REGION end of second message part and related logic
                    if (($i -eq $secondIndexETX) -and ($Stream[$i] -eq $byteETX)) {
                        $secondIndexETX = $i
                        Write-Verbose ("[MesgFlow]: Index: [" + $i + "] <ETX> [Message part 2]")
                        #this should be the end of the second message part, since stream index equals byte count of (message + padding)
                        if ($Stream[$i] -ne $byteETX) {
                            #expected end of stream, got something else
                            #something has gone wrong, break out
                            Write-Warning "[ERROR] Expected end of message byte 0xaa. Malformed message."
                            break
                        }
                        #at end of message stream, if no more messages are expected,
                        #bail from loop
                        Write-Verbose "[EXIT] No more message parts expected."
                        Write-Verbose "[EXIT] Returning serial port collection loop"
                        $Indexes.Add($IndexMessagePart,@{"STX"=$secondIndexSTX;"ETX"=$secondIndexETX})
                        $StreamComplete = $true
                        break

                        if (($iOInstance.HandlerCount) -gt $IndexMessagePart) {
                            #if we haven't reached the count of handles (messages) for this instruction reception
                            #throw a fit because something has gone wrong - only two messages in a stream are allowed
                            Throw "REC BMS messages only contain up to two messages in return stream."
                        }
                    }
                    $i++
                } until ($WatchDog.ElapsedMilliseconds -ge $BMSInstructionSet.Config.Session.SessionTimeout)
                #REGION close up shop and emit data
                $WatchDog.Stop()
                $ParsedStream = [ordered]@{}
                $ParsedStream.Add("0",$Stream[$firstIndexSTX..$firstIndexETX])
                #add next part if there's more than one
                if ($IndexMessagePart -gt 1) {
                    $ParsedStream.Add("1",$Stream[$secondIndexSTX..$secondIndexETX])
                }
                
                return @{"RawStream"=$Stream[$firstIndexSTX..$secondIndexETX];"ParsedStream"=$ParsedStream}
            }
            #ENDREGION private function definitions


            #REGION timer setup
            #Define a timer to see how long things take
            $Timer = New-Object -TypeName System.Diagnostics.Stopwatch
            #ENDREGION timer setup
            

        }
    
        process {
            
            #REGION Main loop

            #Open the serial port
            
            #openserialport has it's own progress bars on id 30
            Open-SerialPort

            #zzz TODO add a loop to process multiple message send events
            $ProgressStepNumber = 1
            foreach ($iOInstance in $iO) {
                #Write-Progress -id 20 -Activity '[Serial]' -Status "Processing Instructions" -PercentComplete (($ProgressStepNumber / $iO.Count) * 100)
                #start the timer for transmit event.
                $Timer.Start()
                #port should stay open for immediate receieve

                #Write-Progress -id 40 -Activity '[Serial]:[Send]' -Status ("Sending Instruction: [" + $iOInstance.Command + "]")
                Send-SerialBytes $iOInstance

                #stop the timer for transmit event.
                $Timer.Stop()
                Write-Verbose ("[Serial]: TX milliseconds: " + $WatchDog.ElapsedMilliseconds)
                #reset the timer for the next event.
                $Timer.Reset()
        
                #Wait a specified number of milliseconds.
                Write-Verbose ("[Serial]: Sleeping " + $BMSInstructionSet.Config.Session.SessionThrottle + " milliseconds")
                Start-Sleep -m $BMSInstructionSet.Config.Session.SessionThrottle

                #start the timer for the receieve event.
                $Timer.Start()

                #Call read serial bytes
                #Write-Progress -id 40 -Activity '[Serial]:[Receive]' -Status ("Getting Response: [" + $iOInstance.Command + "]")
                $StreamObject = Read-SerialBytes
                #return the message as a hash array
                #next better version of this should be to define a custom class for this.
                $iOInstance | Add-Member -Name "ByteStreamReceive" -Type NoteProperty -Value (@{
                    "RawStream" = $StreamObject.RawStream;
                    "InspectedStream" = ($StreamObject.RawStream | Format-Hex -Encoding ascii);
                    "ParsedStream" = $StreamObject.ParsedStream})

                
                $Timer.Stop()
                Write-Verbose ("[Serial]: RX milliseconds: " + $WatchDog.ElapsedMilliseconds)
                Write-Verbose ("[Serial]: Received [" + $StreamObject.RawStream.count + "] bytes on port [" + $port.PortName +"]")
                $Timer.Reset()
                
                Write-Verbose "[Serial]: Returning stream"


                #this error is a failure and can cause dependent calls to fall on their face
                #if (unlikely) any good data comes out, crc check will provide some validation
                Test-MessageCRC $iOInstance | Out-Null
                #increment step number for progressbar
                $ProgressStepNumber++
            }
            
        }

        end {
            Close-SerialPort
            return $iO
        }
        
    }