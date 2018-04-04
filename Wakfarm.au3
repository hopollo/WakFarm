;~ Note(HoPollo) :
;~ Welcome to this OpenSource project written in AutoIt.
;~
;~ Disclaimer : This program is not about cheating or abusing the game,
;~ 		but it's a fun way to learn how to code intelligent macros.

;~ #RequireAdmin
#include <ImageSearch.au3>
#include <FileConstants.au3>
#include <MsgBoxConstants.au3>
#include <WinAPIFiles.au3>

; TODO (HoPollo) : Implement a proper GUI

Opt("PixelCoordMode", 2)

Global Const $colorRecolte = 0x00837F
Global Const $colorPopout = 0xFF9700
Global Const $colorCombat = 0x4AA197

Global $DetectionImage, $DetectionPixel, $Combat , $Wait, $Popout, $Attacking, $CollectingHand, $CollectingSablier, $Moving = False

Global $reason = "Thanks for using this program, see you next time."

Global $launcher = "[TITLE:Updater Wakfu; CLASS:QWidget]"
Global $title = "[TITLE:WAKFU; CLASS:SunAwtFrame]"
Global $id = "[CLASS:SunAwtCanvas; INSTANCE:1]"

Global $config = "config.ini"
Global $target = "target.png"
Global $harvest = "harvest.png"
Global $cut = "cut.png"
Global $close = "close.png"
Global $dll1 = "ImageSearchDLL.dll"
Global $dll2 = "ImageSearchDLLx32.dll"
Global $dll3 = "ImageSearchDLLx64.dll"

Global $CouperOnly = False
Global $DetectionParPixel = True
Global $colorPixelMob[] = ["0x6D320B", "0x1D3836"]
Global $tolerancePixel = 2

HotKeySet ("{ESC}","ExitScript")

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
;~    $file8 = FileExists($config)


;~    If $file1 And $file2 And $file3 And $file4 And $file5 And $file6 And $file7 And $file8 = True Then
   If $file1 And $file2 And $file3 And $file4 And $file5 And $file6 And $file7 = True Then
	  ; TODO : Add ini config file reading for vars and stuff
;~ 	  ConfigRead()
	  Start()
   Else
	  $reason = "Some important required files are missing, please check if they are in the same folder as this program."
	  ExitScript()
   EndIf
EndFunc

Func ConfigRead()
   $hFileOpen = FileOpen($config)
   If $hFileOpen = -1 Then
        CreateConfig()
   Else
		Start()
   EndIf
EndFunc

Func CreateConfig()
   ;TODO (HoPollo) : Implement default config.ini template if needed new
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
	  Step0()
   EndIf
EndFunc

Func Step0()
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
   Step1()
EndFunc

Func Step1()
While 1
   ConsoleWrite("Analysing..." & @CRLF)
   Sleep(500)

	  #Region Images Searchs
	  ; ISSUE : ImageSearch are not stable atm
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
			If $CouperOnly = True Then
			   $CollectingSablier = False
			Else
			   $CollectingSablier = True
		 EndIf

		 ElseIf IsArray($recolterHand) Then
			$CollectingHand = True

		 ElseIf IsArray($recolte) Then
			$Wait = True

		 ElseIf IsArray($monstreImage) Then
			$DetectionImage = True

		 ElseIf IsArray($monstrePixel) And $DetectionParPixel = True Then
			$DetectionPixel = True

		 ElseIf IsArray($closeBtnImage) Or $recolte = 1 Then
			   $Popout = True
		 EndIf
	  #EndRegion

   While $Wait
	  ; ISSUE : Detects Tempo on fight state
	  ; TODO (HoPollo) : Change completly the tempo detection or something
	  ConsoleWrite("Tempo dectected" & @CRLF)
	  Sleep(3000)
	  $Wait = False
   WEnd

   While $Popout
	  ConsoleWrite("Popout detected" & @CRLF)
	  Sleep(100)
	  ControlClick($hWnd,"",$id, "left", 1, $closeBtnImage[0], $closeBtnImage[1])
	  $Popout = False
   WEnd

   While $DetectionImage
	  ConsoleWrite("MOB found ! (Image)" & @CRLF)
	  Sleep(100)
	  ControlClick($hWnd,"",$id, "right", 1, $monstreImage[0], $monstreImage[1])
	  $DetectionImage = False
   WEnd

   While $DetectionPixel
	  ConsoleWrite("MOB found ! (Pixel)" & @CRLF)
	  Sleep(100)
	  ControlClick($hWnd,"",$id, "right", 1, $monstrePixel[0], $monstrePixel[1])
	  $DetectionPixel = False
   WEnd

   While $CollectingHand
	  ConsoleWrite("Harvesting -> Hand " & @CRLF)
	  Sleep(500)
	  ControlClick($hWnd,"",$id, "left", 1, $recolterHand[0], $recolterHand[1])
	  $CollectingHand = False
	  $Moving = True
   WEnd

   While $CollectingSablier
	  ConsoleWrite("Harvesting -> Sablier " & @CRLF)
	  Sleep(500)
	  ControlClick($hWnd,"",$id, "left", 1, $recolterSablier[0], $recolterSablier[1])
	  $CollectingSablier = False
	  $Moving = True
   WEnd

   While $Moving
	  ConsoleWrite("Running, wait...")
	  Sleep(2000)
	  $Moving = False
   WEnd

WEnd
EndFunc

Func ExitScript()
   MsgBox(0,"Closing", $reason, 10)
;~    FileClose($config)
   ConsoleWrite("Program closed...")
   Exit
EndFunc
