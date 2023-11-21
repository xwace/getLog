dim ws,fso,Project,psw,calPath,resultPath

msg = MsgBox("yes is JDM, no is ZY2X",4)
if msg = vbYes Then
	Project = "JDM"
	psw = "yx113322"
else 
	Project = "ZY2X"
	psw = "yx113322"
end if

calPath = "E:\wdh\huanchuang\calibration\"&Project&"\xwCal"
resultPath = "E:\wdh\huanchuang\calibration\"&Project&"\xwResult"

'先删除本地计算标定用的旧log再pull
set fso = CreateObject("Scripting.FileSystemObject")
if fso.folderExists("E:\wdh\huanchuang\calibration\"&Project&"\xwCal\1") then
	fso.DeleteFile "E:\wdh\huanchuang\calibration\"&Project&"\xwCal\*"
	fso.DeleteFolder "E:\wdh\huanchuang\calibration\"&Project&"\xwCal\1"
	fso.DeleteFolder "E:\wdh\huanchuang\calibration\"&Project&"\xwCal\2"
	on error resume next
end if

Set ws = CreateObject("WScript.shell")

'判断adb是否打开
Dim deviceName,reg,match
set ret = ws.Exec("adb devices")
deviceName = ret.stdOut.ReadAll()
set reg=New RegExp
reg.pattern="device"
reg.Global=True
set match=reg.Execute(deviceName)

if match.count <= 1 then
    WScript.Echo "Failed to open ADB!!!"
    set ws = Nothing
	set fso = Nothing
	set Project = Nothing
	set psw = Nothing
	set calPath = Nothing
	set resultPath = Nothing
	set ret = Nothing
	set deviceName = Nothing
	set reg=Nothing
	set match=Nothing
	WScript.Quit
end if
set ret = Nothing
set deviceName = Nothing
set reg=Nothing
set match=Nothing

'if ws.run("adb shell",,true)>0 then
	'WScript.Echo "Failed to open adb!!!"
	'set ws = Nothing
	'set fso = Nothing
	'set Project = Nothing
	'set psw = Nothing
	'set calPath = Nothing
	'set resultPath = Nothing
	'WScript.Quit
'end if

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

'删除扫地机线激光旧文件log,创建存放标定结果的扫地机文件
ws.sendkeys("rm -rf /userdata/yx_user/business/txt/1/* /userdata/yx_user/business/txt/2/* /home/robot/config/run/laser_calibrator.txt")
ws.sendkeys("{ENTER}")
wscript.sleep 4000
ws.sendkeys "touch /home/robot/config/run/laser_calibrator.txt"
ws.sendkeys("{ENTER}")
wscript.sleep 500

'开始清扫，抓取原始线激光数据到xwcal目录
InputBox("Start the robot and Wait for three seconds!!!!")

ws.run "cmd /k e: && cd \wdh\huanchuang\calibration\"&Project&"\xwCal && adb pull /userdata/yx_user/business/txt/1" '抓水平线激光数据
wscript.sleep 1500
ws.sendkeys("adb pull /userdata/yx_user/business/txt/2")'抓垂直线激光数据
ws.sendkeys("{ENTER}")
wscript.sleep 1500

ws.sendkeys "dir E:\wdh\huanchuang\calibration\"&Project&"\xwCal\1 /b > "&calPath&"\filename1.txt" '获取所有水平线激光文件名
ws.sendkeys("{ENTER}")

wscript.sleep 1000
path=calPath&"\filename1.txt"
Set A=fso.OpenTextFile(path,1)
line=A.ReadLine'其中一个线激光文件名称
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

'修改线激光文件名称：测试激光打到水平面，24.8mm木板两种场景
ws.sendkeys "ren "&line&" "&floorType&".txt" 
ws.sendkeys("{ENTER}")
'移动到存放标定数据的目录
ws.sendkeys "move "&floorType&".txt "&resultPath
ws.sendkeys("{ENTER}")
wscript.sleep 500

ws.sendkeys "yes"
ws.sendkeys("{ENTER}")
wscript.sleep 500

'计算标定结果并保存到机器的标定文件中
if MsgBox("Calculate the reuslt?", vbYesNo) = vbYes Then
	ws.sendkeys "python E:\wdh\python\hc_calibrator.py"	'调用算法计算标定的结果
	ws.sendkeys("{ENTER}")
	wscript.sleep 2000
	
	Dim path,hori_cali
	path = "E:/wdh/huanchuang/calibration/"&Project&"/xwResult/laser_calibrator.txt"
	Set A=fso.OpenTextFile(path,1)
	hori_cali = A.readline '读取水平线激光标定结果
	
	ws.appactivate("adb.exe")
	ws.sendkeys("{ENTER}")
	ws.sendkeys("echo "& hori_cali&">>/home/robot/config/run/laser_calibrator.txt") '存放到扫地机的文件中
	wscript.sleep 500
	ws.sendkeys("{ENTER}")
	ws.sendkeys("echo -61.0>>/home/robot/config/run/laser_calibrator.txt") '垂直线激光标定默认值
	wscript.sleep 500
	ws.sendkeys("{ENTER}")
	ws.sendkeys "grep -o -e 'pitch = [1-9].*$' /userdata/yx_user/business/log/log_robot |tail -n 1 | "
	ws.sendkeys "awk -F'[ ,]' '{{}print $3,$7{}}' >>/home/robot/config/run/laser_calibrator.txt" '提取文件中的俯仰角数据
	wscript.sleep 500
	ws.sendkeys("{ENTER}")
	ws.sendkeys("cat /home/robot/config/run/laser_calibrator.txt")
	wscript.sleep 500
	ws.sendkeys("{ENTER}")
	
end if

set ws = Nothing
set A  = Nothing
set fso = Nothing
set hori_cali = Nothing
set path = Nothing
set Project = Nothing
set psw = Nothing
set calPath = Nothing
set resultPath = Nothing
