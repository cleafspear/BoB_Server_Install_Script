#if you are reading this, you need to right click the file and "Run with PowerShell"



Function Start1 {
    Echo "Do you have Steam Command Already installed?"
    $Q1 = Read-Host "(y)es  (n)o  (c)ancel"
    Switch ($Q1) {
        'y'{CheckStm}
        'n'{InstallStm}
        'c'{exit}
        default {
            echo "input not valid" 
            Start1
        }
    }
}
Function InstallStm {
    Echo "Please enter the location you wish to install Steam Command"
    $Q2 = Read-Host "Leave Blank to install where this script was ran"
    if ($Q2 -eq ""){
        $Script:SetCmdPath = Join-Path $PSScriptRoot "Steam Command" #we use this path as well when generating the server automation scripts.
    } else {
        $Script:SetCmdPath = $Q2 
    }
    Echo "Installing SteamCommand at $SetCmdPath"
    New-Item -ItemType Directory -Force -Path $SetCmdPath | Out-Null
    Echo "Downloading Steamcommand from offical Source"
    Invoke-WebRequest -Uri "https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip" -OutFile "$SetCmdPath\steamcmd.zip"
    Echo "Unzipping Download"
    Expand-Archive -LiteralPath "$SetCmdPath\steamcmd.zip" -DestinationPath $SetCmdPath -Force
    Echo "Forcing update to Steam Command. This may take a few minutes"
    & "$SetCmdPath\steamcmd.exe" "+quit"
    InstallServer
}
Function CheckStm {
    Echo "Please enter the folder path of where the Steamcmd.exe is located"
    $Q2 = Read-Host "Leave Blank to return to the previous prompt"
    if ($Q2 -eq ""){
        Echo "Cancelled"
        Start1
    } else {
        $Script:SetCmdPath = $Q2 
        Echo "Checking to see if steamcmd.exe exist"
        if (Test-Path $SetCmdPath\steamcmd.exe) {
            echo "Steam Command found"
            InstallServer
        } else {
            echo "Steam Command not found. please make sure you use the full file path."
            echo "EX: C:\Example\file\path . do not include \steamcmd.exe"
            CheckStm
        }
        
    }
}
Function InstallServer {
Echo "Set the location where you would like to install Beasts of Bermuda Dedicated Server"
$Q3 = Read-Host "Leave Blank to install in the SteamCommand Server Folder"
if ($Q3 -eq ""){
        $Script:SetSvrPath = "$SetCmdPath\Server"#we use this path as well when generating the server automation scripts.
    } else {
        $Script:SetSvrPath = $Q3
    }
    Echo "Installing Beasts of Bermuda at $SetSvrPath"
    New-Item -ItemType Directory -Force -Path $SetSvrPath | Out-Null
    $UpdateArgs = "+login anonymous +force_install_dir ","""$SetSvrPath""",' "+app_update 882430"'," +quit" -join ""
    $params = $UpdateArgs.Split(" ") #steam is 'special' when parsing the args
    & "$SetCmdPath\steamcmd.exe" $params 
    Echo "Beast of Bermuda installed."
    AddAutomation
}
Function AddAutomation {
    Echo "Would you like us to generate the automation files to get the server running? Select 1 of the following:"
    Echo "(1) Basic script to launch the Server and seprate script to update Server"
    Echo "(2) Advanced script to launch the server and auto-restart on crash and seprate script to update Server"
    Echo "(3) Advanced script to launch the server and auto-restart on crash / update on restart"
    Echo "(4) Advanced script to launch the server and auto-restart on crash / update on restart, and add auto-restart"
    Echo "(c) Cancel Adding any scripts and finish install"
    Echo ""
    $Q4 = Read-Host "Selection"
    Switch ($Q4) {
        '1'{
            ReqBasicData
            Echo "Generating Startup.bat and installing at $SetSvrPath"
            $ScriptSource = """$SetSvrPath\WindowsServer\BeastsOfBermudaServer.exe"" -GameMode $ServerGM -MapName $ServerMap -SessionName $ServerName -NumPlayers $ServerCount ?Port=$ServerPort","?QueryPort=$ServerQuery -log" -join ""
            Set-Content -path $SetSvrPath\Startup.bat -Value $ScriptSource
            Echo "Generating Update.bat and installing at $SetSvrPath"
            $ScriptSource = """$SetCmdPath\steamcmd.exe"""," +login anonymous +force_install_dir ","""$SetSvrPath""",' "+app_update 882430 validate"'," +quit" -join ""
            Set-Content -path $SetSvrPath\Update.bat -Value $ScriptSource
            Echo "Install complete. run the Startup.bat file to start the server"
        }
        '2'{
            ReqBasicData
            Echo "Generating Startup.bat and installing at $SetSvrPath"
            $ScriptSource = '@Echo off',@"
Powershell.exe -executionpolicy remotesigned -File  "$SetSvrPath\Server.ps1"
"@ -join "`r`n"
            Set-Content -path $SetSvrPath\Startup.bat -Value $ScriptSource
            Echo "Generating Server.ps1 and installing at $SetSvrPath"
            BuildAdvancedScript -stype 1
            Set-Content -path $SetSvrPath\Server.ps1 -Value $SSourceCode
            Echo "Generating Update.bat and installing at $SetSvrPath"
            $ScriptSource = """$SetCmdPath\steamcmd.exe"""," +login anonymous +force_install_dir ","""$SetSvrPath""",' "+app_update 882430 validate"'," +quit" -join ""
            Set-Content -path $SetSvrPath\Update.bat -Value $ScriptSource
            Echo "Install complete. run the Startup.bat file to start the server"
        }
        '3'{
            ReqBasicData
            Echo "Generating Startup.bat and installing at $SetSvrPath"
            $ScriptSource = '@Echo off',@"
Powershell.exe -executionpolicy remotesigned -File  "$SetSvrPath\Server.ps1"
"@ -join "`r`n"
            Set-Content -path $SetSvrPath\Startup.bat -Value $ScriptSource
            Echo "Generating Server.ps1 and installing at $SetSvrPath"
            BuildAdvancedScript -stype 2
            Set-Content -path $SetSvrPath\Server.ps1 -Value $SSourceCode
            Echo "Install complete. run the Startup.bat file to start the server"
        }
        '4'{
            ReqBasicData
            Echo "Generating Startup.bat and installing at $SetSvrPath"
            $ScriptSource = '@Echo off',@"
Powershell.exe -executionpolicy remotesigned -File  "$SetSvrPath\Server.ps1"
"@ -join "`r`n"
            Set-Content -path $SetSvrPath\Startup.bat -Value $ScriptSource
            Echo "Generating Server.ps1 and installing at $SetSvrPath"
            BuildAdvancedScript -stype 3
            Set-Content -path $SetSvrPath\Server.ps1 -Value $SSourceCode
            Echo "Generating Restart.bat and installing at $SetSvrPath"
            $ScriptSource = "echo [BoB State Manager]>""$SetSvrPath\Automation\State.ini"" && echo restart=true>>""$SetSvrPath\Automation\State.ini"""
            Set-Content -path $SetSvrPath\Restart.bat -Value $ScriptSource
            Echo "Adding automation file and folder at $SetSvrPath\Automation\State.ini"
            New-Item -ItemType Directory -Force -Path $SetSvrPath\Automation | Out-Null
            Set-Content -path $SetSvrPath\Automation\State.ini -Value "[BoB State Manager]`r`nrestart=false"
            CreateScedualedTask
            Echo "Install complete. run the Startup.bat file to start the server"
        }
        'c'{
            Echo "Install complete. Create a script or shortcut to launch the server located at $SetSvrPath\WindowsServer\BeastsOfBermudaServer.exe"
        }
        default {
            echo "input not valid" 
            AddAutomation
        }
    }

}
Function ReqBasicData {
    Echo "We will now gather the basics needed to properly Setup the server"
    Echo "spelling must be exact for the server to work. Try copy and paste if needed"
    Echo ""
    Echo 'Select a map: Forest_Island Ancestral_Plains Rival_Shores DM_Caldera Test_Performance BB_Test_Map'
    $Script:ServerMap = Read-Host "Map"
    Echo ""
    Echo "Select a Game mode: Life_Cycle Combat Free_Roam"
    $Script:ServerGM = Read-Host "GameMode"
    Echo ""
    Echo "How many players will be playing?"
    $Script:ServerCount = Read-Host "Player Count"
    Echo ""
    Echo "What will be the server name? Hint: use _ in place of spaces"
    $Script:ServerName = Read-Host "Server_Name"
    Echo ""
    Echo "What port will you be using for the game? Default:7777"
    $Script:ServerPort = Read-Host "Server port"
    Echo ""
    Echo "What port will you be using for the game's Steam Query Port? Default:27015"
    $Script:ServerQuery = Read-Host "Server Query port"
}
Function BuildAdvancedScript {
    param ([int]$stype)
    $ScriptVariables = "`$ServerLoc = ""$SetSvrPath"" ","#Game Settings","`$ServerMap = ""$ServerMap"" ","`$ServerGM = ""$ServerGM"" ","`$PlayerCount = ""$ServerCount"" ","`$ServerName = ""$ServerName"" ","`$ServerPort = $ServerPort ","`$ServerQuery = $ServerQuery " -join "`r`n"#parsed section of script, contains ALL variables 
    $AltScriptVariables = '$StateData = ',"""$SetSvrPath\Automation\State.ini""" -join ""
    $SteamCmdInsert = '$SteamCmd = ',"""$SetCmdPath\steamcmd.exe""" -join ""
    $Scriptinit = @'
$ServerArgs = " -GameMode $ServerGM -MapName $ServerMap -SessionName $ServerName -NumPlayers $PlayerCount ?Port=$ServerPort?","QueryPort=$ServerQuery -log " -join "" 
'@
    
    $ScriptUpdateArgs = @'
$UpdateArgs = "+login anonymous +force_install_dir ","""$ServerLoc""",' "+app_update 882430"'," +quit" -join ""
$params = $UpdateArgs.Split(" ")
'@
    
    $Kill_Monitor = @'
function Kill-Tree { #BoB has multiple processes used to run the server. this gets them all
    Param([int]$ppid)
    Get-CimInstance Win32_Process | Where-Object { $_.ParentProcessId -eq $ppid } | ForEach-Object { Kill-Tree $_.ProcessId }
    Stop-Process -Id $ppid
}

function CheckPass {
     $Savecontent = get-content -path $StateData #grab the original content of the file
     for($i = 0;$i -lt $Savecontent.Count; $i++){
        if($Savecontent[$i].Substring(0,'restart'.Length) -eq 'restart'){#does the selector variable match the line name
            if($Savecontent[$i].Substring('restart'.Length+1) -eq 'true'){
                echo "stopping server with process id $proc"
                Kill-Tree -ppid $proc
                $Savecontent[$i]='restart=false'
                Set-Content -path $SaveData -Value $Savecontent
            }  
         }
     }
}
'@
    
    $MainLoop1 = @'
echo "Server root: $ServerLoc"
echo 'Server autorestart active, Written by Cleafspear'
echo 'close this window to stop the autorestart'
$proc = (Start-Process -FilePath $ServerLoc\WindowsServer\BeastsOfBermudaServer.exe -ArgumentList $ServerArgs -PassThru).Id #we start the server with the assumption that the server ran by ONLY this script is valid. allows for more then one BOB server to run
echo "Server Started with Process id $proc"

while($true){
    Sleep 10 #we check of the process is still alive every 10 seconds, keeps overhead low.
'@
    $MainsubLoop1 = "CheckPass"
    $MainsubLoop2 = @'
    if((get-process -Id $proc -ea SilentlyContinue) -eq $Null){
        echo "Server with Process id $proc was killed."
'@
    $MainsubLoop3 = @'
            & $SteamCmd $params
        echo "Server Update ran. Starting Server"
'@
    $Endloop = @'
            $proc = (Start-Process -FilePath $ServerLoc\WindowsServer\BeastsOfBermudaServer.exe -ArgumentList $ServerArgs -PassThru).Id
        echo "New Server Started with Process id $proc"
    }
}
'@
    switch ($stype) {
    1{$Script:SSourceCode = $ScriptVariables,$Scriptinit,$MainLoop1,$MainsubLoop2,$Endloop -join "`r`n"}
    2{$Script:SSourceCode = $ScriptVariables,$SteamCmdInsert,$Scriptinit,$ScriptUpdateArgs,$MainLoop1,$MainsubLoop2,$MainsubLoop3,$Endloop -join "`r`n"}
    3{$Script:SSourceCode = $ScriptVariables,$AltScriptVariables,$SteamCmdInsert,$Scriptinit,$ScriptUpdateArgs,$Kill_Monitor,$MainLoop1,$MainsubLoop1,$MainsubLoop2,$MainsubLoop3,$Endloop -join "`r`n"}
    }
}
Function CreateScedualedTask {
    Echo "Would you like for us to automatically add the restart function to your computer?it will automatically schedule restarts at midnight your computer time."
    $Q5 = Read-Host "(y)es  (n)o"
    Switch ($Q5) {
        'y'{Echo "Creating a restart entry in Task Sceduler"
            $action = New-ScheduledTaskAction -Execute "$SetSvrPath\Restart.bat"
            $trigger =  New-ScheduledTaskTrigger -Daily -At 12am
            Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "BeastsOfBermuda Restart" -Description "Daily Restart of the Beast of Bermuda Server"
        }
        'n'{Echo "You will need to create an entry in task scheduler that runs $SetSvrPath\Restart.bat at your perferred time"}
        default {
            echo "input not valid" 
            Start1
        }
    }
}
Echo "Beasts of Bermuda Dedicated Server Installer. Written by Cleafspear"
Start1
pause
exit