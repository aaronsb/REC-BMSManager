# REC-BMSManager: A Powershell based management tool for REC-BMS battery management tools.
Powershell based management for REC-BMS battery management

The intention of this set of management functions is as follows:

* Offer a "lightweight" implementation of getting and setting data from REC-BMS that isn't reliant on a big Windows installer.
* Offer more insight into the messaging component of on the wire data to and from the BMS microcontroller.
* Build a general framework for parsing and understanding the intracacies of the instructionset.

Other considerations:
* Tnternally, these modules use the  ```System.IO.Ports.SerialPort``` object to talk on the wire. I seem to get occasional hangups and resets, so there is some testing and lazy starts to events to soften the fragility of that state.
* This toolset functions properly in both Windows and Linux environments. It was developed in Powershell Core

Current release notes:
* REC-BMS 1Q is based on an Amtel AVR32 90CAN32 microcontroller
* In order for me to get this to function in Linux, I requested REC-BMS to issue a special firmware that can communicate on 38400 BPS, because 56000 BPS (default) isn't a compatible BPS rate with FTDI USB Serial chipsets. If anyone knows how to make that rate work easily, please let me know!
* Set-BMSParameter doesn't actually effect changes. The BMS returns ERROR1 - I am looking into that with REC-BMS, to see if perhaps there's a different instruction that is necessary to send on the port.

Future plans:
* Since I use Home Assistant, I am planning on building a docker container that turns this module into a sensor platform. This way, it easily becomes integrated with long term metrics and telemetry.


List of public function conversation flow:

  Get-BMSParameter

  Set-BMSParameter
  Get-BMSInstructionList
  Get-BMSLibraryInstance


Assert -> Build -> Send -> Parse -> Decode -> Present




![Getting BMS Parameters](https://raw.githubusercontent.com/aaronsb/REC-BMSManager/master/images/get-bmsparameters.gif)

![Functions have extra verbosity!](https://raw.githubusercontent.com/aaronsb/REC-BMSManager/master/images/get-parameters-verbose.gif)
