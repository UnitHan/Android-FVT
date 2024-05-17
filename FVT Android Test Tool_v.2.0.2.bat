@echo off
setlocal EnableDelayedExpansion
REM 배치 파일의 작성자와 수정자 정보
echo make by Byoungow Jeoung
echo edit by DanWon Han
echo create on Nov. 23, 2019
echo update on May. 17, 2024

rem Anyone can be updated when new functions implement.
:: Default Setting
rem FVT (Functional Verification Test)
title FVT Android Test Tool
color 03
mode con cols=90 lines=90

:FVT

echo ::::::::::::::::::::::::::::::::::::::::::::::::
echo          FVT Android Test Tool v2.0.2
echo ::::::::::::::::::::::::::::::::::::::::::::::::
echo :: 1. Connect ADB                             ::
echo :: 2. Test Information (Memory Infomation)    ::
echo :: 3. ADB STB Connect for IPTV                ::
echo :: 4. Log Collection (Logcat/Bootlog)         ::
echo :: 5. Log Collection (Bugreport)              ::
echo :: 6. APP PID confirmation                    ::
echo :: 7. Mobile App Performance Measurement      ::
echo :: 8. Battery Usage Information               ::
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
:: 8. Battery Usage Information
chcp 65001 > nul
CLS
echo ____________________________________________
echo Battery Usage Information
echo ____________________________________________

REM 앱의 패키지 이름 입력받기
set /p PACKAGE_NAME="앱의 패키지 이름을 입력하세요: "

:LOOP
REM 앱의 UID 가져오기
set "UID="
for /f "tokens=1 delims= " %%A in ('adb shell ps ^| findstr %PACKAGE_NAME%') do (
    set "UID=%%A"
    echo UID found: %%A
    goto UID_FOUND
)

echo %PACKAGE_NAME% 앱의 UID를 가져올 수 없습니다.
goto WAIT

:UID_FOUND
REM UID에서 언더바(_) 제거
set "UID=!UID:_=!"
echo Processed UID: !UID!

REM 앱이 설치되어 있는지 확인
if not defined UID (
    echo %PACKAGE_NAME% 앱이 설치되어 있지 않습니다.
    goto WAIT
)

REM 앱의 배터리 소모량 정보 초기화
set "BATTERY_USAGE="

REM 앱의 배터리 소모량 정보 가져오기
for /f "tokens=*" %%B in ('adb shell dumpsys batterystats --charged ^| findstr /C:" UID !UID!:"') do (
    if "%%B" neq "" (
        set "BATTERY_USAGE=%%B"
    )
)

REM 값이 존재하는 경우에만 출력
if defined BATTERY_USAGE (
    echo %PACKAGE_NAME% 앱의 배터리 소모량 정보: !BATTERY_USAGE!
) else (
    echo %PACKAGE_NAME% 앱의 배터리 소모량 정보를 가져올 수 없습니다.
)

:WAIT
REM 5초 대기 후 다시 조회
timeout /t 5 >nul
goto LOOP

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

:END
exit /b
