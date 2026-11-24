$process = Start-Process `
    -FilePath "msiexec.exe" `
    -ArgumentList @(
        "/i",
        "E:\share\Jetson\usbipd-win_5.3.0_x64.msi",
        "/qn",
        "/norestart"
    ) `
    -Verb RunAs `
    -Wait `
    -PassThru

Write-Output $process.ExitCode
