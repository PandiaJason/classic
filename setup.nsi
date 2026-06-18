!define PRODUCT_NAME "ranotot"
!define PRODUCT_VERSION "1.0"
!define PRODUCT_PUBLISHER "hikki studios"
!define PRODUCT_WEB_SITE "https://hikkistudios.com"

# Compression settings
SetCompressor lzma

Name "${PRODUCT_NAME}"
OutFile "exports/ranotot_setup.exe"
InstallDir "$LOCALAPPDATA\ranotot"
RequestExecutionLevel user

# Pages
Page license
Page directory
Page instfiles

UninstPage uninstConfirm
UninstPage instfiles

LicenseData "license.txt"

Section "install"
  SetOutPath "$INSTDIR"
  
  # Put files there
  File "exports/ranotot.exe"
  File "exports/ranotot.pck"
  File "license.txt"
  
  # Uninstaller
  WriteUninstaller "$INSTDIR\uninstall.exe"
  
  # Desktop shortcut
  CreateShortcut "$DESKTOP\ranotot.lnk" "$INSTDIR\ranotot.exe" "" "$INSTDIR\ranotot.exe" 0
  
  # Start menu shortcuts
  CreateDirectory "$SMPROGRAMS\ranotot"
  CreateShortcut "$SMPROGRAMS\ranotot\ranotot.lnk" "$INSTDIR\ranotot.exe" "" "$INSTDIR\ranotot.exe" 0
  CreateShortcut "$SMPROGRAMS\ranotot\uninstall.lnk" "$INSTDIR\uninstall.exe" "" "$INSTDIR\uninstall.exe" 0
  
  # Registry settings for Add/Remove Programs
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\ranotot" "DisplayName" "ranotot"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\ranotot" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\ranotot" "Publisher" "${PRODUCT_PUBLISHER}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\ranotot" "DisplayIcon" '"$INSTDIR\ranotot.exe"'
SectionEnd

Section "uninstall"
  # Remove shortcuts
  Delete "$DESKTOP\ranotot.lnk"
  Delete "$SMPROGRAMS\ranotot\ranotot.lnk"
  Delete "$SMPROGRAMS\ranotot\uninstall.lnk"
  RMDir "$SMPROGRAMS\ranotot"
  
  # Remove registry keys
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\ranotot"
  
  # Remove files
  Delete "$INSTDIR\ranotot.exe"
  Delete "$INSTDIR\ranotot.pck"
  Delete "$INSTDIR\license.txt"
  Delete "$INSTDIR\uninstall.exe"
  
  # Remove directory
  RMDir "$INSTDIR"
SectionEnd
