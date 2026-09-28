@echo off
setlocal EnableExtensions
cd /d "%~dp0"

rem =====================================================
rem  CONFIG
rem  Copy this file to another .bat name, in the same
rem  folder as sync-game-mods.ps1, then edit the three
rem  values below. Leave this template unchanged.
rem
rem  REMOTE_ROOT  parent folder on the share
rem  LOCAL_ROOT   parent folder on this PC
rem  GAMES        folder names, separated by commas.
rem               Each name is one folder under both roots,
rem               not a path. The local folder must already
rem               exist.
rem =====================================================
set "REMOTE_ROOT=\\server\share\Games"
set "LOCAL_ROOT=D:\Games"
set "GAMES=Game One,Game Two"

set "EXCLUDE_FILES=*.tmp,*.temp,*.log,*.bak,*.old,*.dmp,*.partial,Thumbs.db,desktop.ini"
set "EXCLUDE_DIRS="

rem -----------------------------------------------------
rem  ROBOCOPY SWITCHES
rem  These are the switches this script already understands.
rem  ROBO_ARGS is the list that is actually passed through.
rem  The script adds the remote folder, the local folder,
rem  /XF from EXCLUDE_FILES, and /XD from EXCLUDE_DIRS.
rem
rem  /MIR        mirror: copy everything, delete local extras
rem  /E          copy subfolders, including empty ones
rem  /PURGE      delete local files that are not on the remote
rem  /COPY:DAT   copy data, attributes, and timestamps
rem  /DCOPY:DAT  copy directory timestamps
rem  /FFT        treat timestamps within 2 seconds as equal (SMB)
rem  /XJ         skip junctions and symbolic links
rem  /MT:8       copy 8 files at a time
rem  /R:2        retry a failed file twice
rem  /W:3        wait 3 seconds between retries
rem  /Z          restartable copy, slower, useful on a flaky share
rem  /J          unbuffered copy, useful for large files
rem  /NP         hide the progress percentage
rem  /NFL        hide the file list
rem  /NDL        hide the directory list
rem  /TEE        also print robocopy output in this window
rem  /L          list only; do not copy or delete
rem  /XO         skip files that are newer in the local folder
rem -----------------------------------------------------
set "ROBO_ARGS=/MIR /COPY:DAT /DCOPY:DAT /FFT /XJ /MT:8 /R:2 /W:3 /NP /NDL"



rem =====================================================
rem  RUN
rem =====================================================
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0sync-game-mods.ps1" -Caller "%~f0" -RemoteRoot "%REMOTE_ROOT% " -LocalRoot "%LOCAL_ROOT% " -Games "%GAMES%" -Exclude "%EXCLUDE_FILES%" -ExcludeDir "%EXCLUDE_DIRS%" -RoboArgs "%ROBO_ARGS%"
set RC=%ERRORLEVEL%
pause
exit /b %RC%
