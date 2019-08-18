
!include "MUI2.nsh"
;!include "WriteEnvStr.nsh"

;SetCompressor lzma
SetCompress off
Unicode true

Name "Dependencies"
OutFile "Dependencies.exe"

InstallDir "$PROGRAMFILES32\Jack's Mini Network\Dependencies"
InstallDirRegKey HKLM "Software\Jack's Mini Network\Dependencies" "InstallDir"

RequestExecutionLevel admin

Icon "Installer.ico"
UninstallIcon "Installer.ico"

!define MUI_ICON "Installer.ico"
!define MUI_UNICON "Installer.ico"

XPStyle on
ManifestDPIAware true

!define MUI_ABORTWARNING

;!insertmacro MUI_PAGE_LICENSE "../LICENSE"
;!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
  
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"

Section ""
	SectionIn RO
	WriteRegStr HKLM "Software\Jack's Mini Network\Dependencies" "InstallDir" "$INSTDIR"
SectionEnd

Section "" ;"Environment Variables"
	SectionIn RO

	SetOutPath "$INSTDIR"
	ExecWait '"setx.exe" /M "jdependencies_home" "$INSTDIR"'
SectionEnd

Section "" ;"Remove Old Versions"
	SetOutPath "$INSTDIR"

	; clean the old installation
	Delete "$INSTDIR\include\*.h"
	RMDir /r "$INSTDIR\include"

	Delete "$INSTDIR\Lib"
	RMDir /r "$INSTDIR\Lib"
SectionEnd

Section "" ;"Standard Libraries"
	SectionIn RO

	SetOutPath "$INSTDIR"

	File "..\7za.exe"
	File "..\Dependencies.7z"
	;ExecWait '"$OUTDIR\7za.exe" x Dependencies.7z -y'
	nsExec::Exec '"$OUTDIR\7za.exe" x Dependencies.7z -y'
	Pop $0
	Delete "$OUTDIR\Dependencies.7z"
	Delete "$OUTDIR\7za.exe"

	WriteUninstaller "$INSTDIR\Uninstall.exe"

SectionEnd ; end the section

Section "Uninstall"
	Delete "$INSTDIR\include\*.h"
	RMDir /r "$INSTDIR\include"

	Delete "$INSTDIR\Lib"
	RMDir /r "$INSTDIR\Lib"

	DeleteRegKey /ifempty HKLM "Software\Jack's Mini Network\Dependencies"
	Delete "$INSTDIR\Uninstall.exe"
	RMDir "$INSTDIR"
SectionEnd
