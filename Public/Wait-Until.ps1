<#
.SYNOPSIS
Induces a wait operation using a simple time specifier.

.DESCRIPTION
Wait-Until uses a brief time span operator D:H:M:S and then waits that specified time before continuing.

.PARAMETER pattern
Pattern is a string of four digits seperated by colons. 

Position 1: Days
Position 2: Hours
Position 3: Minutes
Position 4: Seconds

.EXAMPLE
Wait-Until 0:0:3:45

(Delay for 3 minutes and 45 seconds)

.EXAMPLE
Wait-Until 1:2:15:2

(Delay for 1 day, 2 hours, 15 minutes, and 2 seconds)

.NOTES
Sending a break will stop this loop.
#>
Function Wait-Until
{
    [CmdletBinding()]
    param([string][Parameter(Mandatory=$true)]$pattern)
    $Delay = ($pattern.Split(":"))
    $DelaySpan = New-TimeSpan -Days $Delay[0] -Hours $Delay[1] -Minutes $Delay[2] -Seconds $Delay[3]
    Write-Verbose "Waiting timespan"
    Write-Verbose ($DelaySpan | Out-String)
    Start-Sleep -Seconds $DelaySpan.TotalSeconds
}