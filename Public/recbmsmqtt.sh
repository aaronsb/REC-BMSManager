#!/usr/bin/pwsh

Import-Module REC-BMSManager

Use-BMSMQTTConfiguration

while ($true) {
    Send-MQTTValue
    Wait-Until $BMSInstructionSet.Config.MQTT.Frequency
}

