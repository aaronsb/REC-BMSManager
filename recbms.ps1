#manifest

# Preprocessor for determining instruction type input and constructing a valid message
. .\functions\CMDPreProcessor.ps1

# Instruction message assertion code, generates valid query data structures
. .\functions\AssertMessage.ps1

# CRC functions for signing byte data streams
. .\functions\CRC16.ps1

# Instruction message builder to suit instruction command structure syntax
. .\functions\BuildMessage.ps1

# Serial communication functions for sending and receieving instructions and telemetry
. .\functions\SendMessage.ps1

# Message parser for converting instruction response bytestreams into value streams
. .\functions\ParseMessage.ps1

# Stream processor functions for intermediary and final data presentation
. .\functions\MessageStream.ps1

# Helper functions for simplified UX and presentation
. .\functions\HelperFunctions.ps1


#instance a library global
$global:BMSInstructionSet = Get-BMSLibraryInstance
