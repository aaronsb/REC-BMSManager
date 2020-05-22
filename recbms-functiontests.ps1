Function Test-InstructionValidation
{
    $biglist = (Get-BMSInstructionList -verbose).Instruction
    if ($biglist)
    {
        Approve-BMSInstructionList -Command $biglist -verbose
    }
}