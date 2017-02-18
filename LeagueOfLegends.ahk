#SingleInstance force
#MaxThreads 50
#MaxThreadsPerHotkey 1

;Pour une détection permissive des noms de fenêtres (et de la fenêtre PvP.net si cachée)
; SetTitleMatchMode, 1
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
	FileSelectFile, gameFullPath, 1, %A_ScriptDir%, Veuillez indiquer l`'emplacement du jeu, lol.launcher.exe
	If (ErrorLevel == 1)
		ExitApp
	IniWrite, %gameFullPath%, %iniFile%, General, GameFullPath
}
Menu, tray, Icon, %gameFullPath%, 1 

;Lecture du mot de passe s'il est présent dans le fichier
IniRead, password, %iniFile%, General, password
if (password == "ERROR")
{
	InputBox, password, Quel est le password de votre account ?, La saisie d'un password vous permet de vous logger en utilisant la touche F1 sur le menu PVP.net, HIDE, , , , , , , nopassword
	IniWrite, %password%, %iniFile%, General, password
}

IfWinExist, League of Legends (TM) Client ; In-game
	WinActivate
else IfWinExist, League of Legends ; Matchmaker
	WinActivateMatchMaker()
else IfWinExist, LoL Patcher ; Patcher
	WinActivate
else
	Run, %gameFullPath%
	
;IfWinExist, LoL Patcher ... refaire mot de passe etc...
	
; Minimiser Discord (close réduit au systray)
WinWait, Discord,, 60
WinClose

Return

#IfWinActive League of Legends ; Matchmaker
F1::send %password%{Enter}

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

WinActivateMatchMaker()
{
	WinGet, id, list, League of Legends
	Loop, %id%
		WinActivate, % "ahk_id " . id%A_Index%
}

Update:
	throw Not implemented

	;On prend la dernière mise à jour
	UrlDownloadToFile, https://drive.google.com/open?id=0B2s6BYZ0DlKKV0lFVy1iUVZwSGc, Update.dat
	
	;Si on a pu télécharger un fichier
	if(!ErrorLevel)
	{
		;On remplace l'actuel script par le nouveau (écrasement)
		FileMove, Update.dat, %A_ScriptFullPath%, 1
		
		;Et on relance le script
		Reload
	}
	Else
		MsgBox Aucune version n'a été trouvée en ligne
Return



