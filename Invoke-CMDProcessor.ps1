Function Invoke-CmdPreprocessor {
    Param($Command)
        #begin region
        #check to see if input object is of one of the required types
        #I'm conflicted between requiring an ordered dictionary hashtable and just a regular old hashtable
        #I think it makes sense from a "less complexity" perspective to use a hashtable since a multi-instruction
        #sentence doesn't really matter the order in which it's sent to the BMS controller
        #before the object is consumed by the serial stream processor function, it's cast internally into an ordered
        #dictionary since I need to keep track of which command was executed in which order for decoding purposes

        switch ($Command.GetType().Name) {
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
                $Command = @{$Command="?"}
            }
            "Object[]" {
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
    return $Command
}