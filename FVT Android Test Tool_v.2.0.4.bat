@echo off
setlocal EnableDelayedExpansion

REM 배치 파일의 작성자와 수정자 정보
echo make by Byoungow Jeoung
echo edit by DanWon Han
echo create on Nov. 23, 2019
echo update on Jun. 29, 2024

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
echo :: 7. Mobile App Memory Measurement           ::
echo :: 8. Mobile App CPU Monitoring               ::
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
echo Android ID
adb shell settings get secure android_id

pause
GOTO FVT

:3
:: 3. ADB STB Connect for IPTV
CLS
echo ____________________________________________
echo Connect to ADB STB for IPTV
adb connect 192.168.1.2:5555

pause
GOTO FVT

:4
:: 4. Log Collection (Logcat/Bootlog)
CLS
echo ____________________________________________
echo Collecting logcat and bootlog...
adb logcat -d > logcat.txt
adb shell cat /proc/last_kmsg > bootlog.txt

pause
GOTO FVT

:5
:: 5. Log Collection (Bugreport)
CLS
echo ____________________________________________
echo Collecting bugreport...
adb bugreport > bugreport.zip

pause
GOTO FVT

:6
:: 6. APP PID confirmation
CLS
echo ____________________________________________
echo Please enter the package name of the app:
set /p package_name=

if "%package_name%"=="" (
    echo No package name entered. Returning to main menu.
    pause
    goto FVT
)

adb shell ps | findstr %package_name%

pause
GOTO FVT

:7
:: 7. Mobile App Memory Measurement
CLS
call :MemoryMeasurement
pause
GOTO FVT

:8
:: 8. Mobile App CPU Monitoring
CLS
call :CPUMonitoring
pause
GOTO FVT

:9
:: 9. Device Reboot
CLS
echo ____________________________________________
echo Rebooting device...
adb reboot

pause
GOTO FVT

:END
exit

:MemoryMeasurement
@echo off
chcp 65001 > nul
CLS
setlocal enabledelayedexpansion

REM adb 경로 설정 (필요한 경우 수정)
set "ADB_PATH=C:\path\to\adb"
set "PATH=%ADB_PATH%;%PATH%"

:CHECK_DEVICE
REM 디바이스 연결 상태 확인
adb devices | findstr /v "List of devices attached" | findstr /v "^$" > connected_devices.txt
for /f "delims=" %%d in (connected_devices.txt) do (
    set "device=%%d"
)

if not defined device (
    echo No devices connected. Please connect a device and try again.
    pause
    goto FVT
)

echo Device connected: %device%

echo ____________________________________________
echo ::::: Mobile App Performance Measurement :::::
echo ____________________________________________

echo Please enter the package name of the app:
set /p package_name=

if "%package_name%"=="" (
    echo No package name entered. Returning to main menu.
    pause
    goto FVT
)

REM adb 경로 확인
adb version > nul 2>&1
if %errorlevel% neq 0 (
    echo adb not found or not recognized as a command. Please check adb path.
    pause
    goto FVT
)

REM 디바이스에서 안드로이드 버전 가져오기
for /f "tokens=*" %%v in ('adb shell getprop ro.build.version.release') do (
    set android_version=%%v
)

echo Android Version: !android_version!

REM 패키지명을 이용하여 PID와 이름을 찾음
set "pid_list="
set "index=1"
for /f "tokens=2,9" %%P in ('adb shell ps ^| findstr "%package_name%"') do (
    echo !index!. PID: %%P, Name: %%Q
    set "pid_list=!pid_list!%%P=%%Q;"
    set /a index+=1
)

if "!pid_list!"=="" (
    echo No PIDs found for package %package_name%.
    pause
    goto FVT
)

echo Please select the PID to monitor (enter the number):
set /p pid_choice=

set "pid="
set "selected_name="
set "index=1"
for %%P in (!pid_list!) do (
    if !index! equ !pid_choice! (
        for /f "tokens=1,2 delims==" %%A in ("%%P") do (
            set "pid=%%A"
            set "selected_name=%%B"
        )
    )
    set /a index+=1
)

if "!pid!"=="" (
    echo Invalid selection.
    pause
    goto FVT
)

:START_MONITORING
echo Monitoring memory usage for PID: !pid!, Name: !selected_name!...
echo Start Time: %date% %time%
set "start_time=%time%"
set "log_file=memory_usage_%package_name%_%date:~-4%%date:~4,2%%date:~7,2%_%time:~0,2%%time:~3,2%%time:~6,2%.txt"
echo Start Time: %date% %time% >> !log_file!
set "total_elapsed_seconds=0"

:MEM_MONITOR_LOOP
REM 디바이스 연결 상태 확인
adb devices | findstr /v "List of devices attached" | findstr /v "^$" > connected_devices.txt
for /f "delims=" %%d in (connected_devices.txt) do (
    set "current_device=%%d"
)

if not "%device%"=="%current_device%" (
    echo Device changed. Restarting monitoring.
    goto CHECK_DEVICE
)

REM 안드로이드 버전에 따라 다른 명령어 실행
if !android_version! LSS 10 (
    adb shell dumpsys meminfo %package_name% > meminfo_output.txt
    set "meminfo="
    for /f "tokens=2 delims=: " %%a in ('findstr /c:"TOTAL" meminfo_output.txt') do (
        set "meminfo=%%a"
        goto :MEMINFO_FOUND
    )
) else (
    set "meminfo="
    for /f "delims=" %%a in ('adb shell dumpsys meminfo %package_name% ^| findstr /c:"TOTAL PSS"') do (
        set "meminfo=%%a"
        goto :MEMINFO_FOUND
    )
)

if "!meminfo!"=="" (
    echo Meminfo not found for package %package_name%. Checking adb status and retrying...
    adb get-state > nul 2>&1
    if %errorlevel% neq 0 (
        echo adb is not in a valid state. Please check device connection.
        pause
        goto MEM_MONITOR_LOOP
    )
    timeout /t 10 > nul
    goto MEM_MONITOR_LOOP
)

:MEMINFO_FOUND
REM Extracting TOTAL PSS or PSS TOTAL value from meminfo
if !android_version! LSS 10 (
    set total_pss_kb=!meminfo!
) else (
    for /f "tokens=3" %%a in ("!meminfo!") do (
        set total_pss_kb=%%a
    )
)

REM Verify that total_pss_kb is a valid number
for /f "delims=0123456789" %%b in ("!total_pss_kb!") do (
    echo Invalid number detected: !total_pss_kb!
    pause
    goto FVT
)

REM Converting from KB to MB
set /a total_pss_mb=!total_pss_kb! / 1024

set available_mem_kb=0
set available_mem_mb=0
for /f "tokens=1-2" %%a in ('adb shell cat /proc/meminfo ^| findstr "MemAvailable:"') do (
    set /a available_mem_kb=%%b
    set /a available_mem_mb=!available_mem_kb! / 1024
)

REM 경과 시간 계산
call :CalculateElapsedTime_MEM

set "current_time=%date% %time%"
echo !current_time! - !package_name! 테스트 앱의 메모리 사용량 : !total_pss_mb! MB
echo !current_time! - !package_name! 테스트 앱의 메모리 사용량 : !total_pss_mb! MB >> !log_file!
echo !current_time! - 단말 시스템의 잔여 메모리량 : !available_mem_mb! MB
echo !current_time! - 단말 시스템의 잔여 메모리량 : !available_mem_mb! MB >> !log_file!
echo !current_time! - 테스트 경과 시간 : !elapsed_time!
echo !current_time! - 테스트 경과 시간 : !elapsed_time! >> !log_file!
echo ----------------------------------------
echo ---------------------------------------- >> !log_file!

timeout /t 5 > nul

REM 72시간(259200초) 체크
call :CalculateTotalElapsedSeconds
if !total_elapsed_seconds! GEQ 259200 goto FVT

goto MEM_MONITOR_LOOP

:CalculateElapsedTime_MEM
set "end_time=%time%"

REM 시간 계산 (start_time과 end_time의 차이 계산)
for /f "tokens=1-4 delims=:," %%a in ("%start_time%") do (
    set start_hours=%%a
    set start_mins=%%b
    set start_secs=%%c
    set start_ms=%%d
)

for /f "tokens=1-4 delims=:," %%a in ("%end_time%") do (
    set end_hours=%%a
    set end_mins=%%b
    set end_secs=%%c
    set end_ms=%%d
)

REM 밀리초를 고려한 시간 차이 계산
set /a elapsed_ms = end_ms - start_ms
set /a elapsed_secs = end_secs - start_secs
set /a elapsed_mins = end_mins - start_mins
set /a elapsed_hours = end_hours - start_hours

if !elapsed_ms! lss 0 (
    set /a elapsed_ms += 1000
    set /a elapsed_secs -= 1
)

if !elapsed_secs! lss 0 (
    set /a elapsed_secs += 60
    set /a elapsed_mins -= 1
)

if !elapsed_mins! lss 0 (
    set /a elapsed_mins += 60
    set /a elapsed_hours -= 1
)

if !elapsed_hours! lss 0 (
    set /a elapsed_hours += 24
)

set elapsed_time=!elapsed_hours!:!elapsed_mins!:!elapsed_secs!,!elapsed_ms!
goto :eof

:CalculateTotalElapsedSeconds
set /a total_elapsed_seconds=!elapsed_hours! * 3600 + !elapsed_mins! * 60 + !elapsed_secs!
goto :eof

GOTO FVT

:CPUMonitoring
@echo off
chcp 65001 > nul
CLS
setlocal enabledelayedexpansion

REM adb 경로 설정 (필요한 경우 수정)
set "ADB_PATH=C:\path\to\adb"
set "PATH=%ADB_PATH%;%PATH%"

:CHECK_DEVICE_CPU
REM 디바이스 연결 상태 확인
adb devices | findstr /v "List of devices attached" | findstr /v "^$" > connected_devices_cpu.txt
for /f "delims=" %%d in (connected_devices_cpu.txt) do (
    set "device=%%d"
)

if not defined device (
    echo No devices connected. Please connect a device and try again.
    pause
    goto FVT
)

echo Device connected: %device%

echo ____________________________________________
echo ::::: Mobile App CPU Monitoring ::::::
echo ____________________________________________

echo Please enter the package name of the app:
set /p package_name=

if "%package_name%"=="" (
    echo No package name entered. Returning to main menu.
    pause
    goto FVT
)

REM adb 경로 확인
adb version > nul 2>&1
if %errorlevel% neq 0 (
    echo adb not found or not recognized as a command. Please check adb path.
    pause
    goto FVT
)

REM 디바이스에서 안드로이드 버전 가져오기
for /f "tokens=*" %%v in ('adb shell getprop ro.build.version.release') do (
    set android_version=%%v
)

echo Android Version: !android_version!

REM 패키지명을 이용하여 PID와 이름을 찾음
set "pid_list="
set "index=1"
for /f "tokens=2,9" %%P in ('adb shell ps ^| findstr "%package_name%"') do (
    echo !index!. PID: %%P, Name: %%Q
    set "pid_list=!pid_list!%%P=%%Q;"
    set /a index+=1
)

if "!pid_list!"=="" (
    echo No PIDs found for package %package_name%.
    pause
    goto FVT
)

echo Please select the PID to monitor (enter the number):
set /p pid_choice=

set "pid="
set "selected_name="
set "index=1"
for %%P in (!pid_list!) do (
    if !index! equ !pid_choice! (
        for /f "tokens=1,2 delims==" %%A in ("%%P") do (
            set "pid=%%A"
            set "selected_name=%%B"
        )
    )
    set /a index+=1
)

if "!pid!"=="" (
    echo Invalid selection.
    pause
    goto FVT
)

:START_MONITORING_CPU
echo Monitoring CPU usage for PID: !pid!, Name: !selected_name!...
echo Start Time: %date% %time%
set "start_time=%time%"
set "log_file=cpu_usage_%package_name%_%date:~-4%%date:~4,2%%date:~7,2%_%time:~0,2%%time:~3,2%%time:~6,2%.txt"
echo Start Time: %date% %time% >> !log_file!
set "total_elapsed_seconds=0"

:CPU_MONITOR_LOOP
REM 디바이스 연결 상태 확인
adb devices | findstr /v "List of devices attached" | findstr /v "^$" > connected_devices_cpu.txt
for /f "delims=" %%d in (connected_devices_cpu.txt) do (
    set "current_device=%%d"
)

if not "%device%"=="%current_device%" (
    echo Device changed. Restarting monitoring.
    goto CHECK_DEVICE_CPU
)

REM top 명령어를 이용하여 CPU 사용량 측정
set "cpu_usage="
for /f "tokens=9" %%a in ('adb shell top -b -n 1 -p !pid! ^| findstr "!pid!"') do (
    set "cpu_usage=%%a"
)

if "!cpu_usage!"=="" (
    echo CPU usage not found for PID !pid!.
    adb kill-server
    adb start-server
    echo Restarting adb server...
    timeout /t 10 > nul
    goto CPU_MONITOR_LOOP
)

REM 경과 시간 계산
call :CalculateElapsedTime_CPU

set "current_time=%date% %time%"
echo !current_time! - !package_name! 테스트 앱의 CPU 사용량 : !cpu_usage!%%
echo !current_time! - 테스트 경과 시간 : !elapsed_time!

echo !current_time! - !package_name! 테스트 앱의 CPU 사용량 : !cpu_usage!%% >> !log_file!
echo !current_time! - 테스트 경과 시간 : !elapsed_time! >> !log_file!
echo ----------------------------------------
echo ---------------------------------------- >> !log_file!

timeout /t 5 > nul

REM 72시간(259200초) 체크
call :CalculateTotalElapsedSeconds
if !total_elapsed_seconds! GEQ 259200 goto FVT

goto CPU_MONITOR_LOOP

:CalculateElapsedTime_CPU
set "end_time=%time%"

REM 시간 계산 (start_time과 end_time의 차이 계산)
for /f "tokens=1-4 delims=:," %%a in ("%start_time%") do (
    set start_hours=%%a
    set start_mins=%%b
    set start_secs=%%c
    set start_ms=%%d
)

for /f "tokens=1-4 delims=:," %%a in ("%end_time%") do (
    set end_hours=%%a
    set end_mins=%%b
    set end_secs=%%c
    set end_ms=%%d
)

REM 밀리초를 고려한 시간 차이 계산
set /a elapsed_ms = end_ms - start_ms
set /a elapsed_secs = end_secs - start_secs
set /a elapsed_mins = end_mins - start_mins
set /a elapsed_hours = end_hours - start_hours

if !elapsed_ms! lss 0 (
    set /a elapsed_ms += 1000
    set /a elapsed_secs -= 1
)

if !elapsed_secs! lss 0 (
    set /a elapsed_secs += 60
    set /a elapsed_mins -= 1
)

if !elapsed_mins! lss 0 (
    set /a elapsed_mins += 60
    set /a elapsed_hours -= 1
)

set /a elapsed_seconds=elapsed_hours * 3600 + elapsed_mins * 60 + elapsed_secs
set /a display_hours=elapsed_seconds / 3600
set /a display_mins=(elapsed_seconds %% 3600) / 60
set /a display_secs=elapsed_seconds %% 60

set "elapsed_time=%display_hours%:%display_mins%:%display_secs%,!elapsed_ms!"
goto :eof

:CalculateTotalElapsedSeconds
set /a total_elapsed_seconds=!elapsed_hours! * 3600 + !elapsed_mins! * 60 + !elapsed_secs!
goto :eof

GOTO FVT
