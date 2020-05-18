
. .\get-crc16.ps1
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
        $object = gc .\instructionset.json | ConvertFrom-Json
        $instructionObject = $object.Command | ?{$_.Instruction -match $instruction}
        #small fix for butthole character *
        if ($instructionObject.Instruction -eq "_IDN")
        {$instructionObject.Instruction = "*IDN"}
        $instructionObject
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
        $config = Get-BMSConfigMeta
    
    if (!$instruction)
    {
        Get-BMSInstructionList
        return
    }
    $iO = Get-BMSInstruction $instruction
    if ($iO)
        {
            if ($value) {
                #zzz TODO: construct a "WRITE" message. For now, let's just concentrate on read only messages below ;)
                #parse instruction set to package value being set here
                #
                Write-Warning "Not Implemented. (yet!)"
            }
            else
            {
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
                $instruction.Add($config.message.components.QRY.ToLower())
                
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
            }
        }
        else {
            Write-Error ("Instruction " + $instruction + " not found.")
        }
    $message -join ""
    }
    
}


Function Invoke-BMSCommunication {
    param($message)
    trap {
        Write-Error "Something died! Closing COM port."
        $port.Close()
        break
    }
    $bytes = Convert-HexToByteArray ($message -join "")
    
    $config = Get-BMSConfigMeta
    $SerialConfigurables = $config.client.psobject.properties.name
    $port = new-Object System.IO.Ports.SerialPort 
    foreach ($item in $SerialConfigurables) {
        $port.$item = $config.Client.$item
    }
    
    $port.Open()  
    $port.ReadExisting() | Out-Null #clear existing buffer

  
    # Gets the data from the com port for the specified interval 
    
    $port.Write([byte[]] $bytes, 0, ($bytes.count))
    Start-Sleep -m $config.Session.SessionThrottle

    $Retry = 0
    do {
        $Data = $null
        $Data = $port.ReadExisting()
        $Retry++
        if ($Data)
        {
            $port.Close()
            return $Data
        }
        else
        {
            Write-Warning ("No response. Retry: " + $Retry)
            Start-Sleep -m $config.Session.SessionThrottle
            $Data = $port.ReadExisting()
        }
    } until ($Retry -ge $config.Session.Retries)
    $port.Close()  
}

Function New-BMSComm
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
            (Invoke-BMSCommunication (New-BMSMessage -Instruction $Instruction))
        }
}

#$inst = ("LCD1","LCD3","CELL","PTEM","RINT","BTEM","ERRO")
#$inst | %{New-BMSMessage -Instruction $_} | %{Invoke-BMSCommunication $_}
#Invoke-BMSCommunication (New-BMSMessage -Instruction _IDN)