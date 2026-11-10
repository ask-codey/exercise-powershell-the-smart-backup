# Checks your Backup-File.ps1 by running it for real, job by job.
# Every test runs your script in a throwaway folder of its own, with made-up
# files, so nothing in this exercise folder (or anywhere else) is changed.
# Run it from this folder with: Invoke-Pester
# You don't need to change this file.

BeforeAll {
    $script:script = Join-Path $PSScriptRoot 'Backup-File.ps1'
    $script:pwsh = (Get-Process -Id $PID).Path
    $script:usage = 'Usage: .\Backup-File.ps1 FILE [-Destination FOLDER], or -List or -Menu'

    # A throwaway folder with made-up files, a fresh one for every test.
    function New-PracticeFolder {
        $practice = Join-Path ([System.IO.Path]::GetTempPath()) ('smart-backup-check-' + [guid]::NewGuid())
        New-Item -ItemType Directory -Path $practice, (Join-Path $practice 'photos') | Out-Null
        Set-Content -Path (Join-Path $practice 'essay.txt') -Value 'Why the Town Library Matters', 'First draft, two pages.'
        Set-Content -Path (Join-Path $practice 'notes.txt') -Value 'Chapter 4: read by Friday', 'Lab report due Monday'
        Set-Content -Path (Join-Path $practice 'my essay.txt') -Value 'The second draft, with the quotes fixed.'
        Set-Content -Path (Join-Path $practice 'budget.csv') -Value 'Item,Cost', 'Poster board,4.50'
        Set-Content -Path (Join-Path $practice 'photos\science-fair.jpg') -Value '(a practice photo: the science fair volcano)'
        Set-Content -Path (Join-Path $practice 'poster.png') -Value '(a practice picture: the science fair poster)'
        New-Item -ItemType File -Path (Join-Path $practice 'empty-draft.txt') | Out-Null
        $practice
    }

    # Runs your script in $Folder with these arguments, the way you would from a
    # terminal, and gives back what it printed (one string, lines joined with
    # " | ") and its exit code. -Answers are typed into Read-Host, one a line.
    function Invoke-Backup {
        param([string] $Folder, [string[]] $Arguments = @(), [string[]] $Answers)
        $info = [System.Diagnostics.ProcessStartInfo]::new($script:pwsh)
        foreach ($a in @('-NoProfile', '-NoLogo')) { $info.ArgumentList.Add($a) }
        if (-not $Answers) { $info.ArgumentList.Add('-NonInteractive') }
        $info.ArgumentList.Add('-File')
        $info.ArgumentList.Add($script:script)
        foreach ($a in $Arguments) { $info.ArgumentList.Add($a) }
        $info.WorkingDirectory = $Folder
        $info.RedirectStandardInput = $true
        $info.RedirectStandardOutput = $true
        $info.RedirectStandardError = $true
        $info.UseShellExecute = $false
        $process = [System.Diagnostics.Process]::Start($info)
        $errors = $process.StandardError.ReadToEndAsync()
        $printed = $process.StandardOutput.ReadToEndAsync()
        foreach ($line in $Answers) { $process.StandardInput.WriteLine($line) }
        $process.StandardInput.Close()
        if (-not $process.WaitForExit(30000)) {
            $process.Kill()
            return [pscustomobject]@{ Output = '(it was still waiting after 30 seconds: is a Read-Host asking for more answers than the job gives?)'; ExitCode = -1 }
        }
        $lines = @(($printed.Result + $errors.Result) -split "\r?\n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })
        $text = $lines -join ' | '
        if ($text -match 'not digitally signed|running scripts is disabled') {
            $text = 'PowerShell would not run the script. Run Get-ChildItem -Recurse | Unblock-File once in this folder, then try again.'
        }
        [pscustomobject]@{ Output = $text; ExitCode = $process.ExitCode }
    }
}

Describe 'Exercise: The Smart Backup' {

    BeforeEach {
        # A fresh throwaway folder for every test.
        $practice = New-PracticeFolder
    }

    AfterEach {
        # The throwaway folder goes when the test is done. Only a folder this check made is removed.
        if ((Split-Path -Leaf $practice) -like 'smart-backup-check-*') { Remove-Item -LiteralPath $practice -Recurse -Force }
    }

    It 'the script is here and PowerShell can read it' {
        Test-Path $script | Should -BeTrue -Because 'Backup-File.ps1 should be in this folder. Download the exercise again to get it back'
        $problems = $null
        [System.Management.Automation.Language.Parser]::ParseFile($script, [ref] $null, [ref] $problems) | Out-Null
        $first = if ($problems) { "line $($problems[0].Extent.StartLineNumber): $($problems[0].Message)" } else { 'none' }
        $first | Should -Be 'none' -Because 'PowerShell found a mistake in Backup-File.ps1 before running it. Look at the line it names: a missing } or ) is the usual cause'
    }

    It '1) the parameters: -Path, -Destination, -List and -Menu' {
        $parameters = (Get-Command $script).Parameters
        $found = @('Path', 'Destination', 'List', 'Menu' | Where-Object { $parameters.ContainsKey($_) }) -join ', '
        $found | Should -Be 'Path, Destination, List, Menu' -Because 'job 1 writes a param() block with four parameters: [string]$Path, [string]$Destination = ''backup'', [switch]$List and [switch]$Menu'
        $parameters['Path'].ParameterType.Name | Should -Be 'String' -Because 'job 1 puts [string] in front of $Path'
        $parameters['List'].ParameterType.Name | Should -Be 'SwitchParameter' -Because 'job 1 makes -List a switch: [switch]$List'
        $parameters['Menu'].ParameterType.Name | Should -Be 'SwitchParameter' -Because 'job 1 makes -Menu a switch: [switch]$Menu'
        $first = @($parameters['Path'].ParameterSets.Values)[0].Position
        $first | Should -Be 0 -Because '$Path comes first in param(), so .\Backup-File.ps1 essay.txt works without typing -Path'
    }

    It '2) -Menu, then 1 and a file name: it backs that file up' {
        $run = Invoke-Backup $practice '-Menu' -Answers '1', 'essay.txt'
        $run.Output | Should -Be '1) Back up a file | 2) List the backups | Q) Quit | 1 | essay.txt | Copied essay.txt (a document).' -Because 'job 2 prints the three menu lines, asks Pick one with Read-Host, and for 1 puts Read-Host ''Which file'' into $Path, so the jobs below back it up. (The answers typed into Read-Host show in the output too.)'
    }

    It '2) -Menu, then 2: it lists the backups' {
        New-Item -ItemType Directory -Path (Join-Path $practice 'backup') | Out-Null
        Set-Content -Path (Join-Path $practice 'backup\notes.txt') -Value 'an older copy'
        $run = Invoke-Backup $practice '-Menu' -Answers '2'
        $run.Output | Should -Be '1) Back up a file | 2) List the backups | Q) Quit | 2 | notes.txt' -Because 'for 2, job 2 turns the list on with $List = $true, and job 4 does the listing'
    }

    It '2) -Menu, then Q: it says Bye. and stops' {
        $run = Invoke-Backup $practice '-Menu' -Answers 'Q'
        $run.Output | Should -Be '1) Back up a file | 2) List the backups | Q) Quit | Q | Bye.' -Because 'for q, job 2 prints Bye. and stops with exit 0. A switch ignores capital letters, so Q matches ''q'''
        $run.ExitCode | Should -Be 0 -Because 'Bye. ends the script with exit 0'
    }

    It '2) -Menu, then anything else: it says so and stops with exit code 1' {
        $run = Invoke-Backup $practice '-Menu' -Answers '7'
        $run.Output | Should -Be "1) Back up a file | 2) List the backups | Q) Quit | 7 | There's no 7 on the menu." -Because 'the switch''s default branch prints "There''s no $choice on the menu." and stops with exit 1'
        $run.ExitCode | Should -Be 1 -Because 'a choice that isn''t on the menu ends with exit 1'
    }

    It '3) run with nothing, it prints the usage line and stops with exit code 1' {
        $run = Invoke-Backup $practice
        $run.Output | Should -Be $usage -Because 'job 3 prints only $usage when there''s no -Path and no -List: an if with -not $Path -and -not $List'
        $run.ExitCode | Should -Be 1 -Because 'run with nothing, the script should stop with exit 1'
    }

    It '4) -List says when there are no backups yet' {
        $run = Invoke-Backup $practice '-List'
        $run.Output | Should -Be 'No backups yet.' -Because 'with no backup folder, job 4 prints No backups yet. Test for the folder with Test-Path $Destination'
        $run.ExitCode | Should -Be 0 -Because '-List stops with exit 0'
    }

    It '4) -List shows what is in the backup folder' {
        New-Item -ItemType Directory -Path (Join-Path $practice 'backup') | Out-Null
        Set-Content -Path (Join-Path $practice 'backup\essay.txt') -Value 'an older copy'
        Set-Content -Path (Join-Path $practice 'backup\notes.txt') -Value 'an older copy'
        $run = Invoke-Backup $practice '-List'
        $run.Output | Should -Be 'essay.txt | notes.txt' -Because 'job 4 lists the names in the backup folder with Get-ChildItem -Name, and stops with exit 0'
        $run.ExitCode | Should -Be 0 -Because '-List stops with exit 0'
    }

    It '5) a missing file: it says so and stops with exit code 1' {
        $run = Invoke-Backup $practice 'essay.txs'
        $run.Output | Should -Be "There's no file called essay.txs." -Because 'job 5 checks with -not (Test-Path $Path) before anything else happens to the file'
        $run.ExitCode | Should -Be 1 -Because 'a missing file stops the script with exit 1'
    }

    It '6) a folder: it says so and stops with exit code 1' {
        $run = Invoke-Backup $practice 'photos'
        $run.Output | Should -Be 'photos is a folder. Name a file instead.' -Because 'job 6 checks with Test-Path $Path -PathType Container'
        $run.ExitCode | Should -Be 1 -Because 'a folder stops the script with exit 1'
    }

    It '7) an empty file: it keeps the last good copy' {
        New-Item -ItemType Directory -Path (Join-Path $practice 'backup') | Out-Null
        Set-Content -Path (Join-Path $practice 'backup\empty-draft.txt') -Value 'the last good copy'
        $run = Invoke-Backup $practice 'empty-draft.txt'
        $run.Output | Should -Be 'empty-draft.txt is empty, so the last good copy stays.' -Because 'job 7 checks $file.Length -eq 0 before anything is copied'
        Get-Content -Path (Join-Path $practice 'backup\empty-draft.txt') | Should -Be 'the last good copy' -Because 'an empty file must never replace a good copy'
        $run.ExitCode | Should -Be 0 -Because 'an empty file is not a mistake, so the script stops with exit 0'
    }

    It '8) a file with no copy yet is copied, and the backup folder is made' {
        $run = Invoke-Backup $practice 'essay.txt'
        Test-Path (Join-Path $practice 'backup\essay.txt') | Should -BeTrue -Because 'with no backup folder yet, job 8 makes it (New-Item -ItemType Directory) and job 9 copies the file into it. Its name comes from -Destination''s default, ''backup'''
        $run.Output | Should -Match '^Copied essay\.txt' -Because "the script should say Copied essay.txt (a document). It printed: $($run.Output)"
    }

    It '8) -Destination puts the copy in another folder' {
        $run = Invoke-Backup $practice 'notes.txt', '-Destination', 'usb-stick'
        Test-Path (Join-Path $practice 'usb-stick\notes.txt') | Should -BeTrue -Because "-Destination usb-stick should make the folder usb-stick and copy notes.txt into it. It printed: $($run.Output)"
    }

    It '8) a name with spaces works' {
        $run = Invoke-Backup $practice 'my essay.txt'
        Test-Path -LiteralPath (Join-Path $practice 'backup\my essay.txt') | Should -BeTrue -Because "a name with a space is one value when it's quoted, so 'my essay.txt' should be copied. It printed: $($run.Output)"
    }

    It "8) an unchanged file isn't copied again" {
        New-Item -ItemType Directory -Path (Join-Path $practice 'backup') | Out-Null
        Set-Content -Path (Join-Path $practice 'backup\essay.txt') -Value 'the copy made last time'
        $when = (Get-Date).AddHours(-2)
        (Get-Item (Join-Path $practice 'essay.txt')).LastWriteTime = $when
        (Get-Item (Join-Path $practice 'backup\essay.txt')).LastWriteTime = $when
        $run = Invoke-Backup $practice 'essay.txt'
        $run.Output | Should -Be "essay.txt hasn't changed since the last backup." -Because 'job 8 compares $file.LastWriteTime with the copy''s, and stops when the file isn''t newer'
        Get-Content -Path (Join-Path $practice 'backup\essay.txt') | Should -Be 'the copy made last time' -Because 'an unchanged file is not copied again'
        $run.ExitCode | Should -Be 0 -Because 'nothing to do is not a mistake, so the script stops with exit 0'
    }

    It '8) a changed file is copied again' {
        New-Item -ItemType Directory -Path (Join-Path $practice 'backup') | Out-Null
        Set-Content -Path (Join-Path $practice 'backup\essay.txt') -Value 'the copy made last time'
        (Get-Item (Join-Path $practice 'backup\essay.txt')).LastWriteTime = (Get-Date).AddDays(-2)
        $run = Invoke-Backup $practice 'essay.txt'
        @(Get-Content -Path (Join-Path $practice 'backup\essay.txt'))[0] | Should -Be 'Why the Town Library Matters' -Because "essay.txt is newer than its copy, so job 8 goes on and job 9 copies it again. It printed: $($run.Output)"
    }

    It '9) it says what kind of file it copied' {
        $kinds = @(
            (Invoke-Backup $practice 'essay.txt').Output
            (Invoke-Backup $practice 'photos\science-fair.jpg').Output
            (Invoke-Backup $practice 'poster.png').Output
            (Invoke-Backup $practice 'budget.csv').Output
        ) -join ' | '
        $kinds | Should -Be 'Copied essay.txt (a document). | Copied science-fair.jpg (a photo). | Copied poster.png (a photo). | Copied budget.csv (a file).' -Because 'job 9 uses switch -Wildcard on $file.Name: ''*.txt'' is a document, ''*.jpg'' and ''*.png'' are photos, and default is a file'
    }
}
