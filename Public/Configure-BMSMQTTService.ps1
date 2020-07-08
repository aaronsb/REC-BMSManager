function Install-BMSMQTTService
{
    #region Configure mqtt service

    switch ($PSVersionTable.Platform) {
        Unix {
            $serviceName = $BMSInstructionSet.Config.MQTT.ServicePaths.Unix.ServiceName
            $systemdPath = $BMSInstructionSet.Config.MQTT.ServicePaths.Unix.SystemdPath
            $executableName = $BMSInstructionSet.Config.MQTT.ServicePaths.Unix.ExecutableName
            $executablePath = $BMSInstructionSet.Config.MQTT.ServicePaths.Unix.ExecutablePath
            $serviceConf = $BMSInstructionSet.Config.MQTT.ServicePaths.Unix.ServiceConf
            $serviceConfPath = $BMSInstructionSet.Config.MQTT.ServicePaths.Unix.ServiceConfPath
            $moduleOriginPath = (Get-ChildItem $PSCommandPath).Directory
            if ((id -u) -eq 1000) {
                try {
                     if (Get-Process -Name systemd) {
                        Copy-Item -Force -Path (Join-Path -Path $moduleOriginPath -ChildPath $serviceName) -Destination $systemdPath
                        Copy-Item -Force -Path (Join-Path -Path $moduleOriginPath -ChildPath $executableName) -Destination $executablePath
                        Update-BMSMQTTService -confTargetPath (Join-Path -Path $serviceConfPath -ChildPath $serviceConf)
                     }
                     else {
                         Throw "This service requires systemd for installation"
                     }
                }
                catch {
                    
                }
                Test-Path $ServiceSource
            }
            else {
                Write-Error "This command requires Root privilages to install service."
            }
        }

        Win32NT {
            Write-Warning "Windows Service: Not Implemented Yet"
        }
        Default {
            Write-Error "This script requires PowerShell Core to function properly."
        }
    }
}

function Update-BMSMQTTService
{
    param($confTargetPath="bmsmqtt.conf")
    if (Test-Path $confTargetPath) {
        Write-Warning "This will overwrite your existing configuration file. Press Control-C now to cancel."
    }
    switch ($PSVersionTable.Platform) {
        Unix {
            if ((id -u) -eq 1000) {
                #region configure MQTT Service
                $BrokerAcct = Read-Host -Prompt "MQTT Broker Account"
                
                if (!$BrokerAcct) {
                    Write-Error "A broker credential and password is required for this service to work."
                }
                else {
                    $BrokerPWD = Read-Host -Prompt "MQTT Broker Password" -AsSecureString
                    $BrokerCredential = New-Object -typename PSCredential -ArgumentList @($BrokerAcct,$BrokerPWD)
                    $BrokerCredJSON = $BrokerCredential | Select Username,@{Name="Password";Expression = { $_.password | ConvertFrom-SecureString }}
                }
                

                $BrokerHost = Read-Host -Prompt "MQTT Broker Hostname"
                if ($BrokerHost -eq "") {
                    Write-Warning "Defaulting to host localhost"
                    $BrokerHost = "localhost"
                }
                $BrokerPort = Read-Host -Prompt "MQTT Broker TCP Port"
                if ($BrokerPort -eq "") {
                    Write-Warning "Defaulting broker port TCP/1883"
                    $BrokerPort = 1883
                }
                $BrokerPrefix = Read-Host -Prompt "MQTT Prefix"
                if ($BrokerPrefix -eq "") {
                    $BrokerPrefix = $null
                }
                else {
                    #Sanitize broker path
                    $BrokerPrefix = $BrokerPrefix.Replace("\","/")
                    $BrokerPrefix = $BrokerPrefix.TrimStart("/")
                    $BrokerPrefix = $BrokerPrefix.TrimEnd("/")
                    $BrokerPrefix = ($BrokerPrefix + "/")
                }
                $BrokerRetain = Read-Host -Prompt "Retain? [Y/N]"
                if ($BrokerRetain -match "n") {
                    $BrokerRetain = $false
                }
                else {
                    if ($BrokerRetain -match "y") {
                        $BrokerRetain = $true
                    }
                    else {
                        Write-Warning "Retain defaulting to true"
                    }
                    
                }
                $BrokerConf = @{}
                $BrokerConf.Add("BrokerCredential",$BrokerCredJSON)
                $BrokerConf.Add("BrokerHost",$BrokerHost)
                $BrokerConf.Add("BrokerPort",$BrokerPort)
                $BrokerConf.Add("BrokerPrefix",$BrokerPrefix)
                $BrokerConf.Add("BrokerRetain",$BrokerRetain)
                $BrokerConf.Add("BrokerFrequency","0:0:0:60")
            }
            else {
                Write-Error "This command requires SUDO privilages"
            }
        }

        Win32NT {
            Write-Warning "Windows Service: Not Implemented Yet"
        }
        Default {
            Write-Error "This script requires PowerShell Core to function properly."
        }
        
    }
    $BrokerConf | ConvertTo-Json | Out-File -Force $confTargetPath
}

function Uninstall-BMSMQTTService
{
    switch ($PSVersionTable.Platform) {
        Unix {
            if ((id -u) -eq 1000) {
                Join-Path -Path (gci $PSCommandPath).Directory -ChildPath "recbmsmqtt.service"
            }
            else {
                Write-Error "This command requires SUDO privilages"
            }
        }

        Win32NT {
            Write-Warning "Windows Service: Not Implemented Yet"
        }
        Default {
            Write-Error "This script requires PowerShell Core to function properly."
        }
    }
}
