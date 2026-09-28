# Sync Game Mods

[![Lines of Code](https://raw.githubusercontent.com/CodeAnthem/sync-game-mods/images/loc.svg)](https://github.com/CodeAnthem/sync-game-mods/tree/images) [![PowerShell](https://img.shields.io/badge/PowerShell-5391FE?logo=powershell&logoColor=white)](https://learn.microsoft.com/powershell/) [![Windows](https://img.shields.io/badge/Windows-0078D6?logo=windows&logoColor=white)](https://www.microsoft.com/windows)

Mirror selected game folders from a remote share onto a local games folder. The local folder for a game must already exist. When the same folder name exists under the remote root, `robocopy /MIR` copies that folder onto the local one.

Games that are not installed locally, or that are missing on the remote, are skipped.

## Requirements

- Windows
- PowerShell
- `robocopy.exe`, included with Windows

## Files

| File | Role |
| --- | --- |
| `sync-game-mods.ps1` | Sync logic. Several batch files can call this one script with different paths and game lists. |
| `sync-game-mods.template.bat` | Launcher template. Copy it and fill in your paths. |

`.gitignore` ignores every `.bat` file and every `.log` file, then tracks `sync-game-mods.template.bat` again. Your own launchers and the logs they write stay on this PC.

## Create a launcher

1. Copy `sync-game-mods.template.bat` into the same folder as `sync-game-mods.ps1`.
2. Rename the copy, for example `sync-my-games.bat`.
3. Edit the three settings at the top:

```bat
set "REMOTE_ROOT=\\server\share\Games"
set "LOCAL_ROOT=D:\Games"
set "GAMES=Game One,Game Two"
```

`REMOTE_ROOT` is the share that holds the source game folders. `LOCAL_ROOT` is the local games folder. `GAMES` is a comma-separated list of folder names. Each name is one folder under both roots, not a path.

```text
\\server\share\Games\Game One
\\server\share\Games\Game Two

D:\Games\Game One
D:\Games\Game Two
```

`D:\Games\Game One` must already exist. The script does not create a missing local game folder, and it skips a name that is missing on the share.

Optional settings in the same file:

| Setting | Effect |
| --- | --- |
| `EXCLUDE_FILES` | File patterns passed to robocopy as `/XF`. The template skips temp files, logs, dumps, `Thumbs.db`, and `desktop.ini`. |
| `EXCLUDE_DIRS` | Directory names passed as `/XD`. Leave it empty to exclude none. |
| `ROBO_ARGS` | Robocopy switches. The script adds the two folders, `/XF`, and `/XD` itself. |

Copy the template again to keep more than one list. Each copy has its own name, roots, games, and log.

## Run

Double-click the `.bat` file, or run it from a command prompt. The window stays open so you can read the summary.

The script prints one line per game:

| Line | Meaning |
| --- | --- |
| `[OK]` | Mirrored |
| `[SKIP]` | Not installed locally, missing on the remote, or not a single folder name |
| `[FAIL]` | Robocopy exit code 8 or higher |

It then prints counts for synced, skipped, and failed games. The process exits with code `1` when any game failed or a required path was missing. Otherwise it exits with `0`.

## Mirror behavior

`/MIR` copies new and changed files from the remote folder onto the local folder, and deletes local files and folders that are not on the remote. Files you added only on this PC inside a synced game folder are removed on the next run.

The template also passes:

| Switch | Effect |
| --- | --- |
| `/COPY:DAT` | Copy data, attributes, and timestamps |
| `/DCOPY:DAT` | Copy directory timestamps |
| `/FFT` | Treat timestamps within 2 seconds as equal (SMB shares) |
| `/XJ` | Skip junctions and symbolic links |
| `/MT:8` | Copy 8 files at a time |
| `/R:2` `/W:3` | Retry a failed file twice, waiting 3 seconds between retries |
| `/NP` `/NDL` | Hide the progress percentage and directory list |

Other switches you can put in `ROBO_ARGS` are listed in comments in the template, including `/L` (list only, no copy or delete) and `/Z` (restartable copy on a flaky share).

## Log

Each run writes a log next to the batch file that started it, with the same name and a `.log` extension. A launcher named `sync-game-mods.bat` writes `sync-game-mods.log`. The log starts with the time and both roots, then the robocopy output for each game.

## Call the script directly

```bat
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\sync-game-mods.ps1 ^
    -RemoteRoot "\\server\share\Games" ^
    -LocalRoot "D:\Games" ^
    -Games "Game One,Game Two" ^
    -Exclude "*.tmp,*.log" ^
    -RoboArgs "/MIR /FFT /XJ"
```

| Parameter | Required | Meaning |
| --- | --- | --- |
| `-RemoteRoot` | yes | Remote parent folder |
| `-LocalRoot` | yes | Local parent folder |
| `-Games` | yes | Comma-separated folder names |
| `-Exclude` | no | Comma-separated file patterns (`/XF`). If omitted, the script uses its built-in temp, log, and dump list. |
| `-ExcludeDir` | no | Comma-separated directory names (`/XD`) |
| `-RoboArgs` | no | Robocopy switches separated by spaces. If omitted, the script uses the template set and also `/NFL` (hide the file list). |
| `-Caller` | no | Path of the batch file that launched the script. The log is written beside that file. |
| `-LogFile` | no | Explicit log path. Overrides `-Caller`. |
