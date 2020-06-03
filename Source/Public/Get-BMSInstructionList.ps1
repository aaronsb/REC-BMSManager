Function Get-BMSInstructionList {
    [CmdletBinding()]
    Param([ValidateSet(
        "String",
        "Array",
        "Range",
        "Configurable",
        "Common"
        )]$Type,
        [ValidateSet(
            "Amperage",
            "BMS",
            "Cell",
            "Error",
            "Identification",
            "Information",
            "Pack",
            "SOC",
            "Temperature",
            "Victron"
        )]$Category,
        [switch]$FullCommand)

    process {

        Switch ($Type) {
            String {$Selection = $global:BMSInstructionSet.Command | ?{$_.Handler -match "String"}}
            Array {$Selection = $global:BMSInstructionSet.Command | ?{$_.Handler -match "Array"}}
            Range {$Selection = $global:BMSInstructionSet.Command | ?{$_.Handler -match "Range"}}
            Configurable {$selection = $global:BMSInstructionSet.Command | ?{$_.ReadOnly -eq $false}}
            Common {$global:BMSInstructionSet.Command | ?{$_.Common -eq $true}}
            
            Default {
                $Selection = $global:BMSInstructionSet.Command
            }
        }
        
        if ($Category) {
            $Selection = $Selection | ?{$_.Category -match $Category}
        }

        if ($FullCommand) {
            Return $Selection.PSObject.Copy()
        }
        else {
            ($Selection | Select-Object -Property Alias,Instruction,Category,Handler).PSObject.Copy()
        }

    }
    
}