
Function Format-MessageObjects {
    [CmdletBinding()]
    param($iO)

    begin {
        Function Format-Value {
            [CmdletBinding()]
            param($value,$d)
        }
    }

    process {
        write-verbose $iO.Instruction.Return.Value



        #instruction-specific handler
        #there are some non-uniformities in the way instruction strings are expressed
        #switch case offers specific handling for those

        #the parent switch case is evaluated first

        switch ($iO.Command) {
            LCD3 {
                
                ForEach ($Value in ($iO.Instruction.Return.Unit.Array | Sort-Object Position)) {
                    
                }
                #this bitmapped instruction is fairly normal, except for the
                #last two bytes of LCD3 are LSB and MSB of reported amphour capacity
                #LCD3 is a variant of IntArray {} switch case seen below
                #LCD3 array is a mixed array type of int (that are actually chars) and two bytes
            }

            ERRO {
                #error handler has a lookup table, which is managed here.
                #errors of the BMS are not emitted as error objects
                #ERRO is a variant of IntArray {} switch case seen below
                #The ERRO array is a mixed type with int (as chars) and a lookup table
            }

            CHEM {
                #this is an indexed lookup of cell chemistry identifiers
                #Chemistry types are translated in this switch case
                #CHEM Is a lookup of int value (ok, it's a char but we're calling it an int)
            }

            CANF {
                #CANBUS frequency for Victron compatible BMS units. The Venus-OS device
                #must be configured to match this frquency
                #Canf is a lookup of int value  (ok, it's a char but we're calling it an int)
            }
            Default {
                switch ($iO.Instruction.Return.Value) {
                    IntArray {}
                    Array {}
                    Float {}
                    Char {}
                    String {}
                    Int {}
                    Default {}
                }
            }
        }

        <#
                switch ($iO.Instruction.Return.Value) {
            intarray {
                write-verbose "array"
                # part 0 (header)
                $h = ($iO.Instruction.Return.Unit.Array | ?{$_.Part -eq 0})
                $Header = [PSCustomObject]@{
                    "Name" = $iO.Instruction.Name;
                    "Instruction" = $iO.Instruction.Instruction
                }
                if (($iO.Instruction.Return.Unit.Array[0].Unit) -eq "UnitCount") {
                    $Header | Add-Member -MemberType NoteProperty -Name "BMSUnit" -Value $iO.BMSData.0 
                }
                write-verbose "header"
                $Header
                # part 1 (data)
                $d = ($iO.Instruction.Return.Unit.Array | ?{$_.Part -eq 1})
                if ($d.Position -eq "template") {
                    #if this is a template type, it will always be an array of cells, bms boxes, or temperature sensors
                    $i = 0
                    $values = [ordered]@{}
                    do {
                        $values.Add(([string]($i + 1)),$iO.BMSData."1"[$i])
                        $i++
                    } until ($i -eq $io.BMSData."1".Count)
                    write-verbose "template"
                    [PSCustomObject]@{$d.Description=[PSCustomObject]$values}
                }
                else {
                    $i = 0
                    $values = [ordered]@{}
                    do {
                        $values.Add($d[$i].Description,$iO.BMSData."1"[$i])
                        #$values.Add()
                        $i++
                    } until ($i -eq $io.BMSData."1".Count)
                    write-verbose "mapped"
                    $data = [PSCustomObject]@{$iO.Instruction.Name=[PSCustomObject]$values}
                    write-verbose $data
                }


            }
            #intarray {

            #}
            Default {}
        }
        #>

    }

    end {

    }
}