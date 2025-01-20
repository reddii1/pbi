# Set file and folder path for Gateway installer .exe
$folderpath="c:\windows\temp"
$filepath="$folderpath\gateway-Setup-ENU.exe"
 
#If gateway not present, download
if (!(Test-Path $filepath)){
write-host "Downloading gateway..."
$URL = "https://go.microsoft.com/fwlink/?LinkId=2116849&clcid=0x409"
$clnt = New-Object System.Net.WebClient
$clnt.DownloadFile($url,$filepath)
Write-Host "data gateway installer download complete" -ForegroundColor Green
 
}
else {
 
write-host "Located the gateway Installer binaries, moving on to install..."
}
 
# start the gateway installer
write-host "Beginning gateway install..." -nonewline
$Parms = " /Install /Quiet /Norestart /Logs log.txt"
$Prms = $Parms.Split(" ")
& "$filepath" $Prms | Out-Null
Write-Host "gateway installation complete" 

$WshShell = New-Object -COMObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$Home\Desktop\gateway.lnk")
$Shortcut.TargetPath = "C:\Program Files (x86)\Microsoft SQL Server Management Studio 20\Common7\IDE\gateway.exe"
$Shortcut.Save()
