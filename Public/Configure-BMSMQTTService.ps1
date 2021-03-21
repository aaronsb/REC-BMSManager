function Install-BMSMQTTService {
    switch ($PSVersionTable.Platform) {
        Unix {
            if ((Test-Path /run/systemd/system) -eq $false) {
                throw "BMSMQTT Service installation requires systemd"
            }
            $confTargetPath = (Join-Path -Path $BMSInstructionSet.Config.MQTT.ServicePaths.Unix.ServiceConfPath -ChildPath $BMSInstructionSet.Config.MQTT.ServicePaths.Unix.ServiceConf)
            if (Test-Path $confTargetPath) {
                Write-Warning "This will overwrite your existing configuration file. Press Control-C now to cancel or Enter to continue."
                Read-Host
            }
            $serviceName = $BMSInstructionSet.Config.MQTT.ServicePaths.Unix.ServiceName
            $systemdPath = $BMSInstructionSet.Config.MQTT.ServicePaths.Unix.SystemdPath
            $executableName = $BMSInstructionSet.Config.MQTT.ServicePaths.Unix.ExecutableName
            $executablePath = $BMSInstructionSet.Config.MQTT.ServicePaths.Unix.ExecutablePath
            $serviceConf = $BMSInstructionSet.Config.MQTT.ServicePaths.Unix.ServiceConf
            $serviceConfPath = $BMSInstructionSet.Config.MQTT.ServicePaths.Unix.ServiceConfPath
            $moduleOriginPath = (Get-ChildItem $PSCommandPath).Directory
            if ((id -u) -eq 0) {
                if (Get-Process -Name systemd) {
                Write-Verbose "Copying service file to systemd"
                Copy-Item -Force -Path (Join-Path -Path $moduleOriginPath -ChildPath $serviceName) -Destination $systemdPath
                chmod 644 (Join-Path -Path $systemdPath -ChildPath $serviceName)
                Write-Verbose "Copying executable script to bin"
                Copy-Item -Force -Path (Join-Path -Path $moduleOriginPath -ChildPath $executableName) -Destination $executablePath
                chmod +x (Join-Path -Path $executablePath -ChildPath $executableName)
                if (!(Test-Path $serviceConfPath)) {
                    Write-Verbose "Creating configuration directory"
                    New-Item $serviceConfPath -ItemType Directory  | Out-Null
                }
                Write-Verbose "Updating /etc/conf file"
                Update-BMSMQTTService
                Write-Verbose "Reloading systemd unit files"
                systemctl daemon-reload
                Write-Verbose "Enabling systemd service unit at boot"
                systemctl enable recbmsmqtt
                Write-Verbose "Starting systemd service unit"
                systemctl start recbmsmqtt
                Write-Verbose "Getting status of systemd service unit"
                systemctl status recbmsmqtt

                }
                else {
                    Throw "This service requires systemd for installation"
                }
                Write-Host "You may now start service with systemctl start recbmsmqtt"
            }
            else {
                Write-Error "This command requires Root context to install service. (Hint: use [sudo -i] and try again.)"
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
    switch ($PSVersionTable.Platform) {
        Unix {
            if ((id -u) -eq 0) {
                $confTargetPath = (Join-Path -Path $BMSInstructionSet.Config.MQTT.ServicePaths.Unix.ServiceConfPath -ChildPath $BMSInstructionSet.Config.MQTT.ServicePaths.Unix.ServiceConf)
                if (Test-Path $confTargetPath) {
                    Write-Warning "This will overwrite your existing configuration file. Press Control-C now to cancel."
                }
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
                
                $BrokerHost = Read-Host -Prompt "MQTT Broker Hostname [localhost]"
                if ($BrokerHost -eq "") {
                    Write-Warning "Defaulting to host localhost"
                    $BrokerHost = "localhost"
                }
                $BrokerPort = Read-Host -Prompt "MQTT Broker TCP Port [1883]"
                if ($BrokerPort -eq "") {
                    Write-Warning "Defaulting broker port TCP/1883"
                    $BrokerPort = 1883
                }
                $BrokerPrefix = Read-Host -Prompt "MQTT Prefix [battery\#]"
                if ($BrokerPrefix -eq "") {
                    $BrokerPrefix = "battery\#"
                }
                else {
                    #Sanitize broker path
                    $BrokerPrefix = $BrokerPrefix.Replace("\","/")
                    $BrokerPrefix = $BrokerPrefix.TrimStart("/")
                    $BrokerPrefix = $BrokerPrefix.TrimEnd("/")
                    $BrokerPrefix = ($BrokerPrefix + "/")
                }
                $BrokerRetain = Read-Host -Prompt "Retain? [Y/n]"
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
    Write-Verbose ("Wrote new conf to " + $confTargetPath)
}

function Uninstall-BMSMQTTService
{
    switch ($PSVersionTable.Platform) {
        Unix {
            if ((id -u) -eq 0) {
                $confTargetPath = (Join-Path -Path $BMSInstructionSet.Config.MQTT.ServicePaths.Unix.ServiceConfPath -ChildPath $BMSInstructionSet.Config.MQTT.ServicePaths.Unix.ServiceConf)
                if (Test-Path $confTargetPath) {
                    Write-Warning "This will disable and remove the recbmsmqtt service and configuration files. Press Control-C now to cancel or Enter to continue."
                    Read-Host
                }
                systemctl disable recbmsmqtt
                remove-item $confTargetPath
                remove-item /etc/systemd/system/recbmsmqtt.service
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
