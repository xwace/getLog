@echo off
set latest_file=""
for /f "delims=" %%f in ('dir /b /o:d /a:-d "C:\Users\17300\Desktop\*"') do (
	if %%~zf GTR 1048576 (
		set latest_file=%%~nf%%~xf
		REM echo %%~nf%%~xf
		REM echo %%~tf
	)
)

set time_str=%time%
set hour=%time_str:~0,2%
set "minute=%time_str:~3,2%"
set /a "minute_left=minute-3"

REM 获取文件的时间
for %%F in ("%latest_file%") do set filedatetime=%%~tF
set filetime=%filedatetime:~11,5%
set file_hour=%filetime:~0,2%
set file_minute=%filetime:~3,2%

REM 去除首字母为0
set firstChar=%file_minute:~0,1%
if %firstChar% EQU 0 (
	set /a file_minute=%file_minute:~1%
)
set firstChar=%file_hour:~0,1%
if %firstChar% EQU 0 (
	set /a file_hour=%file_hour:~1%
)


if %hour% EQU %file_hour% (
	rem if %file_minute% GEQ %minute_left% if %file_minute% LEQ %minute% ( REM 保证修改的文件是三分钟内新下载的
		ren "C:\Users\17300\Desktop\%latest_file%" 2
		REM echo "Change the log name successfully!"
		echo "C:\Users\17300\Desktop\2"
	rem )
)