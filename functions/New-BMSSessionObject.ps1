Function New-BMSSessionObject {
    [CmdletBinding()]
    Param($Command)
    begin {
        $Command = Invoke-CmdPreprocessor $Command
        #instance instruction library
        $Config = Get-BMSConfigMeta
        #zzz todo merge config and library calls together 
        $sO = [pscustomobject]@{}
        $MaxMessagePerSession = $Config.Config.Session.MaxMessagesPer
        $StreamIndex = 0
        $FirstCommandIndex = 0
        $LastCommandIndex = 0
    }

    # MaxMessagePerSession = 3
    # (4 total commands)
    # Stream 0
    #   Command,Command,Command
    # Stream 1
    #   Command
    #
    # MaxMessagePerSession = 1
    # (4 total commands)
    # Stream 0
    #   Command
    # Stream 1
    #   Command
    # Stream 2
    #   Command
    # Stream 3
    #   Command
    
    process {

        $Command = Approve-BMSInstructionList -Command $Command
        
        do {
            $sO | Add-Member -MemberType NoteProperty -Name $StreamID -Value $null
            do {
                $LastCommandIndex = $LastCommandIndex + $MaxMessagePerSession
                if (($LastCommandIndex +1)-gt $Command.Count) {
                    $LastCommandIndex = $Command.Count
                }
                $BMSMessage = $Command[$FirstCommandIndex..$LastCommandIndex]
                #New-BMSMessage -Instructions
                $FirstCommandIndex = $LastCommandIndex + 1
                $CommandID++
            } until ($CommandID -gt $Command.Count)
            $sO.$StreamID = $BMSMessage
            $StreamID++
        } until ($CommandID -gt $Command.Count)

    end {
        return $sO
    }
}
}