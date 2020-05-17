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

Function Get-RECBMSInstructionList
{
    $object = [xml](gc .\instructionset.xml)
    $object.Library.command | Select-Object -Property Instruction,Name,Category
}


Function Priv-GetRECBMSConfig
{
    [xml](gc .\config.xml)
}

Function Priv-Get-RECBMSInstruction
{param([Parameter(Mandatory=$true)]$instruction)
    $object = [xml](gc .\instructionset.xml)
    $instructionObject = $object.Library.Command | ?{$_.Instruction -match $instruction}
    #small fix for butthole character *
    if ($instructionObject.Instruction -eq "_IDN")
    {$instructionObject.Instruction = "*IDN"}
    $instructionObject
}

Function Priv-New-RECBMSMessage
{param([Parameter(Mandatory=$true)]$instruction,$value)
    $config = Priv-RECBMSGetConfig
    $iO = Priv-Get-RECBMSInstruction $instruction
    if ($iO)
        {
                #region enumerate instructions
            $STX = [int16]$config.Constructor.Message.Components.STX
            $DST = [int16]$config.Constructor.Message.Components.DST
            $SND = [int16]$config.Constructor.Message.Components.SND
            $LEN = [int16]$config.Constructor.Message.Components.LEN
            $MSG = [int16]$config.Constructor.Message.Components.DST
            $DST = [int16]$config.Constructor.Message.Components.DST

                #zzz TODO: construct a "WRITE" message. For now, let's just concentrate on read only messages below ;)
                #parse instruction set to package value being set here
                #
                Write-Warning "Not Implemented. (yet!)"
            }
            else
            {
                $iO.Instruction
            }
        }
        else {
            Write-Error ("Instruction " + $instruction + " not found.")
        }
    
}

