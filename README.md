# ps-recbms
Powershell based management for REC-BMS battery management

The intention of this set of management functions is as follows:

* Offer a "lightweight" implementation of getting and setting data from REC-BMS that isn't reliant on a big installer
* Offer more insight into the messaging component of on the wire data to and from the BMS microcontroller.
* Build a general framework for parsing and understanding the intracacies of the instructionset.

Other considerations:
* This is not highly efficient - internally, I am using a Microsoft .net ```System.IO.Ports.SerialPort``` object to talk on the wire, which isn't ideal.
* I almost immediately translate bytearrays to hex string arrays. This is very helpful for development purposes and understanding the code. Not so helpful in making it run fast.
  * A better approach in the future will be to re-balance the effort towards direct byte manipulation and translate the json libary definitions to binary representation.
  * As it sits right now, this model (in my mind) is overly obvious and should be obviously portable.

This is a work in progress...


Findings and Notes
*REC-BMS 1Q is based on an Amtel AVR32 90CAN32 microcontroller
*Binary value floats (single precision, 32 bit) are little endian and need to be processed accordingly.


![progress so far](https://raw.githubusercontent.com/aaronsb/ps-recbms/master/recbms.gif)
