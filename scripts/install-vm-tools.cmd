@echo off
echo =====================================================
echo Installing VMware Tools silently and forcing reboot...
echo =====================================================

:: Detect VMware Tools installer drive automatically
set "VMTOOLSDRIVE="
for %%d in (D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    if exist "%%d:\setup64.exe" (
        set "VMTOOLSDRIVE=%%d:"
        goto :found
    )
)

echo [ERROR] VMware Tools installer not found on any drive.
exit /b 1

:found
echo Found VMware Tools on %VMTOOLSDRIVE%
cd /d %VMTOOLSDRIVE%

:: Install silently (ignore reboot flag)
start /wait setup64.exe /S /v "/qn REBOOT=R"

:: Wait a bit in case background processes still run
timeout /t 20 /nobreak >nul

echo Forcing system reboot...
shutdown /r /t 5 /f

exit 0
