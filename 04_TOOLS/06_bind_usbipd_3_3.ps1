$process = Start-Process `
    -FilePath "C:\PROGRA~1\usbipd-win\usbipd.exe" `
    -ArgumentList @(
        "bind",
        "--busid",
        "3-3",
        "--force"
    ) `
    -Verb RunAs `
    -Wait `
    -PassThru

Set-Content `
    -LiteralPath "E:\share\Jetson\usbipd-bind-3-3-result.txt" `
    -Value $process.ExitCode
