@Echo Off
Echo Most Windows computer have powershell disabled. this enables it in a secure mode.
powershell -command "& {Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -scope CurrentUser}"
Echo Your Powershell mode for CurrentUser is now "RemoteSigned"
pause
