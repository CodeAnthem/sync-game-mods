# Sync Game Mods

Mirror selected game folders from a remote share onto a local games folder. The local folder for a game must already exist. If the same folder name also exists under the remote root, its contents are copied onto the local folder with `robocopy /MIR`.

Use this when mods, saves, or other game files live on a share and you want the matching local install kept in sync. Games that are not installed locally, or that are missing on the remote, are skipped.

## Requirements

- Windows
- PowerShell
- `robocopy.exe` (included with Windows)

## Files

| File | Role |
| --- | --- |
| `sync-game-mods.ps1` | Sync logic. Several batch files can call this one script with different paths and game lists. |
| `sync-game-mods.template.bat` | Launcher template. Copy it and fill in your paths. |

`.gitignore` ignores every `.bat` file, then puts `sync-game-mods.template.bat` back. Your own launchers and the `.log` files they write stay on this PC.

## Create a launcher

1. Copy `sync-game-mods.template.bat` in the same folder as `sync-game-mods.ps1`.
2. Rename the copy, for example `sync-my-games.bat`.
3. Edit the three settings at the top:

```bat
set "REMOTE_ROOT=\\server\share\Games"
set "LOCAL_ROOT=D:\Games"
set "GAMES=Game One,Game Two"
```

`REMOTE_ROOT` is the share that holds the source game folders. `LOCAL_ROOT` is the local games folder. `GAMES` is a comma-separated list of folder names. Each name is a single folder under both roots, not a path.

For that example the folders look like this:

```text
\\server\share\Games\Game One
\\server\share\Games\Game Two

D:\Games\Game One
D:\Games\Game Two
```

`D:\Games\Game One` must already exist. The script does not create a game folder that is missing locally, and it skips a name that is missing on the share.

Optional settings in the same file:

- `EXCLUDE_FILES` — file patterns passed to robocopy as `/XF`. The template skips temp files, logs, dumps, `Thumbs.db`, and `desktop.ini`.
- `EXCLUDE_DIRS` — directory names passed as `/XD`. Leave it empty to exclude none.
- `ROBO_ARGS` — robocopy switches. The script adds the two folders, `/XF`, and `/XD` itself.

To keep more than one list, copy the template again and give the new file its own name, roots, and games. Each copy logs beside itself.

## Run

Double-click your `.bat` file, or run it from a command prompt. The window stays open at the end so you can read the summary.

The script prints one line per game:

- `[OK]` — mirrored
- `[SKIP]` — not installed locally, missing on the remote, or not a single folder name
- `[FAIL]` — robocopy exit code 8 or higher

It then prints counts for synced, skipped, and failed games. The process exits with code `1` if any game failed or a required path was missing. Otherwise it exits with `0`.

## Mirror behavior

`/MIR` copies new and changed files from the remote folder onto the local folder, and deletes local files and folders that are not on the remote. Anything you added only on this PC inside a synced game folder will be removed on the next run.

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
| `-RoboArgs` | no | Robocopy switches separated by spaces. If omitted, the script uses the same set as the template. |
| `-Caller` | no | Path of the batch file that launched the script. The log is written beside that file. |
| `-LogFile` | no | Explicit log path. Overrides `-Caller`. |
