# Sync Game Mods

![Lines of Code](https://raw.githubusercontent.com/CodeAnthem/sync-game-mods/images/loc.svg) ![PowerShell](https://img.shields.io/badge/PowerShell-5391FE?logo=powershell&logoColor=white) ![Windows](https://img.shields.io/badge/Windows-0078D6?logo=windows&logoColor=white)

Mirror selected game folders from a share onto this PC. Windows 10 or later.

```text
\\server\share\Games              D:\Games
        Game One      ------->    Game One
        Game Two      ------->    Game Two
        Game Three    xxxxxxxx
                      xxxxxxxx    Game Four
```

For each configured game:

- Skip it when that folder is missing on the share or on this PC
- Otherwise mirror the share folder onto the local one



## Features

- Temp files are skipped by default.
- Files and folders can be excluded in the configuration.
- Robocopy arguments can be changed. The comments in the batch file explain each switch.



## Quick start

1. Download the [latest release](https://github.com/CodeAnthem/sync-game-mods/releases/latest) and unpack the zip.
2. Optionally rename `sync-game-mods.template.bat`, for example to `sync-my-games.bat`.
3. Make sure the games folder is a share this PC can reach. Read-only access is enough.
4. Set the paths in the batch file:

```bat
set "REMOTE_ROOT=\\server\share\Games"
set "LOCAL_ROOT=D:\Games"
set "GAMES=Game One,Game Two"
```

1. Double-click the batch file on the PC that should receive the game files.
2. Optionally check the log written next to the batch file.

You can keep several batch files, each with its own configuration.