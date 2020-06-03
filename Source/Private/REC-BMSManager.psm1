#manifest
<#
# Preprocessor for determining instruction type input and constructing a valid message
. .\Private\CMDPreProcessor.ps1

# Instruction message assertion code, generates valid query data structures
. .\Private\AssertMessage.ps1

# CRC functions for signing byte data streams
. .\Private\CRC16.ps1

# Instruction message builder to suit instruction command structure syntax
. .\Private\BuildMessage.ps1

# Serial communication functions for sending and receieving instructions and telemetry
. .\Private\SendMessage.ps1

# Message parser for converting instruction response bytestreams into value streams
. .\Private\ParseMessage.ps1

# Stream processor functions for intermediary and final data presentation
. .\Private\MessageStream.ps1

# Helper functions for simplified UX and presentation
. .\Public\HelperFunctions.ps1

#>
#instance a library global
$global:BMSInstructionSet = Get-BMSLibraryInstance
