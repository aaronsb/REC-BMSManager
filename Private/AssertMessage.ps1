Function Assert-BMSMessage {
    [CmdletBinding(DefaultParameterSetName='Command')]
    param (
        [Parameter(ValueFromPipeline)]
        [Parameter(Mandatory = $true, ParameterSetName = 'Command')]$Command
    )

    begin {
        $Command = Invoke-CmdPreprocessor $Command
        
        #instance an ordered array to contain packaged instruction(s)
        $InstructionStack = New-Object System.Collections.Generic.List[System.Object]

        #instance the library
        $Library = $BMSInstructionSet.Command

        #define a private validation function

        Function MinMaxValidate{
            param($instructionValue, $Book)
            if ([double]$Command.$Key -ge [double]$Book.Range.Min) {
                if ([double]$Command.$Key -le [double]$Book.Range.Max) {
                    Write-Verbose ("[MsgAssert]: [" + $Command.$Key + " <= " + $Book.Range.Max + "]: RangeMax Accepted")
                    $thisMinMax.Max = $true
                }
                else {
                    $thisMinMax.Max = $false
                    Write-Verbose ("[MsgAssert]: [" + $Command.$Key + " !<= " + $Book.Range.Max + "]: RangeMax NOT Accepted")
                }
                Write-Verbose ("[MsgAssert]: [" + $Command.$Key + " >= " + $Book.Range.Min + "]: RangeMin Accepted")
                $thisMinMax.Min = $true
            }
            else {
                $thisMinMax.Min = $false
                Write-Verbose ("[MsgAssert]: [" + $Command.$Key + " !>= " + $Book.Range.Min + "]: RangeMin NOT Accepted")
            }
            Write-Verbose ("[MsgAssert]: [" + $Book.Return.Value + "]: Instruction type validated")
            return $thisMinMax
        }

        #validates instructions and formats the values (if any) to the correct format defined in the library, then returns an array of pscustomobjects
        Function ValidateInstructionStack {
            param($Command)
            $CommandCopy = @()
            foreach ($Key in $Command.Keys) {
                #get instruction book from library
                $Book = $null
                #clear the previous hex encoding
                $HexEncoded = $null
                #Clear previous handler count
                $HandlerCount = 0

                $Book = ($Library | ?{$_.Instruction -eq $Key.ToUpper()})
                if (!$Book) {
                    Write-Verbose ("[MsgAssert]: [" + $Key + ":" + $Command.$Key + "]: Instruction is Unknown")
                    #throw the book?
                    Write-Warning ("[MsgAssert]: [" + $Key + ":" + $Command.$Key + "]: Instruction is Unknown")
                    return
                }
                else {
                    Write-Verbose ("[MsgAssert]: [" + $Key + ":" + $Command.$Key + "]: Instruction Validation Success")
                }
                
                Write-Verbose ("[MsgAssert]: [" + $Key + ":" + $Command.$Key + "]: Instruction is Known")
                Write-Verbose ("[MsgAssert]: [" + $Key + ":" + $Command.$Key + "]: " + $Book.Name)
                
                switch ($Book.Return.Value) {
                    Array {
                        $HandlerCount = $HandlerCount + ($Book.Return.Unit.Array.Part | Sort-Object -Unique).Count
                    }
                    IntArray {
                        $HandlerCount = $HandlerCount + ($Book.Return.Unit.Array.Part | Sort-Object -Unique).Count
                    }
                    Default {
                        $HandlerCount = $HandlerCount + $Book.Return.Unit.Count
                    }
                }
                
                #region valdating command/query
                if (($Command.$Key.Length -eq "0") -or ($Command.$Key -eq "?")) {
                    #if data is empty or query, turn it into a query or assert as a query
                    Write-Verbose ("[MsgAssert]: [" + $Key + ":" + $Command.$Key + "]: Null Instruction Data: Asserting to Query")
                    $HexEncodedInstruction = New-Object System.Collections.Generic.List[System.Object]
                    $Key.ToUpper().ToCharArray() | %{'{0:x2}' -f [int][char]$_} | %{$HexEncodedInstruction.Add($_)}
                    [char]"?" | %{"{0:x2}" -f [int][char]$_} | %{$HexEncodedInstruction.Add($_)}
                    $CommandCopy += ,[pscustomobject]@{
                        "Hex"=$HexEncodedInstruction;
                        "Plain"=$Command.$Key;
                        "Command"=$Key.ToUpper();
                        "HandlerCount"=$HandlerCount;
                        "Instruction"=$Book
                    }
                }
                else {
                    Write-Verbose ("[MsgAssert]: [" + $Key + ":" + $Command.$Key + "]: Validating Instruction DataType")
                    #validation code using the a page from the book aka return object parameters
                    #don't want to turn up the BMS to 11 accidently. is there a knob that goes that high?
                    if (($Book.ReadOnly -eq $true) -and ($Command.$Key -ne "?")) {
                        #respect readonly instruction flag definition. Discard any instruction data that is included.
                        #in a more strict implementation, this instruction should probably just be discarded.
                        Write-Warning ("[MsgAssert]: [" + $Key + ":" + $Command.$Key + "]: Expected Query with ReadOnly Instruction")
                        Write-Warning ("[MsgAssert]: [" + $Key + ":" + $Command.$Key + "]: Disallowed Instruction Data: Setting to Query")
                        $HexEncodedInstruction = New-Object System.Collections.Generic.List[System.Object]
                        $CommandCopy += ,[pscustomobject]@{"Hex"=$HexEncodedInstruction;"Plain"=$Command.$Key;"Command"=$Key.ToUpper()}
                        $Key.ToUpper().ToCharArray() | %{'{0:x2}' -f [int][char]$_} | %{$HexEncodedInstruction.Add($_)}
                        [char]"?" | %{"{0:x2}" -f [int][char]$_} | %{$HexEncodedInstruction.Add($_)}
                    }
                    else {
                        #region verify instruction is of the correct value type (float, int, char etc)
                        #verify instruction is within the range of correct value for type.

                        #initialize flag object to tag verification
                        $thisMinMax = @{"Min"=$false;"Max"=$false}
                        $thisTypeValid = $false
                        switch ($Book.Return.Value) {
                            "float" {
                                if ($Command.$Key -is [double]) {
                                    Write-Verbose ("[MsgAssert]: [" + ("{0:N}" -f $Command.$Key) + "]: Value Is float")
                                    $thisTypeValid = $true
                                    $HexEncodedInstruction = New-Object System.Collections.Generic.List[System.Object]
                                    $thisMinMax = MinMaxValidate -instructionValue $Command.$Key -Book $Book
                                    if ($thisMinMax -eq $false) {
                                        Write-Warning "[MsgAssert]: Instruction value is out of bounds"
                                        break
                                    }
                                    else {
                                        $Key.ToUpper().ToCharArray() | %{"{0:x2}" -f [int][char]$_} | %{$HexEncodedInstruction.Add($_)}
                                        ([string]$Command.$Key).ToCharArray() | %{"{0:x2}" -f [int][char]$_} | %{$HexEncodedInstruction.Add($_)}
                                    }

                                }
                                else {
                                    Write-Verbose ("[MsgAssert]: [" + $Command.$Key + "]: Value Is NOT float")
                                }
                            }
                            "int" {
                                if (($Command.$Key -is [int]) -or ($Command.$Key -eq 0)) {
                                    Write-Verbose ("[MsgAssert]: [" + ("{0:N}" -f $Command.$Key) + "]: Value Is int")
                                    $thisTypeValid = $true
                                    $HexEncodedInstruction = New-Object System.Collections.Generic.List[System.Object]
                                    $thisMinMax = MinMaxValidate -instructionValue $Command.$Key -Book $Book
                                    if ($thisMinMax -eq $false) {
                                        Write-Warning "[MsgAssert]: Instruction value is out of bounds"
                                        break
                                    }
                                    else {
                                        $Key.ToUpper().ToCharArray() | %{"{0:x2}" -f [int][char]$_} | %{$HexEncodedInstruction.Add($_)}
                                        ([string]$Command.$Key).ToCharArray() | %{"{0:x2}" -f [int][char]$_} | %{$HexEncodedInstruction.Add($_)}
                                    }

                                }
                                else {
                                    Write-Verbose ("[MsgAssert]: [" + $Command.$Key + "]: Value Is NOT int")
                                }
                            }
                            "array" {
                                if ($Command.$Key) {
                                    Write-Verbose ("[MsgAssert]: [" + $Command.$Key + "]: Value Is an array")
                                    $thisTypeValid = $true
                                    $HexEncodedInstruction = New-Object System.Collections.Generic.List[System.Object]
                                    #array types are always read only and have a return handler elsewhere
                                    # min and max don't actually do anything. set to true.
                                    #set encoded instruction to query always
                                    $thisMinMax.Max = $true
                                    $thisMinMax.Min = $true
                                    $Key.ToUpper().ToCharArray() | %{'{0:x2}' -f [int][char]$_} | %{$HexEncodedInstruction.Add($_)}
                                    [char]"?" | %{"{0:x2}" -f [int][char]$_} | %{$HexEncodedInstruction.Add($_)}
                                }
                                else {
                                    Write-Verbose ("[MsgAssert]: [" + $Command.$Key + "]: Value Is NOT an array")
                                }
                            }
                            "char" {
                                if ($Command.$Key -is [char]) {
                                    Write-Verbose ("[MsgAssert]: [" + $Command.$Key + "]: Value Is char")
                                    $thisTypeValid = $true
                                    $HexEncodedInstruction = New-Object System.Collections.Generic.List[System.Object]
                                    $thisMinMax = MinMaxValidate -instructionValue $Command.$Key -Book $Book
                                    $Key.ToUpper().ToCharArray() | %{'{0:x2}' -f [int][char]$_} | %{$HexEncodedInstruction.Add($_)}
                                    [char]$Command.$Key | %{"{0:x2}" -f [int][char]$_} | %{$HexEncodedInstruction.Add($_)}
                                }
                                else {
                                    Write-Verbose ("[MsgAssert]: [" + $Command.$Key + "]: Value Is NOT char")
                                }
                            }
                            Default {
                                Write-Verbose ("[MsgAssert]: [" + $Book.Return.Value + "]: No handler for this value type")
                                Write-Error ("[MsgAssert]: [" + $Book.Return.Value + "]: No handler for this value type. Verify Dictionary data.")
                                $thisTypeValid = $false
                                $thisMinMax.Max = $false
                                $thisMinMax.Min = $false
                            }
                        }
                        if (($thisMinMax.Max -eq $true) -and ($thisMinMax.Min -eq $true) -and ($thisTypeValid -eq $true)) {
                            Write-Verbose ("[MsgAssert]: [" + $Key + "]: Added to validated instruction stack")
                            $CommandCopy += ,[pscustomobject]@{
                                    "Hex"=$HexEncodedInstruction;
                                    "Plain"=$Command.$Key;
                                    "Command"=$Key.ToUpper();
                                    "HandlerCount"=$HandlerCount;
                                    "Instruction"=$Book
                                }
                        }
                        else {
                            Write-Verbose ("[MsgAssert]: [" + $Key + "]: NOT Added to validated instruction stack")
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
        $InstructionStack = ValidateInstructionStack $Command
    }
    #end of process region

    #begin of end region
    end {
        return $InstructionStack
    }
    #end of end region. The End.
}