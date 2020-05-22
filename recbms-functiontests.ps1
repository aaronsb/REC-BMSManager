
#returns one instruction CMAX value of 4.2
Approve-BMSInstructionList -Command @{"CMAX"="4.2"} -verbose

#returns one instruction CMAX of ? query type
Approve-BMSInstructionList -Command CMAX -verbose

#returns two instructions of CMAX, CMIN of ? query type
Approve-BMSInstructionList -Command CMAX,CMIN -verbose

#returns two instructions of CMAX, CMIN to set to a value
Approve-BMSInstructionList -Command @{"CMAX"="4.2";"CMIN"="3.2"} -verbose

#exceeding bounds of instructions should return no instructions
Approve-BMSInstructionList -Command @{"CMAX"="-3";"CMIN"="99"} -verbose

#this should return zero errors. 
Approve-BMSInstructionList -Command (Get-BMSInstructionList -verbose).Instruction -verbose

#this should return 42 instructions (currently)
(Get-BMSInstructionList -verbose).Count