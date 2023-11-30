Dim ws,obj

set ws = wscript.CreateObject("Excel.Application")
set obj = CreateObject("wscript.shell")
set objtxt=obj.exec("C:\Users\17300\Desktop\renLog.bat")
ret=objtxt.Stdout.ReadLine()
if ret="" Then
	WScript.echo ret
	WScript.echo "Failed to find the log"
	WScript.quit
	set ws=Nothing
	set objtxt=Nothing
	set ret=Nothing	
end if

'obj.run "C:\Users\17300\Desktop\renameLog.bat",1
'wscript.sleep 500
obj.run "decode.exe",1
wscript.sleep 1000

ws.ExecuteExcel4Macro"CALL(""user32"",""SetCursorPos"",""JJJ"",""1200"",""320"")" REM 25,25为鼠标移动后的坐标，左上为原点
wscript.sleep 25
ws.ExecuteExcel4Macro"CALL(""user32"",""mouse_event"",""JJJJJJ"",2,0,0,0,0)"
obj.sendkeys "{ENTER}"
wscript.sleep 25
obj.sendkeys " "
wscript.sleep 50
obj.sendkeys "C:\Users\17300\Desktop\2"
obj.sendkeys "{ENTER}"
wscript.sleep 25

ws.ExecuteExcel4Macro"CALL(""user32"",""SetCursorPos"",""JJJ"",""1200"",""440"")" REM 25,25为鼠标移动后的坐标，左上为原点
wscript.sleep 25
ws.ExecuteExcel4Macro"CALL(""user32"",""mouse_event"",""JJJJJJ"",1,0,0,0,0)"
obj.sendkeys "{ENTER}"

wscript.sleep 1000
msg=MsgBox("unzip the log?",vbYesNo)
if msg=vbYes then
	obj.run "unzip.bat",1
end if

wscript.sleep 10000
msg=MsgBox("close all windows?",vbYesNo)
if msg=vbYes then
	obj.run "taskkill /f /im decode.exe"
	wscript.sleep 25
	obj.run "taskkill /f /im BreeZip.exe" 'C:\Program Files\WindowsApps\3138AweZip.AweZip_1.4.31.0_x64__ffd303wmbhcjt\AweZip\
end if

WScript.quit
set ws=Nothing
set obj=Nothing