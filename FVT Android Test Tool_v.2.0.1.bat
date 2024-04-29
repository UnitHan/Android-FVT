@echo off
setlocal EnableDelayedExpansion
REM 배치 파일의 작성자와 수정자 정보
echo make by Byoungow Jeoung
echo edit by DanWon Han
echo create on Nov. 23, 2019
echo update on Mar. 04, 2024

rem Anyone can be updated when new functions implement.
:: Default Setting
rem FVT (Functional Verification Test)
title FVT Android Test Tool
color 03
mode con cols=90 lines=90

:FVT

echo ::::::::::::::::::::::::::::::::::::::::::::::::
echo          FVT Android Test Tool v2.0.1
echo ::::::::::::::::::::::::::::::::::::::::::::::::
echo :: 1. Connect ADB                             ::
echo :: 2. Test Information (Memory Infomation)    ::
echo :: 3. ADB STB Connect for IPTV                ::
echo :: 4. Log Collection (Logcat/Bootlog)         ::
echo :: 5. Log Collection (Bugreport)              ::
echo :: 6. APP PID confirmation                    ::
echo :: 7. Mobile App Performance Measurement      ::
echo :: 8. Screen Recording (3 min)                ::
echo :: 9. Device Reboot                           ::
echo :: 0. Exit                                    ::
echo ::::::::::::::::::::::::::::::::::::::::::::::::

set /p code= What do you want?

if %code%==1 GOTO 1
if %code%==2 GOTO 2
if %code%==3 GOTO 3
if %code%==4 GOTO 4
if %code%==5 GOTO 5
if %code%==6 GOTO 6
if %code%==7 GOTO 7
if %code%==8 GOTO 8
if %code%==9 GOTO 9
if %code%==0 GOTO END

goto FVT

:1
:: 1. Connect ADB
CLS 
echo ____________________________________________
echo Turn on the USB debbugging...
adb kill-server
adb start-server
echo Waiting for device connection...
echo Laptop connected with device
echo Device connected to the PC via ADB

pause
GOTO FVT

:2
:: 2. Test Information (Memory Infomation) 
CLS
echo ____________________________________________
echo ::::: FVT Test Information :::::
echo ____________________________________________
echo Android Version (ex.POS, QOS)
adb shell getprop ro.build.version.release
echo ____________________________________________
echo Test CSC Sales Code
adb shell getprop ro.csc.sales_code	

echo ____________________________________________
echo Test Carrier ID
adb shell getprop ro.boot.carrierid

echo ____________________________________________
echo Device Memory Information
adb shell cat proc/meminfo

echo ____________________________________________
echo Device File size
adb shell df -h

echo ____________________________________________

pause
GOTO FVT

:3
:: 3. ADB STB Connect for IPTV
CLS

@echo off
chcp 65001 > nul


REM 현재 사용 중인 Wi-Fi SSID 확인
for /f "tokens=2 delims=:" %%a in ('netsh wlan show interfaces ^| findstr /c:"SSID"') do (
    set "SSID=%%a"
    goto :SSIDFound
)
:SSIDFound

REM 현재 사용 중인 Wi-Fi SSID 출력
echo 현재 사용 중인 Wi-Fi SSID: !SSID!

REM 사용자로부터 셋탑박스의 IP 주소를 입력받습니다.
set /p STB_IP=셋탑박스의 IP 주소를 입력하세요: 

REM 현재 Wi-Fi 네트워크에 연결되어 있는지 확인합니다.
for /f "tokens=3" %%i in ('netsh wlan show interfaces ^| findstr /r "^SSID "') do (
    if "%%i"=="같은_Wi-Fi_망의_SSID" (
        REM 같은 Wi-Fi 망을 사용하는 경우에만 ADB로 연결합니다.
        adb connect %STB_IP%
        
        REM 연결 상태를 확인하고 처리합니다.
        if errorlevel 1 (
            echo ADB로 연결할 수 없습니다. FVT 메인 화면으로 이동합니다.
            goto :FVT
        ) else (
            echo ADB로 셋탑박스에 성공적으로 연결되었습니다.
            pause
            exit /b
        )
    )
)

adb connect %STB_IP%

REM 결과를 출력하고 스크립트를 종료합니다.
echo ADB 연결 결과를 확인하세요.

pause
GOTO FVT

:4
:: 4. Log Collection (Logcat/Bootlog)
CLS
cd %USERPROFILE%
echo ____________________________________________
echo Now Log is gathering...
echo Save Location: "%USERPROFILE%\BVT_Error_bootupLog.log"
echo If you want to terminate log collection, press Ctrl + C.

adb logcat -b main -b radio -b system -v threadtime > BVT_Error_bootupLog.log

echo Log collection complete.

pause
GOTO FVT

:5
:: 5. Log Collection (Bugreport)   
CLS
cd %USERPROFILE%
echo ____________________________________________
echo Now Log is gathering...
echo Save Location: "%USERPROFILE%\bugreport.log"
echo Bug reports take a long time. Please wait...

adb bugreport %USERPROFILE%\bugreport.log

echo The log saved on "%USERPROFILE%\bugreport.log"

pause
GOTO FVT

:6
:: 6. APP PID confirmation
CLS

REM APK 파일의 패키지명 입력
set /p package_name=Enter the package name of the APK: 

REM 입력한 패키지명이 비어 있는지 확인
if "%package_name%"=="" (
    echo Please enter a package name.
    pause
    GOTO FVT
)

REM PID 추출
for /f "tokens=2" %%P in ('adb shell ps ^| findstr "%package_name%"') do (
    set pid=%%P
)

REM PID가 비어 있는지 확인
if "%pid%"=="" (
    echo PID not found for package %package_name%.
) else (
    REM PID 출력
    echo PID: %pid%
)

pause
REM Instead of going back to the main menu, let's loop back to the option selection menu.
GOTO FVT

:7
:: 7. Check App Status by Package Name
CLS

REM 앱의 패키지명 입력
set /p package_name=Enter the package name of the app: 

REM 입력한 패키지명이 비어 있는지 확인
if "%package_name%"=="" (
    echo Please enter a package name.
    pause
    GOTO FVT
)

REM 패키지명을 이용하여 PID를 찾음
for /f "tokens=2" %%P in ('adb shell ps ^| findstr "%package_name%"') do (
    set pid=%%P
)

REM PID가 비어 있는지 확인
if "%pid%"=="" (
    echo PID not found for package %package_name%.
) else (
    REM top 명령어 실행
    adb shell top -d 1 -p %pid%
)

pause
GOTO FVT

:8
:: 8. Screen Recording  
CLS
echo ____________________________________________
echo Now Screen Recording...
echo Save Location: /sdcard/Download)
echo If you stop the Recording, Please click the Ctrl c butoon and terminated the batch job (Yes)

adb shell screenrecord /sdcard/Download/BTI_FVT_NJ_ScreenRecording.mp4

pause
GOTO FVT

:9
:: 9. Device Reboot 
CLS
echo ____________________________________________
echo Are you really reboot the device?
echo If you press the any key, device will be restart...
pause

adb reboot

pause
GOTO FVT


::  :6
::  :: 6. TCP DUMP log (PCAP)
::  CLS
::  cd %USERPROFILE%
::  echo ____________________________________________
::  echo Now Log is gathering...
::  echo Save Location: "Device (/sdcard/Download.pcap)"
::  echo If you finish the tcpdump, Please click the Ctrl c butoon and terminated the batch job (Yes)
::  echo ____________________________________________
::  echo tcpdump option: tcpdump -p -vv -s 0 -i any -w
::  
::  echo adb push tcpdump /data/local/tmp
::  echo adb shell tcpdump -p -vv -s 0 -i any -w /sdcard/Download.pcap
::  :7
:: 7. Setup Wizard SKIP (only ENG mode)
:: CLS
:: echo ____________________________________________
:: echo Now, system starts the skip process...
:: echo This Menu allowed only ENG binary
:: 
:: adb remount
:: adb shell pm disable com.google.android.setupwizard
:: adb shell pm disable com.sec.android.app.SecSetupWizard
:: adb shell settings put global device_provisioned 1
:: adb shell settings put secure user_setup_complete 1
:: adb shell setprop persist.sys.setupwizard FINISH
:: 
:: pause
:: GOTO FVT


:: @echo off
:: setlocal

:: REM Check if adb is installed and accessible
:: adb version >nul 2>&1
:: if %errorlevel% neq 0 (
::     echo ADB is not installed or accessible.
::     exit /b 1
:: )
:: 
:: REM Check if the package name is provided as argument
:: if "%~1"=="" (
::     echo Please provide the package name of the app.
::     exit /b 1
:: )
:: 
:: REM Set the package name and time stamp
:: set packageName=%~1
:: set timeStamp=%DATE:/=-%_%TIME::=-%
:: 
:: REM Remove milliseconds from the time stamp
:: for /f "tokens=1-4 delims=,.: " %%a in ("%timeStamp%") do set timeStamp=%%a-%%b-%%c_%%d
:: 
:: REM Set the log file path
:: set logFilePath=%USERPROFILE%\%packageName%_%timeStamp%.txt
:: 
:: REM Run adb logcat and save output to log file
:: adb logcat -d | findstr %packageName% > "%logFilePath%"
:: 
:: echo Logcat output saved to: %logFilePath%
:: exit /b 0

