function Use-BMSMQTTConfiguration {
    $BrokerPath = (Join-Path -Path $BMSInstructionSet.Config.MQTT.ServicePaths.Unix.ServiceConfPath -ChildPath $BMSInstructionSet.Config.MQTT.ServicePaths.Unix.ServiceConf)
    $Conf = Get-Content $BrokerPath | ConvertFrom-Json
    $BMSInstructionSet.Config.MQTT.Password = ConvertTo-SecureString $Conf.BrokerCredential.Password
    $BMSInstructionSet.Config.MQTT.Username = $Conf.BrokerCredential.UserName
    $BMSInstructionSet.Config.MQTT.Server = $Conf.BrokerHost
    $BMSInstructionSet.Config.MQTT.Port = $Conf.BrokerPort
    $BMSInstructionSet.Config.MQTT.Frequency = $Conf.BrokerFrequency
    $BMSInstructionSet.Config.MQTT.TopicPrefix = $Conf.BrokerPrefix
    $BMSInstructionSet.Config.MQTT.Retain = $Conf.BrokerRetain
    Write-Host "Merged MQTT Configuration file with BMSInstructionSet object"
}

function Send-MQTTValue {
    [CmdletBinding()]
    param(
        $User = $BMSInstructionSet.Config.MQTT.Username,
        $Password = $BMSInstructionSet.Config.MQTT.Password,
        $Address = $BMSInstructionSet.Config.MQTT.Server,
        $TCPPort=$BMSInstructionSet.Config.MQTT.Port)

    $PWD = ConvertFrom-SecureString -SecureString $Password -AsPlainText

    if (!(Test-Path (which mosquitto_pub))) {
        Throw "This function requires mosquitto_pub.`r`nTry installing with [apt-get install mosquitto-clients], for example."
    }


    #specific pack information about cell voltage
    $Values = $null
    $Values = Get-BMSParameter CELL
    $i = 1
    ForEach ($v in $Values) {
        $topic = ($BMSInstructionSet.Config.MQTT.TopicPrefix + "battery/cell/" + $i + "/volts") 
        $v.Value | mosquitto_pub -h $Address -p $TCPPort -i RECBMS -t $topic -u $User -P $PWD -r -l --quiet 2>&1 | out-null
        $i++
    }
    Get-Date | Out-Host
    $Values | Out-Host
    "Wrote CELL parameters to MQTT Broker" | Out-Host


    #specific pack information about cell resistance
    $Values = $null
    $Values = Get-BMSParameter RINT
    $i = 1
    ForEach ($v in $Values) {
        $topic = ($BMSInstructionSet.Config.MQTT.TopicPrefix + "battery/cell/" + $i + "/ohms") 
        $v.value | %{"{0:N10}" -f $_} | %{$_.ToString()} | mosquitto_pub -h $Address -p $TCPPort -i RECBMS -t $topic -u $User -P $PWD -r -l --quiet 2>&1 | out-null
        $i++
    }
    Get-Date | Out-Host
    $Values | Out-Host
    "Wrote RINT parameters to MQTT Broker" | Out-Host


    #specific pack information with valuable data
    $Values = $null
    $Values = Get-BMSParameter @("LCD1","LCD3")
    ForEach ($v in $Values) {
        $topicName = $v.Description -replace " ","_"
        $topic = ($BMSInstructionSet.Config.MQTT.TopicPrefix + "battery/status/" + $topicName) 
        $v.Value | mosquitto_pub -h $Address -p $TCPPort -i RECBMS -t $topic -u $User -P $PWD -r -l --quiet 2>&1 | out-null
    }
    Get-Date | Out-Host
    $Values | Out-Host
    "Wrote LCD1,LCD3 parameters to MQTT Broker" | Out-Host


    #specific pack information about temperatures
    $Values = $null
    $Values = Get-BMSParameter @("BTEM","PTEM")
    $i = 1
    ForEach ($v in $Values) {
        if ($v.Description -match "BMS") {
            $topic = ($BMSInstructionSet.Config.MQTT.TopicPrefix + "battery/status/temperature/bms/1")
            $v.Value | mosquitto_pub -h $Address -p $TCPPort -i RECBMS -t $topic -u $User -P $PWD -r -l --quiet 2>&1 | out-null
        }
        else {
            $topic = ($BMSInstructionSet.Config.MQTT.TopicPrefix + "battery/status/temperature/pack/" + $i)
            $v.Value | mosquitto_pub -h $Address -p $TCPPort -i RECBMS -t $topic -u $User -P $PWD -r -l --quiet 2>&1 | out-null
            $i++
        }
    }
    Get-Date | Out-Host
    $Values | Out-Host
    "Wrote BTEM,PTEM parameters to MQTT Broker" | Out-Host
}

