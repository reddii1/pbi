# Set file and folder path for SSMS installer .exe
$folderpath="c:\windows\temp"
$filepath="$folderpath\SSMS-Setup-ENU.exe"
 
#If SSMS not present, download
if (!(Test-Path $filepath)){
write-host "Downloading SSMS..."
$URL = "https://aka.ms/ssmsfullsetup"
$clnt = New-Object System.Net.WebClient
$clnt.DownloadFile($url,$filepath)
Write-Host "SSMS installer download complete" -ForegroundColor Green
 
}
else {
 
write-host "Located the SQL SSMS Installer binaries, moving on to install..."
}
 
# start the SSMS installer
write-host "Beginning SSMS 2016 install..." -nonewline
$Parms = " /Install /Quiet /Norestart /Logs log.txt"
$Prms = $Parms.Split(" ")
& "$filepath" $Prms | Out-Null
Write-Host "SSMS installation complete" 

$WshShell = New-Object -COMObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$Home\Desktop\SSMS.lnk")
$Shortcut.TargetPath = "C:\Program Files (x86)\Microsoft SQL Server Management Studio 20\Common7\IDE\Ssms.exe"
$Shortcut.Save()
