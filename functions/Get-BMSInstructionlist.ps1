Function Get-BMSInstructionList {
    [CmdletBinding()]
    Param([ValidateSet("String","Array","Range")][String]$Handler,[Switch]$Common)

    process {
        $selection = $global:BMSInstructionSet.Command | Select-Object -Property Alias,Instruction,Category,Handler
        if ($Common) {
            Write-Verbose ("Selected common instructions") 
                Write-Verbose "Can't use Category or Handler filters with Common switch."
                $selection = $global:BMSInstructionSet.Command | ?{$_.Common -eq $true} | Select-Object -Property Alias,Instruction,Category,Handler
        }
        else {
            if ($Category) {
                Write-Verbose ("Selected " + $Category + " category type") 
                $selection = $global:BMSInstructionSet.Command | ?{$_.Category -match $Category} | Select-Object -Property Alias,Instruction,Category,Handler
            }
            if ($Handler)
            {
                Write-Verbose ("Selected " + $Handler + " type handler")
                $selection = $global:BMSInstructionSet.Command | ?{$_.Handler -match $Handler} | Select-Object -Property Alias,Instruction,Category,Handler
            }
        }
    return $selection
    }
    
}