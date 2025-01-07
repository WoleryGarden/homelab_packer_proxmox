Write-Host "Installing BgInfo..."
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
New-Item -ItemType directory -Path "C:\Program Files\BGInfo"
Invoke-WebRequest https://download.sysinternals.com/files/BGInfo.zip -OutFile "C:\Program Files\BGInfo\bginfo.zip"
Expand-Archive "C:\Program Files\BGInfo\bginfo.zip" -DestinationPath "C:\Program Files\BGInfo"
Copy-Item  "D:\BTServer.bgi" "C:\Program Files\BGInfo\BTServer.bgi"
$RegistryKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
$RegistryEntry = "RunBgInfo"
$Command = '"C:\Program Files\BGInfo\bginfo64.exe" "C:\Program Files\BGInfo\BTServer.bgi" /timer:0 /silent /nolicprompt'
Set-ItemProperty -Path $RegistryKey -Name $RegistryEntry -Value $Command
cmd /c $Command
"Done installing BgInfo. Exit code: $LASTEXITCODE" | Write-Host
