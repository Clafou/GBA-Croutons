# Microsoft Developer Studio Project File - Name="Tetris4k" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 6.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) External Target" 0x0106

CFG=Tetris4k - Win32 Debug
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "Tetris4k.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "Tetris4k.mak" CFG="Tetris4k - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "Tetris4k - Win32 Release" (based on "Win32 (x86) External Target")
!MESSAGE "Tetris4k - Win32 Debug" (based on "Win32 (x86) External Target")
!MESSAGE 

# Begin Project
# PROP AllowPerConfigDependencies 0
# PROP Scc_ProjName ""
# PROP Scc_LocalPath ""

!IF  "$(CFG)" == "Tetris4k - Win32 Release"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "Release"
# PROP BASE Intermediate_Dir "Release"
# PROP BASE Cmd_Line "NMAKE /f Tetris4k.mak"
# PROP BASE Rebuild_Opt "/a"
# PROP BASE Target_File "Tetris4k.exe"
# PROP BASE Bsc_Name "Tetris4k.bsc"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "Release"
# PROP Intermediate_Dir "Release"
# PROP Cmd_Line "NMAKE /f Tetris4k.mak"
# PROP Rebuild_Opt "/a"
# PROP Target_File "Tetris4k.exe"
# PROP Bsc_Name "Tetris4k.bsc"
# PROP Target_Dir ""

!ELSEIF  "$(CFG)" == "Tetris4k - Win32 Debug"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "Debug"
# PROP BASE Intermediate_Dir "Debug"
# PROP BASE Cmd_Line "NMAKE /f Tetris4k.mak"
# PROP BASE Rebuild_Opt "/a"
# PROP BASE Target_File "Tetris4k.exe"
# PROP BASE Bsc_Name "Tetris4k.bsc"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "Debug"
# PROP Intermediate_Dir "Debug"
# PROP Cmd_Line "NMAKE /f Tetris4k.mak"
# PROP Rebuild_Opt "/a"
# PROP Target_File "Tetris4k.exe"
# PROP Bsc_Name "Tetris4k.bsc"
# PROP Target_Dir ""

!ENDIF 

# Begin Target

# Name "Tetris4k - Win32 Release"
# Name "Tetris4k - Win32 Debug"

!IF  "$(CFG)" == "Tetris4k - Win32 Release"

!ELSEIF  "$(CFG)" == "Tetris4k - Win32 Debug"

!ENDIF 

# Begin Group "Source Files"

# PROP Default_Filter "cpp;c;cxx;rc;def;r;odl;idl;hpj;bat"
# Begin Source File

SOURCE=.\crt0.s
# End Source File
# Begin Source File

SOURCE=.\FontMinimal.js
# End Source File
# Begin Source File

SOURCE=.\Spring.js
# End Source File
# Begin Source File

SOURCE=.\Strings.js
# End Source File
# Begin Source File

SOURCE=.\Tetris4k.s
# End Source File
# End Group
# Begin Source File

SOURCE=.\Linkscript
# End Source File
# Begin Source File

SOURCE=".\Strings Ascii.txt"
# End Source File
# Begin Source File

SOURCE=.\Tetris4k.mak
# End Source File
# End Target
# End Project
