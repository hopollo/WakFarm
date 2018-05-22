;~ Note(HoPollo) :
;~ Welcome to this OpenSource project written in AutoIt.
;~
;~ Disclaimer : This program is not about cheating or abusing the game,
;~ 		but it's a fun way to learn how to code intelligent macros.

#RequireAdmin
#include <FileConstants.au3>
#include <MsgBoxConstants.au3>
#include <WinAPIFiles.au3>
#include <ImageSearch.au3>

; TODO (HoPollo) : Implement a proper GUI

Opt("PixelCoordMode", 2)

Global $config = "config.ini"

Global Const $colorRecolte = IniRead($config, "settings" , "Color_Harvest", "")
Global Const $colorPopout = IniRead($config, "settings" , "Color_Popout", "")
Global Const $colorCombat = IniRead($config, "settings" , "Color_Combat", "")
Global $colorPixelMob[] = ["0x6D320B", "0x1D3836"]
Global $tolerancePixel = IniRead($config, "settings" , "Pixel_Tolerance", "")

Global $detectionImage, $detectionPixel, $combat , $wait, $popout, $attacking, $collectingHand, $collectingSablier, $moving = False

Global $reason = "Thanks for using this program, see you next time."

Global $launcher = "[TITLE:Updater Wakfu; CLASS:QWidget]"
Global $title = "[TITLE:WAKFU; CLASS:SunAwtFrame]"
Global $id = "[CLASS:SunAwtCanvas; INSTANCE:1]"

Global $target = IniRead($config, "settings" , "Image_Target", "target.png")
Global $harvest = IniRead($config, "settings" , "Button_Harvest", "harvest.png")
Global $cut = IniRead($config, "settings" , "Button_Cut", "cut.png")
Global $close = IniRead($config, "settings" , "Button_Close", "close.png")
Global $dll1 = "ImageSearchDLL.dll"
Global $dll2 = "ImageSearchDLLx32.dll"
Global $dll3 = "ImageSearchDLLx64.dll"

; implement debugMode after GUI feature
Global $debugMode = False
Global $couperOnly = IniRead($config, "basic" , "Cut_Only", "False")
Global $detectionParPixel = IniRead($config, "basic" , "Pixel_Detection", "True")

$exitKey = IniRead($config, "basic", "Exit_Key", "ESC")

HotKeySet ("{"&$exitKey&"}","ExitScript")

Requirements()

Func Requirements()
   ; TODO (HoPollo) : Add .ini verification after implemented
	$file1 = FileExists($target)
	$file2 = FileExists($harvest)
	$file3 = FileExists($cut)
	$file4 = FileExists($close)
	$file5 = FileExists($dll1)
	$file6 = FileExists($dll2)
	$file7 = FileExists($dll3)
	$file8 = FileExists($config)

	If $file1 And $file2 And $file3 And $file4 And $file5 And $file6 And $file7 And $file8 = True Then
	  ConfigRead()
	Else
		Select
			Case Not $file1
				MsgBox(0,"Error", $target & " is missing.")
			Case Not $file2
				MsgBox(0,"Error", $harvest & " is missing.")
			Case Not $file3
				MsgBox(0,"Error", $cut & " is missing.")
			Case Not $file4
				MsgBox(0,"Error", $close & " is missing.")
			Case Not $file5
				MsgBox(0,"Error", $dll1 & " is missing.")
			Case Not $file6
				MsgBox(0,"Error", $dll2 & " is missing.")
			Case Not $file7
				MsgBox(0,"Error", $dll3 & " is missing.")
			Case Not $file8
				MsgBox(0,"Error", $config & " is missing.")
				ConfigRead()
		EndSelect
	  ExitScript()
	EndIf
EndFunc

Func ConfigRead()
	$hFileOpen = FileOpen($config)
	If $hFileOpen = -1 Then
		$create = FileOpen($config, 1)
		If $create = -1 Then
			MsgBox(0,"Error","Unable to re-create config file, download it from the github/Wakfarm")
		Else
			MsgBox(0,"Succes", $config & " is now created, please restart the script.")
			WriteDefaultConfig()
		EndIf
	Else
		Start()
	EndIf
EndFunc

Func WriteDefaultConfig()
	FileWrite($config, "[basic]" & @CRLF & "Exit_Key=ESC" & @CRLF & "Debug_Mode=False" & @CRLF & "Cut_Only=False" & @CRLF & "Pixel_Detection=True" & @CRLF & @CRLF)
	FileWrite($config, "[settings]" & @CRLF & "Color_Combat=0x4AA197" & @CRLF & "Color_Popup=0xFF9700" & @CRLF & "Color_Harvest=0x00837F" & @CRLF & "Pixel_Tolerance=2" & @CRLF & "Image_Target=target.png" & @CRLF & "Button_Harvest=harvest.png" & @CRLF & "Button_Close=close.png" & @CRLF & "Button_Cut=cut.png")
EndFunc

Func Start()
   Local $updater = False
   Local $game = False
   Local $timeOut = 10 ;seconds
   Do
   Sleep(100)
   If WinExists($launcher, "") Then
	  ConsoleWrite("Updater OK" & @CRLF)
	  $updater = True
   EndIf
   If WinExists($title, "") Then
	  ConsoleWrite("WAKFU OK" & @CRLF)
	  $game = True
   Else
	  ConsoleWrite("Updater/WAKFU NO" & @CRLF)
	  Sleep(1000)
	  $timeOut = $timeOut - 1
	  If $timeOut = 0 Then
		 $reason = "TimeOut : Wakfu (Not dectected/launched properly)"
		 ExitScript()
	  EndIf
   EndIf
   Until $updater And $game = True
   MsgBox(0,"Step 1","Please completly join the world, before pressing OK")
   If 1 Then
	  GameWindowControl()
   EndIf
EndFunc

Func GameWindowControl()
   ConsoleWrite("Starting : Step0" & @CRLF)
   Global $hWnd = WinActivate($title,"")
   If @error Then
	  WinActivate($hWnd)
	  ConsoleWrite("Focus -> WAKFU" & @CRLF)
   Else
	  Sleep(1000)
	  ConsoleWrite("Scroll up" & @CRLF)
	  MouseWheel("down",15)
   EndIf
   Global $aPos = WinGetPos($hWnd)
   ScriptControl()
EndFunc

Func ScriptControl()
	While 1
		ConsoleWrite("Analysing..." & @CRLF)
		Sleep(500)

		#Region Images Searchs
		Global $closeBtnImage = _ImageSearch($close)
		Global $monstreImage = _ImageSearch($target)
		Global $recolterSablier = _ImageSearch($harvest)
		Global $recolterHand = _ImageSearch($cut)
		#EndRegion

		#Region Pixels Searchs

		; ISSUE : No more detecting the cross 100%
		Global $closeBtnPixel = PixelSearch($aPos[0], $aPos[1], $aPos[2], $aPos[3], $colorPopout, $tolerancePixel)

		; ISSUE : Detects Tempo on fight state
		; TODO (HoPollo) : Change completly the tempo detection or something
		Global $recolte = PixelSearch($aPos[0], $aPos[1], $aPos[2], $aPos[3], $colorRecolte, $tolerancePixel)

		Local $randomCreaturePixel = Random(0, UBound($colorPixelMob)-1, 1)
		ConsoleWrite("Pixel picked : " &  $colorPixelMob[$randomCreaturePixel] & @CRLF)
		Global $monstrePixel = PixelSearch($aPos[0], $aPos[1], $aPos[2], $aPos[3], $colorPixelMob[$randomCreaturePixel], $tolerancePixel)
		#EndRegion


		#Region Actions
		If IsArray($recolterSablier) Then
		If $couperOnly = True Then
		   $collectingSablier = False
		Else
		   $collectingSablier = True
		EndIf

		ElseIf IsArray($recolterHand) Then
		$collectingHand = True

		ElseIf IsArray($recolte) Then
		$wait = True

		ElseIf IsArray($monstreImage) Then
		$detectionImage = True

		ElseIf IsArray($monstrePixel) And $detectionParPixel = True Then
		 $detectionPixel = True

		ElseIf IsArray($closeBtnImage) Or $recolte = 1 Then
		   $popout = True
		EndIf
		#EndRegion

		While $wait
		  ; ISSUE : Detects Tempo on fight state
		  ; TODO (HoPollo) : Change completly the tempo detection or something
		  ConsoleWrite("Tempo dectected" & @CRLF)
		  Sleep(3000)
		  $wait = False
		WEnd

		While $popout
		  ConsoleWrite("Popout detected" & @CRLF)
		  Sleep(100)
		  ControlClick($hWnd,"",$id, "left", 1, $closeBtnImage[0], $closeBtnImage[1])
		  $popout = False
		WEnd

		While $detectionImage And Not $moving
		  ConsoleWrite("MOB found ! (Image)" & @CRLF)
		  Sleep(100)
		  ControlClick($hWnd,"",$id, "right", 1, $monstreImage[0], $monstreImage[1])
		  $detectionImage = False
		  $moving = True
		WEnd

		While $detectionPixel And Not $moving
		  ConsoleWrite("MOB found ! (Pixel)" & @CRLF)
		  Sleep(100)
		  ControlClick($hWnd,"",$id, "right", 1, $monstrePixel[0], $monstrePixel[1])
		  $detectionPixel = False
		  $moving = True
		WEnd

		While $collectingHand And Not $moving
		  ConsoleWrite("Harvesting -> Hand " & @CRLF)
		  Sleep(500)
		  ControlClick($hWnd,"",$id, "left", 1, $recolterHand[0], $recolterHand[1])
		  $collectingHand = False
		  $moving = True
		WEnd

		While $collectingSablier And Not $moving
		  ConsoleWrite("Harvesting -> Sablier " & @CRLF)
		  Sleep(500)
		  ControlClick($hWnd,"",$id, "left", 1, $recolterSablier[0], $recolterSablier[1])
		  $collectingSablier = False
		  $moving = True
		WEnd

		While $moving
		  ConsoleWrite("Running, wait...")
		  Sleep(2000)
		  $moving = False
		WEnd
	WEnd
EndFunc

Func ExitScript()
   MsgBox(0,"Closing", $reason, 10)
   FileClose($config)
   ConsoleWrite("Program closed...")
   Exit
EndFunc
