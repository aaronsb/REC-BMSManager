
<#
    Preprocessor for determining instruction type input and constructing a valid message
    Instruction message assertion code, generates valid query data structures
    CRC functions for signing byte data streams
    Instruction message builder to suit instruction command structure syntax
    Serial communication functions for sending and receieving instructions and telemetry
    Message parser for converting instruction response bytestreams into value streams
    Stream processor functions for intermediary and final data presentation
    Helper functions for simplified UX and presentation
#>


$RECBMSResources = @(
    "./Private/Add-HexStreamEncapsulation.ps1",
    "./Private/Assert-BMSMessage.ps1",
    "./Private/Build-BMSMessage.ps1",
    "./Private/Get-CRC16.ps1",
    "./Private/Invoke-CMDPreProcessor.ps1",
    "./Private/Convert-BMSMessage.ps1",
    "./Private/Send-BMSMessage.ps1",
    "./Private/Test-MessageCRC.ps1",
    "./Public/Get-BMSInstructionList.ps1",
    "./Public/Get-BMSLibraryInstance.ps1",
    "./Public/Get-BMSParameter.ps1",
    "./Public/Set-BMSParameter.ps1"
    "./Public/Send-MQTTValue.ps1"
)

ForEach ($resource in $RECBMSResources) {
. (Join-Path -Path $PSScriptRoot -ChildPath $resource)
}

#instance a library global
$global:BMSInstructionSet = Get-BMSLibraryInstance
