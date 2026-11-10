# Backup-File.ps1: copies one file into a backup folder, but only when it's needed.
#
#   .\Backup-File.ps1 FILE                       back up FILE, if it changed since its last backup
#   .\Backup-File.ps1 FILE -Destination FOLDER   back it up into another folder (backup is the default)
#   .\Backup-File.ps1 -List                      show what's in the backup folder
#   .\Backup-File.ps1 -Menu                      choose what to do from a menu
#
# Each numbered comment below is a job for you. The messages are given exactly,
# because the check compares them word for word. FILE stands for the file's
# name: for essay.txs, job 5 prints "There's no file called essay.txs."


# 1. The parameters, in this order: -Path, a [string]; -Destination, a [string]
#    whose default is 'backup'; and two switches, -List and -Menu.
param(
)

$usage = 'Usage: .\Backup-File.ps1 FILE [-Destination FOLDER], or -List or -Menu'

# 2. -Menu: print these three lines, then ask "Pick one" with Read-Host:
#      1) Back up a file
#      2) List the backups
#      Q) Quit
#    Then a switch on the answer:
#      1: ask "Which file" with Read-Host, and put the answer in $Path.
#      2: turn the list on, with $List = $true.
#      q: print "Bye." and stop with exit 0.
#      anything else: print "There's no CHOICE on the menu." (CHOICE is what
#      was typed) and stop with exit 1.
#    After the menu, the script carries on below, with $Path or $List set.


# 3. No file and no -List: print the usage line, and stop with exit 1.


# 4. -List: print the names of the files in the backup folder, or
#    "No backups yet." when there's no backup folder. Stop with exit 0 either way.


# 5. No such file: print "There's no file called FILE." and stop with exit 1.


# 6. A folder: print "FILE is a folder. Name a file instead." and stop with exit 1.


# From here on, $file is the file itself ($file.Name, $file.Length,
# $file.LastWriteTime), and $copy is where its backup goes.
$file = Get-Item $Path
$copy = Join-Path $Destination $file.Name

# 7. An empty file (its Length is 0): print "FILE is empty, so the last good
#    copy stays." and stop with exit 0.


# 8. Copy only when it's needed. If $copy is there and FILE isn't newer than it,
#    print "FILE hasn't changed since the last backup." and stop with exit 0.
#    Otherwise, make the backup folder if it isn't there, and go on to job 9.


# 9. Say what kind of file it is, with a switch on its name: a .txt file is
#    "a document", a .jpg or .png file is "a photo", and anything else is
#    "a file". Copy it into the backup folder, then print "Copied FILE (KIND)."

