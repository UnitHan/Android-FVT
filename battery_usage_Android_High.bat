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
    echo No devices connected. Please connect a device via USB and try again.
    pause
    goto :EOF
)

echo Device connected: %device%

REM 배터리 용량 확인 및 출력
adb shell dumpsys batterystats | findstr "Capacity" > battery_capacity.txt
for /f "tokens=2 delims=: " %%a in ('findstr "Capacity" battery_capacity.txt') do (
    set "battery_capacity=%%a"
)
echo Battery Capacity: %battery_capacity% mAh

REM TCP/IP 모드 활성화
adb tcpip 5555
echo ADB TCP/IP mode enabled on port 5555.

REM 5초 대기
timeout /t 5 > nul

REM IP 주소 확인
adb shell ip -f inet addr show wlan0 > ip_info.txt
set "ip_address="
for /f "tokens=2 delims= " %%i in ('findstr /r "inet " ip_info.txt') do (
    set "ip_address=%%i"
    goto :IP_FOUND
)

:IP_FOUND
REM IP 주소에서 슬래시와 그 뒤의 숫자 제거
for /f "tokens=1 delims=/" %%a in ("%ip_address%") do (
    set "ip_address=%%a"
)

if "%ip_address%"=="" (
    echo Failed to retrieve IP address.
    pause
    goto :EOF
)

echo Device IP address: %ip_address%

REM 5초 대기
timeout /t 5 > nul

REM WiFi를 통해 ADB 연결
adb connect %ip_address%:5555
if %errorlevel% neq 0 (
    echo Failed to connect to device via WiFi. Please check the IP address and try again.
    pause
    goto :EOF
)

echo Successfully connected to device via WiFi at %ip_address%:5555

REM 연결 확인
adb devices
echo 연결 중인 USB 케이블을 제거해주세요.

echo ____________________________________________
echo ::::: Mobile App Battery Usage Measurement :::::
echo ____________________________________________

echo Please enter the package name of the app:
set /p package_name=

if "%package_name%"=="" (
    echo No package name entered. Returning to main menu.
    pause
    goto :EOF
)

REM 배터리 통계 초기화 및 설정
adb shell dumpsys batterystats --enable full-wake-history
adb shell dumpsys batterystats --reset

REM UID 찾기
set "uid="
for /f "tokens=1" %%i in ('adb shell ps ^| findstr %package_name%') do (
    set "uid=%%i"
    goto :UID_FOUND
)

:UID_FOUND
if "%uid%"=="" (
    echo Failed to retrieve UID for package %package_name%.
    pause
    goto :EOF
)

REM 언더바 제거
set "uid=%uid:_=%"

echo UID for package %package_name% is %uid%

REM 로그 파일 설정
set "log_file=battery_usage_%package_name%_%date:~-4%%date:~4,2%%date:~7,2%_%time:~0,2%%time:~3,2%%time:~6,2%.txt"

REM 배터리 사용량 모니터링 시작
echo Monitoring battery usage for package: %package_name% (UID: %uid%)...
echo Start Time: %date% %time%
echo Start Time: %date% %time% >> %log_file%
set "start_time=%time%"

:BATTERY_MONITOR_LOOP
REM 배터리 사용량 확인 및 로그 기록
set "current_time=%date% %time%"
adb shell dumpsys batterystats --charged %package_name% | findstr "Uid %uid%" > temp_battery_stats.txt

REM 배터리 사용량 분석
set "battery_usage=0"
for /f "tokens=3 delims=: " %%a in ('findstr /c:"UID %uid%:" temp_battery_stats.txt') do (
    for /f "tokens=1 delims=( " %%b in ("%%a") do (
        set "battery_usage=%%b"
    )
    goto :USAGE_FOUND
)

:USAGE_FOUND
REM 배터리 사용량 출력 및 기록
echo !current_time! - !package_name! 테스트 앱의 배터리 사용량 : !battery_usage! mAh
echo !current_time! - !package_name! 테스트 앱의 배터리 사용량 : !battery_usage! mAh >> %log_file%

REM 경과 시간 계산 및 기록
call :CalculateElapsedTime_BATTERY
echo !current_time! - 테스트 경과 시간 : !elapsed_time!
echo !current_time! - 테스트 경과 시간 : !elapsed_time! >> %log_file%

echo ----------------------------------------
echo ---------------------------------------- >> %log_file%

REM 5초 대기
timeout /t 5 > nul

REM 72시간(259200초) 체크
if !total_elapsed_seconds! GEQ 259200 goto :EOF

goto BATTERY_MONITOR_LOOP

:CalculateElapsedTime_BATTERY
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

REM 전체 경과 시간 계산
set /a total_elapsed_seconds=elapsed_hours * 3600 + elapsed_mins * 60 + elapsed_secs
goto :eof

:EOF
