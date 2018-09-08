
!include "MUI2.nsh"
;!include "WriteEnvStr.nsh"

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
!insertmacro MUI_PAGE_COMPONENTS
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
	ExecWait '"setx.exe" /M "dependencies" "$INSTDIR"'
SectionEnd

Section "" ;"Remove Old Versions"
	SetOutPath "$INSTDIR"

	; clean the old installation
	Delete "$INSTDIR\include\*.h"
	RMDir /r "$INSTDIR\include"

	Delete "$INSTDIR\Lib"
	RMDir /r "$INSTDIR\Lib"
SectionEnd

Section "Visual Studio 2010"
	;SetOutPath "$INSTDIR\Lib\x64\v100"
	;File /r "..\Build\Lib\x64\v100\"

	;SetOutPath "$INSTDIR\Lib\x64\v100_static"
	;File /r "..\Build\Lib\x64\v100_static\"

	SetOutPath "$INSTDIR\Lib\x86\v100"
	File /r "..\Build\Lib\x86\v100\"

	SetOutPath "$INSTDIR\Lib\x86\v100_static"
	File /r "..\Build\Lib\x86\v100_static\"
SectionEnd

Section "Visual Studio 2015"
	;SetOutPath "$INSTDIR\Lib\x64\v140"
	;File /r "..\Build\Lib\x64\v140\"

	;SetOutPath "$INSTDIR\Lib\x64\v140_static"
	;File /r "..\Build\Lib\x64\v140_static\"

	;SetOutPath "$INSTDIR\Lib\x64\v140_xp"
	;File /r "..\Build\Lib\x64\v140_xp\"

	;SetOutPath "$INSTDIR\Lib\x64\v140_xp_static"
	;File /r "..\Build\Lib\x64\v140_xp_static\"

	SetOutPath "$INSTDIR\Lib\x86\v140"
	File /r "..\Build\Lib\x86\v140\"

	SetOutPath "$INSTDIR\Lib\x86\v140_static"
	File /r "..\Build\Lib\x86\v140_static\"

	SetOutPath "$INSTDIR\Lib\x86\v140_xp"
	File /r "..\Build\Lib\x86\v140_xp\"

	SetOutPath "$INSTDIR\Lib\x86\v140_xp_static"
	File /r "..\Build\Lib\x86\v140_xp_static\"
SectionEnd

Section "Visual Studio 2017"
	;SetOutPath "$INSTDIR\Lib\x64\v141"
	;File /r "..\Build\Lib\x64\v141\"

	;SetOutPath "$INSTDIR\Lib\x64\v141_static"
	;File /r "..\Build\Lib\x64\v141_static\"

	;SetOutPath "$INSTDIR\Lib\x64\v141_xp"
	;File /r "..\Build\Lib\x64\v141_xp\"

	;SetOutPath "$INSTDIR\Lib\x64\v141_xp_static"
	;File /r "..\Build\Lib\x64\v141_xp_static\"

	SetOutPath "$INSTDIR\Lib\x86\v141"
	File /r "..\Build\Lib\x86\v141\"

	SetOutPath "$INSTDIR\Lib\x86\v141_static"
	File /r "..\Build\Lib\x86\v141_static\"

	SetOutPath "$INSTDIR\Lib\x86\v141_xp"
	File /r "..\Build\Lib\x86\v141_xp\"

	SetOutPath "$INSTDIR\Lib\x86\v141_xp_static"
	File /r "..\Build\Lib\x86\v141_xp_static\"
SectionEnd

Section "" ;"Standard Libraries"
	SectionIn RO

	SetOutPath "$INSTDIR"

	SetOutPath "$INSTDIR\include"
	File /r "..\Build\include\"

	;SetOutPath "$INSTDIR\Lib"
	;File /r "..\Lib\"

	SetOutPath "$INSTDIR"

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
