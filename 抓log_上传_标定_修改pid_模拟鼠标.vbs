####################################################1.修改PID
Dim ws
Set ws = CreateObject("WScript.shell")
ws.run "adb shell"
wscript.sleep 500
ws.sendkeys("root")
ws.sendkeys("{ENTER}")
wscript.sleep 500
ws.sendkeys("123")
ws.sendkeys("{ENTER}")
wscript.sleep 500
ws.sendkeys("md5sum /home/robot/config/run/.sys_backup.conf>/tmp/md5sumnew.check")
ws.sendkeys("{ENTER}")

dim pid,uid,auth_key
pid = InputBox("Enter the Pid: ")
wscript.sleep 500
ws.sendkeys("sed -i 's/")
ws.sendkeys("""ProductKey""")
'ws.sendkeys(".*[$,]/""ProductKey"" : ""123"",/")
ws.sendkeys(".*[$,]/""ProductKey"" : """)
ws.sendkeys(pid &""" ,/")
ws.sendkeys("' /userdata/yx_user/config/run/.sys.conf")
ws.sendkeys("{ENTER}")
wscript.sleep 1000

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
ws.sendkeys("cd /userdata/yx_user/config/run/ && cat .sys.conf")
ws.sendkeys("{ENTER}")


####################################################2.标定
dim fso,Project,psw,calPath,resultPath
'Project = "JDM"
'psw = "yx113322"
Project = "ZY2X"
psw = "123"
calPath = "E:\wdh\huanchuang\calibration\"&Project&"\xwCal"
resultPath = "E:\wdh\huanchuang\calibration\"&Project&"\xwResult"

'先删除log再pull
set fso = CreateObject("Scripting.FileSystemObject")
if fso.folderExists("E:\wdh\huanchuang\calibration\"&Project&"\xwCal\1") then
	fso.DeleteFile "E:\wdh\huanchuang\calibration\"&Project&"\xwCal\*"
	fso.DeleteFolder "E:\wdh\huanchuang\calibration\"&Project&"\xwCal\1"
	fso.DeleteFolder "E:\wdh\huanchuang\calibration\"&Project&"\xwCal\2"
	on error resume next
end if

Dim ws
Set ws = CreateObject("WScript.shell")
ws.run "adb shell"
wscript.sleep 500
ws.sendkeys("root")
ws.sendkeys("{ENTER}")
wscript.sleep 500
ws.sendkeys(psw)
ws.sendkeys("{ENTER}")
wscript.sleep 500
ws.sendkeys("md5sum /home/robot/config/run/.sys_backup.conf>/tmp/md5sumnew.check")
ws.sendkeys("{ENTER}")
wscript.sleep 500

'删除扫地机log
ws.sendkeys("rm -rf /userdata/yx_user/business/txt/1/* /userdata/yx_user/business/txt/2/*")
ws.sendkeys("{ENTER}")
wscript.sleep 4000

'开始清扫，抓取线激光数据+包含俯仰角的log_robot
InputBox("start the robot")

ws.run "cmd /k e: && cd \wdh\huanchuang\calibration\"&Project&"\xwCal && adb pull /userdata/yx_user/business/txt/1"
wscript.sleep 1500
ws.sendkeys("adb pull /userdata/yx_user/business/txt/2")
ws.sendkeys("{ENTER}")
wscript.sleep 1500
ws.sendkeys("adb pull /userdata/yx_user/business/log/log_robot")
'on error resume next
ws.sendkeys("{ENTER}")
wscript.sleep 1000

ws.sendkeys "dir E:\wdh\huanchuang\calibration\"&Project&"\xwCal\1 /b > "&calPath&"\filename1.txt" REM 读取所有文件并存放文件名到filename1.txt中
ws.sendkeys("{ENTER}")

wscript.sleep 1000
path=calPath&"\filename1.txt"
Set A=fso.OpenTextFile(path,1)
For i=1 To 2
	A.ReadLine
Next
line=A.ReadLine'线激光文件名
ws.sendkeys "move "&calPath&"\1\"&line&" "&calPath
ws.sendkeys("{ENTER}")
wscript.sleep 500

dim floorType, msg
msg = MsgBox("yes = floor,no = 24.8mm", 4)
if msg = vbYes Then 
	floorType = "floor"
else 
	floorType = "24.8mm"
end if

ws.sendkeys "ren "&line&" "&floorType&".txt"
ws.sendkeys("{ENTER}")

ws.sendkeys "move "&floorType&".txt "&resultPath
ws.sendkeys("{ENTER}")
wscript.sleep 500

ws.sendkeys "yes"
ws.sendkeys("{ENTER}")


####################################################3.抓log
dim fso '先删除log再pull
set fso = CreateObject("Scripting.FileSystemObject")
if fso.folderExists("E:\log") then
	fso.deleteFolder "E:\log"
end if

Dim ws
Set ws = CreateObject("WScript.shell")
ws.run "adb shell",1
'ws.run "ssh root@10.10.35.212", 0, True
wscript.sleep 500
ws.sendkeys("root")
ws.sendkeys("{ENTER}")
wscript.sleep 500
ws.sendkeys("123")
ws.sendkeys("{ENTER}")
wscript.sleep 500
ws.sendkeys("md5sum /home/robot/config/run/.sys_backup.conf>/tmp/md5sumnew.check")
ws.sendkeys("{ENTER}")
wscript.sleep 500
ws.run "cmd /k e: && adb pull /userdata/yx_user/business/log/"


####################################################4.上传文件到扫地机
Dim ws
Set ws = CreateObject("WScript.shell")
ws.run "adb shell",1
wscript.sleep 500
ws.sendkeys("root")
ws.sendkeys("{ENTER}")
wscript.sleep 500
ws.sendkeys("123")
ws.sendkeys("{ENTER}")
wscript.sleep 500
ws.sendkeys("md5sum /home/robot/config/run/.sys_backup.conf>/tmp/md5sumnew.check")
ws.sendkeys("{ENTER}")
wscript.sleep 500

'删除log
ws.sendkeys("rm -rf /userdata/yx_user/business/log/*")
ws.sendkeys("{ENTER}")
wscript.sleep 4000
ws.sendkeys("chmod 777 /userdata/yx_debug_bin/* && reboot")

ws.run "cmd /k e: && adb push E:/robot.svc /userdata/yx_debug_bin/",1
wscript.sleep 3000

ws.run "taskkill /f /im cmd.exe",1

dim cnt:cnt = 15
Do While cnt <> 0
	wscript.sleep 500
	ws.sendkeys("{ENTER}")
	cnt = cnt - 1
Loop

####################################################5.模拟鼠标点击文件
set ws = wscript.CreateObject("Excel.Application")
ws.ExecuteExcel4Macro"CALL(""user32"",""SetCursorPos"",""JJJ"",""25"",""25"")" REM 25,25为鼠标移动后的坐标，左上为原点
wscript.sleep 25
ws.ExecuteExcel4Macro"CALL(""user32"",""mouse_event"",""JJJJJJ"",2,0,0,0,0)" REM 按一次鼠标’

set obj = CreateObject("wscript.shell")
obj.sendkeys "{ENTER}" REM 进入文件
wscript.sleep 25


