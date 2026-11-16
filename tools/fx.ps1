# Helper: runs flutter with the correct PATH for this machine.
$env:Path = "C:\Windows\System32;C:\Windows;C:\Windows\System32\WindowsPowerShell\v1.0;D:\.android\flutter_windows_3.44.7-stable\flutter\bin;" + $env:Path
Set-Location D:\life\Company\Apps-Saas\study_nova\studynova
& "D:\.android\flutter_windows_3.44.7-stable\flutter\bin\flutter.bat" @args
