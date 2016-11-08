;~ Note(HoPollo) :
;~ Welcome to this OpenSource project written in AutoIt.
;~
;~ Disclaimer : This program is not about cheating or abusing the game,
;~ 		but it's a fun way to learn how to code intelligent macros.

#include <ImageSearch.au3>
#include <FileConstants.au3>
#include <MsgBoxConstants.au3>
#include <WinAPIFiles.au3>

Global Const $colorRecolte = 0x00837F
Global Const $colorPopout = 0xFF9700
Global Const $colorCombat = 0x4AA197

Global $XSablier, $YSablier, $XMain, $YMain, $XClose, $YClose, $XMonstre, $YMonstre , $recolterMain, $recolterSablier = 0
Global $DetectionImage, $DetectionPixel, $Combat , $Wait, $Popout, $Attacking, $CollectingMain, $CollectingSablier, $Moving = False

Global $reason = "Thanks for using this program, see you next time."

Global $launcher = "[TITLE:Updater Wakfu; CLASS:QWidget]"
Global $title = "[TITLE:WAKFU; CLASS:SunAwtFrame]"
Global $id = "[CLASS:SunAwtCanvas; INSTANCE:2]"

Global Const $target = "target.png"
Global Const $harvest = "harvest.png"
Global Const $cut = "cut.png"
Global Const $close = "close.png"
Global Const $dll1 = "ImageSearchDLL.dll"
Global Const $dll2 = "ImageSearchDLLx32.dll"
Global Const $dll3 = "ImageSearchDLLx64.dll"

Global $CouperOnly = False
Global $DetectionParPixel = True
Global $colorPixelMob[3] = [0x595510, 0xFFF1B2, 0x777208]
Global $tolerancePixel = 2

HotKeySet ("{ESC}","ExitScript")

Requirements()

Func Requirements()
   $file1 = FileExists($target)
   $file2 = FileExists($harvest)
   $file3 = FileExists($cut)
   $file4 = FileExists($close)
   $file5 = FileExists($dll1)
   $file6 = FileExists($dll2)
   $file7 = FileExists($dll3)

   If $file1 And $file2 And $file3 And $file4 And $file5 And $file6 And $file7 = True Then
	  Start()
   Else
	  $reason = "Some important required files are missing, please check if they are in the same folder as this program."
	  ExitScript()
   EndIf
EndFunc

Func Start()
   Local $ok = False
   Local $to = 0
   Do
   Sleep(100)
   If WinExists($launcher, "") Then
	  ConsoleWrite("Updater OK" & @CRLF)
	  $ok = True
   ElseIf WinExists($title, "") Then
	  ConsoleWrite("WAKFU OK" & @CRLF)
	  $ok = True
   Else
	  ConsoleWrite("Updater/WAKFU NO" & @CRLF)
	  $to = $to + 1
	  If $to > 50 Then
		 $reason = "TimeOut : Wakfu.exe (Not dectected)"
		 ExitScript()
	  EndIf
   EndIf
   Until $ok
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
   Sleep(6000)

	  #Region Images Searchs
	  $monstreImage = _ImageSearch($target, 1, $XMonstre, $YMonstre, 30)
	  $recolterSablier = _ImageSearch($harvest, 1, $XSablier, $YSablier, 100)
	  $recolterMain = _ImageSearch($cut, 1, $XMain, $YMain, 100)
	  $Close = _ImageSearch($close, 1, $XClose, $YClose, 100)
	  #EndRegion

	  #Region Pixels Searchs
	  $recolte = PixelSearch($aPos[0] + 20, $aPos[1] + 75, $aPos[2] - 30, $aPos[3] - 90, $colorRecolte)
	  $pop = PixelSearch($aPos[0] + 500,$aPos[1] + 260, $aPos[2] - 480,$aPos[3] - 420, $colorPopout, 5)
	  $piste1 = PixelSearch($aPos[0] + 20, $aPos[1] + 75, $aPos[2] - 30, $aPos[3] - 90, $colorPixelMob[0], $tolerancePixel)
		 $piste2 = PixelSearch($piste1[0] + 10, $piste1[1] + 35, $piste1[2] - 15, $piste1[3] - 45, $colorPixelMob[1], $tolerancePixel)
			$monstrePixel = PixelSearch($piste2[0] + 5, $piste2[1] + 17, $piste2[2] - 7, $piste2[3] - 23, $colorPixelMob[2], $tolerancePixel)
	  #EndRegion

	  #Region Actions
		 If $recolterSablier = 1 Then
			If $CouperOnly = True Then
			   $CollectingSablier = False
			Else
			   $CollectingSablier = True
		 EndIf

		 ElseIf $recolterMain = 1 Then
			$CollectingMain = True

		 ElseIf IsArray($recolte) Then
			$Wait = True

		 ElseIf $monstreImage = 1 Then
			$DetectionImage = True

		 ElseIf $Close = 1 Then
			   Sleep(1000)
				  ControlClick($hWnd,"",$id, "left", 1, $XClose, $YClose)

		 ElseIf IsArray($pop) Then
			$Popout = True

		 ElseIf IsArray($piste1) Then
		  	If IsArray($piste2) Then
			 	If IsArray($monstrePixel) Then
					If $DetectionParPixel = True Then
					  	$DetectionPixel = True
					EndIf
			 	EndIf
		 	 EndIf
		 EndIf
	  #EndRegion

   While $Wait
	  ConsoleWrite("Tempo dectected" & @CRLF)
	  Sleep(3000)
	  $Wait = False
   WEnd

   While $Popout
	  ConsoleWrite("Popout detected" & @CRLF)
	  Sleep(100)
	  ControlClick($hWnd,"",$id, "left", 1, $aPos[0] + 520, $aPos[1] + 425)
	  Sleep(100)
	  ControlClick($hWnd,"",$id, "left", 1, $aPos[0] + 480, $aPos[1] + 400)
	  $Popout = False
   WEnd

   While $DetectionPixel
	  ConsoleWrite("MOB found ! (Pixel)" & @CRLF)
	  Sleep(100)
	  ControlClick($hWnd,"",$id, "right", 1, $monstrePixel[0], $monstrePixel[1])
	  $DetectionPixel = False
   WEnd

   While $DetectionImage
	  ConsoleWrite("MOB found ! (Image)" & @CRLF)
	  Sleep(100)
	  ControlClick($hWnd,"",$id, "right", 1, $XMonstre, $YMonstre)
	  $DetectionImage = False
   WEnd

   While $CollectingMain
	  ConsoleWrite("Harvesting -> Hand " & @CRLF)
	  Sleep(500)
	  ControlClick($hWnd,"",$id, "left", 1, $XMain, $YMain)
		 $CollectingMain = False
   WEnd

   While $CollectingSablier
	  ConsoleWrite("Harvesting -> Sablier " & @CRLF)
	  Sleep(500)
	  ControlClick($hWnd,"",$id, "left", 1, $XSablier, $YSablier)
	  $CollectingSablier = False
   WEnd

WEnd
EndFunc

Func ExitScript()
   MsgBox(0,"Closing", $reason, 10)
   ConsoleWrite("Program closed...")
   Exit
EndFunc
