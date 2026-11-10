# Exercise: The Smart Backup

Exercise code for the lesson **Exercise: The Smart Backup** in PowerShell in Depth on [ask-codey.com](https://www.ask-codey.com).

You'll finish `Backup-File.ps1`, a backup script that's smart about it: it copies a file only when the file changed since its last copy, never lets an empty file replace a good one, turns away folders and typos with a clear message, and says what kind of file it copied. It takes parameters like a command, explains itself when it's run with nothing, lists what's backed up, and has a menu for anyone who doesn't know the parameters. Each job uses one idea from the chapter *Input and Decisions*: `param()`, `Read-Host`, `if`, `elseif` and `else` with `-and`, `-or` and `-not`, and `switch`. A Pester check runs your script job by job and tells you which jobs work.

## What's here

- `Backup-File.ps1`: the script to finish. Each numbered comment in it is a job, with its messages word for word.
- `essay.txt`, `notes.txt`, `reading-list.txt`, `empty-draft.txt` (empty on purpose) and `photos/science-fair.jpg`: practice files to try it on.
- `Check.Tests.ps1`: the check that runs your script. You don't need to change it.

## What to do

Open PowerShell 7 in this folder, the one with `Check.Tests.ps1` in it, and open `Backup-File.ps1` in VS Code (`code Backup-File.ps1`). Write each job's lines under its comment:

1. **The parameters.** A `param()` block with, in this order: `[string]$Path`, `[string]$Destination` with the default `'backup'`, `[switch]$List` and `[switch]$Menu`.
2. **The menu.** With `-Menu`, print `1) Back up a file`, `2) List the backups` and `Q) Quit`, ask `Pick one` with `Read-Host`, and `switch` on the answer: for `1`, ask `Which file` with `Read-Host` and put the answer in `$Path`; for `2`, set `$List = $true`; for `q`, print `Bye.` and `exit 0`; for anything else, print `There's no CHOICE on the menu.` and `exit 1`. The jobs below then do the rest.
3. **Run with nothing.** With no `$Path` and no `$List`, print the usage line (it's in `$usage`) and `exit 1`.
4. **`-List`.** Print the names of the files in the backup folder, or `No backups yet.` when there's no backup folder, then `exit 0`.
5. **A missing file.** Print `There's no file called FILE.` and `exit 1`.
6. **A folder.** Print `FILE is a folder. Name a file instead.` and `exit 1`.
7. **An empty file.** Print `FILE is empty, so the last good copy stays.` and `exit 0`, without copying.
8. **Copy only when needed.** When the backup folder already has a copy and the file isn't newer than it, print `FILE hasn't changed since the last backup.` and `exit 0`. Otherwise make the backup folder if it isn't there, and go on.
9. **Say what kind.** With `switch -Wildcard` on the file's name: `.txt` is `a document`, `.jpg` and `.png` are `a photo`, anything else is `a file`. Copy the file into the backup folder and print `Copied FILE (KIND).`

FILE is the file's name, such as `essay.txt`. Try your script as you go: `.\Backup-File.ps1 essay.txt` twice, `.\Backup-File.ps1 -List`, and `.\Backup-File.ps1 -Menu`.

## Check your work

The check needs Pester 5 or newer. Install it once, if you haven't already:

```powershell
Install-PSResource Pester
```

Then, from this folder:

```powershell
Invoke-Pester
```

At first most tests fail: that is expected. Each job you finish turns its tests green. A failing test's message says which job it is, what it expected and what your script printed. The check runs your script in a throwaway folder of its own, with made-up files, so nothing in this folder is changed.

If PowerShell says a script *cannot be loaded because running scripts is disabled* or *is not digitally signed*, the folder came from a download that Windows marked as from the internet. Unblock its files once with `Get-ChildItem -Recurse | Unblock-File`, from this folder, and try again.

## Tips

- Work from the top: the script runs its jobs in order, and each `exit` stops it there.
- `-not $Path -and -not $List` is True only when neither was given.
- `Test-Path $Path -PathType Container` is True only for a folder.
- `$file.Length -eq 0` is True for an empty file, and `-le` reads "less than or equal".
- `$kind = switch -Wildcard ($file.Name) { … }` keeps what the matching block outputs.
- In `-Menu`, a switch ignores capital letters, so `'q'` matches `Q` too.

## Hand it in

When it works, push your solution to a public repo of your own on GitHub, then paste that repo's address into **Submit your exercise** on the lesson page at [ask-codey.com](https://www.ask-codey.com). That's what completes the lesson. The lesson page shows the Git commands, step by step.
