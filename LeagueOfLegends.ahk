#SingleInstance force
#MaxThreads 50
#MaxThreadsPerHotkey 1

SetWorkingDir, %A_ScriptDir%
#include Gdip_All.ahk

SetTitleMatchMode, 3 ; Coz matchmaker the game are starting with the same name
DetectHiddenWindows, On
	
;Ajouter une entrée dans le menu pour mise à jour du script
Menu, tray, add
Menu, tray, add, Update

;On a besoin des droits admins pour intercepter les raccourcis dans league of legends (le jeu est lancé en mode admin)
if not A_IsAdmin
{
	Try
		Run *RunAs "%A_ScriptFullPath%"  ; Requires v1.0.92.01+
	Catch
		MsgBox Failed to launch as Admin
	ExitApp
}

;Recherche du jeu
SplitPath, A_ScriptFullPath, , , , iniFile
iniFile .= .ini
IniRead, gameFullPath, %iniFile%, General, GameFullPath

;Si on n'a pas trouvé le jeu configuré dans l'INI, on recherche son emplacement dans la base de registre
IfNotExist, %gameFullPath%
{
	RegRead, gameFullPath, HKEY_LOCAL_MACHINE, SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Components\D23C43CA8A8BF2E43B239AE9897FB699, D25657E31B99E7141B36EB3FC3DAF361
	IfExist, %gameFullPath%
		IniWrite, %gameFullPath%, %iniFile%, General, GameFullPath
}
	
;Si on n'a toujours pas trouvé le jeu (vraiment pas de bol !); on demande à l'utilisateur de le saisir
IfNotExist, %gameFullPath%
{	
	FileSelectFile, gameFullPath, 1,, Veuillez indiquer l`'emplacement du jeu, LeagueClient.exe
	If (ErrorLevel == 1)
		ExitApp
	IniWrite, %gameFullPath%, %iniFile%, General, GameFullPath
}
Menu, tray, Icon, %gameFullPath%, 1 
OnMessage(0x404, "AHK_NOTIFYICON")

;Lecture du mot de passe s'il est présent dans le fichier
IniRead, password, %iniFile%, General, password
if (password == "ERROR")
{
	InputBox, password, Quel est le password de votre account ?, La saisie d'un password vous permet de vous logger en utilisant la touche F1 sur le menu PVP.net, HIDE, , , , , , , nopassword
	IniWrite, %password%, %iniFile%, General, password
}

SetWinDelay, 30
SetKeyDelay, 2, 20
SetMouseDelay, 20

launching:
IfWinExist, League of Legends (TM) Client ; In-game
	WinActivate
Else IfWinExist, League of Legends ; Matchmaker
{
	WinActivate, League of Legends, League of Legends ; Matchmaker
	if(clickOnPicture("logo_matchmaker.png", 50)) ; deselect input password zone
	{
		if(clickOnPicture("password.png", 10))
			send %password%{Enter}
	}
}
; Else IfWinExist, LoL Patcher ; Patcher
; {
	; WinActivate
	; clickOnPicture("launch.png")
	; WinWait, League of Legends ; Matchmaker
	; goto launching
; }
Else
{
	Run, %gameFullPath%
	WinWait, League of Legends ; Matchmaker
	goto launching
}
		
; Minimiser Discord (close réduit au systray)
WinWait, Discord,, 60
WinClose

Return

; #IfWinActive League of Legends ; Matchmaker
; F1::send %password%{Enter}

#IfWinActive League of Legends ; Matchmaker
#IfWinActive League of Legends (TM) Client ; In-game
{
	;Raccourcis Foobar à moi-même
	^!w::
	^!x::
	^!c::	
	^!v::
	^!b::
	^!n::
	^!Up::
	^!Down::
	^!Left::
	^!Right::
	^!PgUp::
	^!PgDn::
		; wingetTitle, titre, ahk_exe foobar2000.exe
		; msgbox %titre%
		ControlSend, ahk_parent,%A_ThisHotkey%, ahk_class {97E27FAA-C0B3-4b8e-A693-ED7881E99FC1}
	Return
}

#IfWinActive League of Legends ; Matchmaker
{
	F12::
		clickOnPicture("accept.png")
	Return
}

clickOnPicture(imagefile, timeout := 0x7FFFFFFFFFFFFFFF)
{
	IfNotExist, %imagefile%
		Return false
		
	ListLines, off
	pToken := Gdip_Startup()
	Gdip_GetDimensions(pBitmap := Gdip_CreateBitmapFromFile(imagefile), w, h)
	Gdip_DisposeImage(pBitmap)
	Gdip_ShutDown(pToken)
	ListLines, on
	
	ErrorLevel := 1, retry := 0
	while(ErrorLevel == true && retry++ < timeout)
	{
		ImageSearch, x, y, 0, 0, A_ScreenWidth-1, A_ScreenHeight-1, %imagefile%
		Sleep 1000
	}
	
	if(ErrorLevel == 0)
	{
		; Find the middle of the pic
		x += w / 2
		y += h / 2
		Click %x%,%y%
		Return true
	}
	
	Return false
}

AHK_NOTIFYICON(wParam, lParam) ; http://www.autohotkey.com/board/topic/62125-how-do-i-change-the-actions-of-clicking-the-tray-icon/?p=391707
{
	WinGet, Style, Style, League of Legends, League of Legends ; Matchmaker
	visible := Style & 0x10000000 ; 0x10000000 is WS_VISIBLE. 
	
    if (lParam = 0x202) ; WM_LBUTTONUP
	{
		if(visible)
			WinHide, League of Legends, League of Legends ; Matchmaker
		else
		{
			WinShow, League of Legends, League of Legends ; Matchmaker
			WinActivate, League of Legends, League of Legends ; Matchmaker
		}			
	}
	; else if (lParam = 0x205) ; WM_RBUTTONUP
    ;    Menu, Tray, Show
}

update()
{
	static tempFile :=  A_Temp . "out.txt"
	; WshShell object: http://msdn.microsoft.com/en-us/library/aew9yb99
	shell := ComObjCreate("WScript.Shell")
	; Execute a single command via cmd.exe
	exec := shell.Run(ComSpec . " /C git pull >" . tempFile, 0, true)
	; Read and return the command's output
	FileRead, output, %tempFile%
	Msgbox % output
	Reload
	Return
}

Update:
	update()
Return


