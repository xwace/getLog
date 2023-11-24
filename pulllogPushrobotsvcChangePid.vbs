sub pullLog()
	ws.run "cmd /k c: && cd "&desktopPath
	ws.run "adb pull /userdata/yx_user/business/log/" 'cmd /k e: && adb pull /userdata/yx_user/business/log/
end sub

sub pushsvc()
	ws.sendkeys("rm -rf /userdata/yx_user/business/log/*")
	ws.sendkeys("{ENTER}")
	wscript.sleep 4000
	ws.sendkeys("mkdir -p /userdata/yx_debug_bin")
	ws.sendkeys("{ENTER}")
	wscript.sleep 500
	ws.sendkeys("chmod 777 /userdata/yx_debug_bin/robot.svc&&ls /userdata/yx_debug_bin/")

	ws.run "cmd /k c: && cd "&desktopPath
	ws.run "adb push robot.svc /userdata/yx_debug_bin/",1
	wscript.sleep 3000
	'ws.run "taskkill /f /im cmd.exe",1

	wscript.sleep 500
	ws.appactivate("adb.exe")
	ws.sendkeys("{ENTER}")
	ws.sendkeys("reboot")
end sub

sub changePid()
	dim pid,uid,auth_key
	pid = InputBox("Enter the Pid: ")

	if pid <>"" then
		ws.sendkeys("sed -i 's/")
		ws.sendkeys("""ProductKey""")'ws.sendkeys(".*[$,]/""ProductKey"" : ""123"",/")
		ws.sendkeys(".*[$,]/""ProductKey"" : """)
		ws.sendkeys(pid &""" ,/")
		ws.sendkeys("' /userdata/yx_user/config/run/.sys.conf")
		ws.sendkeys("{ENTER}")
		wscript.sleep 1000
	end if

	uid = InputBox("Enter the uid")
	if uid <>"" then
		ws.sendkeys("sed -i 's/")
		ws.sendkeys("""TyUuid""")
		ws.sendkeys(".*[$,]/""TyUuid"" : """)
		ws.sendkeys(uid &""" ,/")
		ws.sendkeys("' /userdata/yx_user/config/run/.sys.conf")
		ws.sendkeys("{ENTER}")
	end if

	wscript.sleep 1000
	auth_key = InputBox("Enter the auth_key")
	if auth_key <>"" then
		ws.sendkeys("sed -i 's/")
		ws.sendkeys("""TyAuthKey""")
		ws.sendkeys(".*[$,]/""TyAuthKey"" : """)
		ws.sendkeys(auth_key &""" ,/")
		ws.sendkeys("' /userdata/yx_user/config/run/.sys.conf")
		ws.sendkeys("{ENTER}")
	end if

	wscript.sleep 1000
	ws.sendkeys("cat /userdata/yx_user/config/run/.sys.conf | egrep -i uuid\|authkey")
	ws.sendkeys("{ENTER}")

	set pid = Nothing
	set uid = Nothing
	set auth_key = Nothing
end sub

Dim ws,workMode
Set ws = CreateObject("WScript.shell")
desktopPath = ws.SpecialFolders("Desktop")

dim fso '先删除log再pull
set fso = CreateObject("Scripting.FileSystemObject")
if fso.folderExists(desktopPath&"\log") then
	fso.deleteFolder desktopPath&"\log"
end if
set fso = Nothing

'判断adb是否打开
Dim deviceName,reg,match
set ret = ws.Exec("adb devices")
deviceName = ret.stdOut.ReadAll()

'判断字符串是否包含device
'set reg=New RegExp
'reg.pattern="device"
'reg.Global=True
'set match=reg.Execute(deviceName)
'if match.count <= 1 then

if InStr(right(deviceName,11),"device")=False then
    WScript.Echo "Failed to open ADB!!!"
	WScript.Quit
    set ws = Nothing
	set ret = Nothing
	set deviceName = Nothing
	set reg=Nothing
	set match=Nothing
end if

'判断adb是否打开:method2
'if ws.run("adb shell",,true)>0 then
	'WScript.Echo "Failed to open adb!!!"
	'set ws = Nothing
	'WScript.Quit
'end if

set ret = Nothing
set deviceName = Nothing
set reg=Nothing
set match=Nothing

ws.run "adb shell",1 'ws.run "ssh root@10.10.35.212", 0, True
wscript.sleep 500
ws.sendkeys("root")
ws.sendkeys("{ENTER}")
wscript.sleep 500
ws.sendkeys("yx113322")
ws.sendkeys("{ENTER}")
wscript.sleep 500
ws.sendkeys("md5sum /home/robot/config/run/.sys_backup.conf>/tmp/md5sumnew.check")
ws.sendkeys("{ENTER}")
wscript.sleep 500

workMode=MsgBox("Pull the logs? Yes for pull, No for others!",vbYesNo)
if workMode = vbYes then
	pullLog
else

	workMode=MsgBox("Push the robot.svc or Change the uuid authkey? Yes for push, No for change pid!",vbYesNo)
	if workMode = vbYes then
		pushsvc
	else
		changePid
	end if

end if
set workMode=Nothing
set ws = Nothing
