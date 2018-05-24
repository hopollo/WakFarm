;~ Note(HoPollo) :
;~ Welcome to this OpenSource project written in AutoIt.
;~
;~ Disclaimer : This program is not about cheating or abusing the game,
;~ 		but it's a fun way to learn how to code intelligent macros.

;#RequireAdmin
#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <File.au3>
#include <Array.au3>
#include <WinAPIFiles.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <ScrollBarsConstants.au3>
#include <MsgBoxConstants.au3>
#include <ImageSearch.au3>
#include <GuiEdit.au3>
#include <StaticConstants.au3>

Opt("PixelCoordMode", 2)

Global $config = "config.ini"

Global $imageUrl = IniRead($config, "basic", "Image_Folder", "")
Global $targetUrl = IniRead($config, "basic", "Target_Folder", "")

Global Const $colorRecolte = IniRead($config, "settings" , "Color_Harvest", "")
Global Const $colorPopout = IniRead($config, "settings" , "Color_Popout", "")
Global Const $colorCombat = IniRead($config, "settings" , "Color_Combat", "")
Global $colorPixelMob[] = ["0x6D320B", "0x1D3836"]
Global $tolerancePixel = IniRead($config, "settings" , "Pixel_Tolerance", "")

Global $target = IniRead($config, "settings" , "Image_Target", "")
Global $harvest = IniRead($config, "settings" , "Button_Harvest", "")
Global $cut = IniRead($config, "settings" , "Button_Cut", "")
Global $close = IniRead($config, "settings" , "Button_Close", "")
Global $dll1 = "ImageSearchDLL.dll"
Global $dll2 = "ImageSearchDLLx32.dll"
Global $dll3 = "ImageSearchDLLx64.dll"

Global $launcher = "[TITLE:Updater Wakfu; CLASS:QWidget]"
Global $title = "[TITLE:WAKFU; CLASS:SunAwtFrame]"
Global $id = "[CLASS:SunAwtCanvas; INSTANCE:1]"

Global $debugMode = IniRead($config, "basic", "Debug_Mode", "False")
Global $couperOnly = IniRead($config, "basic" , "Cut_Only", "False")
Global $detectionParPixel = IniRead($config, "basic" , "Pixel_Detection", "True")

Global $detectionImage, $detectionPixel, $combat , $wait, $popout, $attacking, $collectingHand, $collectingSablier, $moving = False

Global $reason = @CRLF & "Thanks for using this program, see you next time."

$exitKey = IniRead($config, "basic", "Exit_Key", "ESC")

HotKeySet ("{"&$exitKey&"}","ExitScript")

#Region ### START Main GUI ###
Global $Form1 = GUICreate("WakFarm", 197, 268, 192, 124)
WinSetOnTop($Form1, "", 1)
Global $journal = GUICtrlCreateEdit("", 0, 0, 196, 209, BitOR($ES_AUTOVSCROLL,$ES_READONLY,$WS_VSCROLL))
GUICtrlSetData(-1, "")
GUICtrlSetState(-1, $GUI_DISABLE)
GUICtrlSetCursor (-1, 2)
$GUI_EVENT_START = GUICtrlCreateButton("Start", 25, 240, 150, 25)
GUICtrlSetFont(-1, 8, 800, 0, "MS Sans Serif")
GUICtrlSetBkColor(-1, 0x008080)
Opt("GUICoordMode", 2)
GUISetCoord(1153, 231)
GUISetState(@SW_SHOW)
#EndRegion ### END Main GUI ###

Info("Bienvenue sur WakFarm by HoPollo" & @CRLF)

While 1
   $nMsg = GUIGetMsg()

   Switch $nMsg
	  Case $GUI_EVENT_CLOSE
		 ExitScript()
	  Case $GUI_EVENT_START
		 GUICtrlSetData($GUI_EVENT_START, $exitKey & " = exit")
		 Requierements()
   EndSwitch
WEnd

Func FreshStart()
   Sleep(100)

   GUICtrlSetData($GUI_EVENT_START, "Start")
EndFunc

Func Requierements()
	ConfigRead()

	$file1 = FileExists($imageUrl & $harvest)
	$file2 = FileExists($imageUrl & $cut)
	$file3 = FileExists($imageUrl & $close)
	$file4 = FileExists($dll1)
	$file5 = FileExists($dll2)
	$file6 = FileExists($dll3)
	$file7 = FileExists($config)

	If $file1 And $file2 And $file3 And $file4 And $file5 And $file6 And $file7 = True Then
	  debug("Requierments -> OK" & @CRLF)
	Else
		Select
			Case Not $file1
				info("Error : " &  $harvest & " is missing")
			Case Not $file2
				info("Error : " &  $cut & " is missing")
			Case Not $file3
				info("Error : " &  $close & " is missing")
			Case Not $file4
				info("Error : " &  $dll1 & " is missing")
			Case Not $file5
				info("Error : " &  $dll2 & " is missing")
			Case Not $file6
				info("Error : " &  $dll3 & " is missing")
			Case Not $file7
				info("Error : " &  $config & " is missing")
		EndSelect
		GUICtrlSetData($GUI_EVENT_START, "Start")
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
		ReadTargets()
	EndIf
EndFunc

Func ReadTargets()

	Global $targetInfo = _FileListToArrayRec($targetUrl, "*", $FLTAR_FILES, $FLTAR_NORECUR, $FLTAR_SORT)
	If @error Then
	  info("Unable to retrieve target info from config files")
	  FreshStart()
	EndIf

	Dim $foo[0]

	info("Targets found : " & $targetInfo[0])
	debug("Current targets :")

	For $i = 1 To $targetInfo[0]
	  debug($targetInfo[$i])
	  _ArrayAdd($foo, $targetInfo[$i])
	Next
	debug("") ;Space after target list

	Start()
EndFunc

Func WriteDefaultConfig()
	FileWrite($config, "[basic]" & @CRLF & "Exit_Key=ESC" & @CRLF & "Debug_Mode=False" & @CRLF & "Image_Folder=imgs/" & @CRLF & "Target_Folder=targets/current/" & @CRLF & "Cut_Only=False" & @CRLF & "Pixel_Detection=True" & @CRLF & @CRLF)
	FileWrite($config, "[settings]" & @CRLF & "Color_Combat=0x4AA197" & @CRLF & "Color_Popup=0xFF9700" & @CRLF & "Color_Harvest=0x00837F" & @CRLF & "Pixel_Tolerance=2" & @CRLF & "Button_Harvest=harvest.png" & @CRLF & "Button_Close=close.png" & @CRLF & "Button_Cut=cut.png")
EndFunc

Func info($messageJournal, $autresInfos = "")
   GUICtrlSetData($journal, GUICtrlRead($journal) & @CRLF & $messageJournal)
   $end = StringLen(GUICtrlRead($journal))
   _GUICtrlEdit_SetSel($journal, $end, $end)
   _GUICtrlEdit_Scroll($journal, $SB_SCROLLCARET)
EndFunc

Func debug($messageJournal, $autresInfos = "")
   If $debugMode = True Then
	  $sleep = 500
	  GUICtrlSetData($journal, GUICtrlRead($journal) & @CRLF & $messageJournal)
	  $end = StringLen(GUICtrlRead($journal))
	  _GUICtrlEdit_SetSel($journal, $end, $end)
	  _GUICtrlEdit_Scroll($journal, $SB_SCROLLCARET)
   EndIf
EndFunc

Func Start()
   Local $updater = False
   Local $game = False
   Local $timeOut = 10 ;seconds
   Do
   Sleep(100)
   If WinExists($launcher, "") Then
	  debug("Updater OK")
	  $updater = True
   EndIf
   If WinExists($title, "") Then
	  debug("WAKFU OK")
	  $game = True
   Else
	  debug("Updater/WAKFU not found")
	  Sleep(1000)
	  $timeOut = $timeOut - 1
	  If $timeOut = 0 Then
		 $reason = "TimeOut : Wakfu (Not dectected/launched properly)"
		 ExitScript()
	  EndIf
   EndIf
   Until $updater And $game = True
   MsgBox(0, "Info", "Please completly join the world, before pressing OK") ; must stay msgbox to know if Ok or not
   If 1 Then
	  GameWindowControl()
   EndIf
EndFunc

Func GameWindowControl()
   debug("Starting : Step0")
   Global $hWnd = WinActivate($title,"")
   If @error Then
	  WinActivate($hWnd)
	  debug("Focus -> WAKFU")
   Else
	  Sleep(1000)
	  debug("Scroll up")
	  MouseWheel("down",15)
   EndIf
   Global $aPos = WinGetPos($hWnd)
   ScriptControl()
EndFunc

Func ScriptControl()
	While 1
		info("Analysing...")
		Sleep(500)

		#Region Images Searchs
		Global $closeBtnImage = _ImageSearch($imageUrl & $close)

		Local $a = 0
		Do
			$a = $a + 1
			Info("Searching : " & $targetInfo[$a])
			Global $monstreImage = _ImageSearch($targetUrl & $targetInfo[$a])
		Until $a = $targetInfo[0]

		Global $recolterSablier = _ImageSearch($imageUrl & $harvest)
		Global $recolterHand = _ImageSearch($imageUrl & $cut)
		#EndRegion

		#Region Pixels Searchs

		; ISSUE : No more detecting the cross 100%
		Global $closeBtnPixel = PixelSearch($aPos[0], $aPos[1], $aPos[2], $aPos[3], $colorPopout, $tolerancePixel)

		; ISSUE : Detects Tempo on fight state
		; TODO (HoPollo) : Change completly the tempo detection or something
		Global $recolte = PixelSearch($aPos[0], $aPos[1], $aPos[2], $aPos[3], $colorRecolte, $tolerancePixel)

		Local $randomCreaturePixel = Random(0, UBound($colorPixelMob)-1, 1)
		info("Pixel picked : " &  $colorPixelMob[$randomCreaturePixel] & @CRLF)
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
		  info("Tempo dectected")
		  Sleep(3000)
		  $wait = False
		WEnd

		While $popout
		  info("Popout detected")
		  Sleep(100)
		  ControlClick($hWnd,"",$id, "left", 1, $closeBtnImage[0], $closeBtnImage[1])
		  $popout = False
		WEnd

		While $detectionImage And Not $moving
		  info("MOB found ! (Image)")
		  Sleep(100)
		  ControlClick($hWnd,"",$id, "right", 1, $monstreImage[0], $monstreImage[1])
		  $detectionImage = False
		  $moving = True
		WEnd

		While $detectionPixel And Not $moving
		  info("MOB found ! (Pixel)")
		  Sleep(100)
		  ControlClick($hWnd,"",$id, "right", 1, $monstrePixel[0], $monstrePixel[1])
		  $detectionPixel = False
		  $moving = True
		WEnd

		While $collectingHand And Not $moving
		  info("Harvesting -> Hand ")
		  Sleep(500)
		  ControlClick($hWnd,"",$id, "left", 1, $recolterHand[0], $recolterHand[1])
		  $collectingHand = False
		  $moving = True
		WEnd

		While $collectingSablier And Not $moving
		  info("Harvesting -> Sablier ")
		  Sleep(500)
		  ControlClick($hWnd,"",$id, "left", 1, $recolterSablier[0], $recolterSablier[1])
		  $collectingSablier = False
		  $moving = True
		WEnd

		While $moving
		  info("Running, wait...")
		  Sleep(2000)
		  $moving = False
		WEnd
	WEnd
EndFunc

Func ExitScript()
   info(@CRLF & $reason)
   FileClose($config)
   Sleep(2000)
   Exit
EndFunc