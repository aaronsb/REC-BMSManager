function Send-MQTTValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]$User,
        [System.Security.SecureString][Parameter(Mandatory=$true)]$Password,
        [Parameter(Mandatory = $true)]$Address,
        $TCPPort=1883)

    #secured with a piece of tape. It's the thought that counts right?
    $PWD = ConvertFrom-SecureString -SecureString $Password -AsPlainText

    if (!(Test-Path (which mosquitto_pub))) {
        Throw "This function requires mosquitto_pub.`r`nTry installing with [apt-get install mosquitto-clients], for example."
    }
    #arrays of cell data
    $Values = $null
    $Values = Get-BMSParameter CELL
    $i = 1
    ForEach ($v in $Values) {
        $topic = ("bus/battery/cell/" + $i + "/volts") 
        $v.Value | mosquitto_pub -h $Address -p $TCPPort -i RECBMS -t $topic -u $User -P $PWD -r -l
        $i++
    }

    $Values = $null
    $Values = Get-BMSParameter RINT
    $i = 1
    ForEach ($v in $Values) {
        $topic = ("bus/battery/cell/" + $i + "/ohms") 
        $v.value | %{"{0:N10}" -f $_} | %{$_.ToString()} | mosquitto_pub -h $Address -p $TCPPort -i RECBMS -t $topic -u $User -P $PWD -r -l
        $i++
    }

    $Values = $null
    #specific pack information with interesting names
    $Values = Get-BMSParameter @("LCD1","LCD3")
    ForEach ($v in $Values) {
        $topicName = $v.Description -replace " ","_"
        $topic = ("bus/battery/status/" + $topicName) 
        $v.Value | mosquitto_pub -h $Address -p $TCPPort -i RECBMS -t $topic -u $User -P $PWD -r -l
    }
    
    $Values = $null
    #specific pack information with interesting names
    $Values = Get-BMSParameter @("BTEM","PTEM")
    $i = 1
    ForEach ($v in $Values) {
        if ($v.Description -match "BMS") {
            $topic = "bus/battery/status/temperature/bms/1"
            $v.Value | mosquitto_pub -h $Address -p $TCPPort -i RECBMS -t $topic -u $User -P $PWD -r -l
        }
        else {
            $topic = ("bus/battery/status/temperature/pack/" + $i)
            $v.Value | mosquitto_pub -h $Address -p $TCPPort -i RECBMS -t $topic -u $User -P $PWD -r -l
            $i++
        }
    }
   

    
}