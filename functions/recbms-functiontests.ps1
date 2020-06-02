
#returns one instruction CMAX value of 4.2
Build-BMSMessage (Assert-BMSMessage -Command @{"CMAX"="4.2"} -verbose) -verbose

#returns one instruction CMAX of ? query type
Build-BMSMessage (Assert-BMSMessage -Command CMAX -verbose) -verbose

#returns two instructions of CMAX, CMIN of ? query type
Build-BMSMessage (Assert-BMSMessage -Command CMAX,CMIN -verbose) -verbose

#returns two instructions of CMAX, CMIN to set to a value
Build-BMSMessage (Assert-BMSMessage -Command @{"CMAX"="4.2";"CMIN"="3.2"} -verbose) -verbose

#exceeding bounds of instructions should return no instructions
Build-BMSMessage (Assert-BMSMessage -Command @{"CMAX"="-3";"CMIN"="99"} -verbose) -verbose

#this should return zero errors. 
Build-BMSMessage (Assert-BMSMessage -Command (Get-BMSInstructionList -verbose).Instruction -verbose) -verbose

#this should return 42 instructions (currently)
(Get-BMSInstructionList -verbose).Count