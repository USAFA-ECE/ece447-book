<#
.SYNOPSIS
    Rebuild the ECE 447 lesson slide decks from the Overleaf LaTeX source.

.DESCRIPTION
    The slide decks live in the Overleaf project "ECE447-faculty (Fall NN)", not in
    this repo -- only the exported PDFs are committed here. This script rebuilds them
    locally so a slide edit doesn't require exporting 25 PDFs by hand from Overleaf.

    Workflow:
      1. In Overleaf: Menu -> Download -> Source (.zip)
      2. Extract it somewhere (e.g. C:\Users\<you>\Documents\ece447-slides-src)
      3. Run this script pointed at that folder

    The driver ECE447_Slides_Fa25.tex selects a lesson via \lessonNumIn, so each deck
    is one pdflatex invocation. Lesson numbers are discovered from the files in
    Lesson_Slides\, so adding a new deck needs no change here.

.PARAMETER ProjectDir
    Folder holding the extracted Overleaf source (contains ECE447_Slides_Fa25.tex).

.PARAMETER OutDir
    Where finished PDFs land. Defaults to this repo's book\_static.

.PARAMETER Lessons
    Optional explicit lesson numbers to build. Default: all discovered.

.EXAMPLE
    .\tools\build_slides.ps1 -ProjectDir C:\Users\DFEC\Documents\ece447-slides-src

.EXAMPLE
    .\tools\build_slides.ps1 -ProjectDir ..\src -Lessons 24,25
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)] [string] $ProjectDir,
    [string] $OutDir,
    [int[]] $Lessons
)

# Must be Continue, not Stop: pdflatex writes benign notices (e.g. the MiKTeX
# "you have not checked for updates" nag) to stderr, and PowerShell 5.1 wraps native
# stderr as NativeCommandError -- which under Stop aborts the whole build. Failures
# are detected explicitly below by checking for the output PDF.
$ErrorActionPreference = "Continue"

# Lesson 39 is authored in PowerPoint, not beamer. Its Lsn39 LaTeX source is only a
# 2-frame schedule/admin placeholder -- building it would replace the real 22-page
# OFDM/MIMO/CDMA deck with a stub. It carries no semester date, so it needs no rebuild.
$SKIP = @{ 39 = "authored in PowerPoint; LaTeX source is a placeholder stub" }

# --- locate pdflatex -------------------------------------------------------------
# MiKTeX installs per-user and PATH updates don't reach already-running processes,
# so fall back to the default install location.
if (-not (Get-Command pdflatex -ErrorAction SilentlyContinue)) {
    $mik = Join-Path $env:LOCALAPPDATA "Programs\MiKTeX\miktex\bin\x64"
    if (Test-Path (Join-Path $mik "pdflatex.exe")) {
        $env:PATH = "$mik;$env:PATH"
    } else {
        throw "pdflatex not found. Install MiKTeX:  winget install --id MiKTeX.MiKTeX -e"
    }
}

$ProjectDir = (Resolve-Path $ProjectDir).Path
$main = Join-Path $ProjectDir "ECE447_Slides_Fa25.tex"
if (-not (Test-Path $main)) { throw "No ECE447_Slides_Fa25.tex in $ProjectDir" }

if (-not $OutDir) { $OutDir = Join-Path $PSScriptRoot "..\book\_static" }
$OutDir = (Resolve-Path $OutDir).Path
$build  = Join-Path $ProjectDir "build"
New-Item -ItemType Directory -Force $build | Out-Null

# --- discover lessons ------------------------------------------------------------
if (-not $Lessons) {
    $Lessons = Get-ChildItem (Join-Path $ProjectDir "Lesson_Slides") -Filter "Lsn*_Slides.tex" |
        ForEach-Object { if ($_.Name -match "^Lsn0*(\d+)_") { [int]$Matches[1] } } |
        Sort-Object
}

Push-Location $ProjectDir
$built = @(); $failed = @(); $skipped = @()

foreach ($n in $Lessons) {
    if ($SKIP.ContainsKey($n)) { $skipped += "Lesson $n  --  $($SKIP[$n])"; continue }

    $job = "lesson$n"
    $arg = "\def\lessonNumIn{$n}\input{ECE447_Slides_Fa25.tex}"

    # Two passes: beamer needs the second for stable frame counts in the footer.
    foreach ($pass in 1, 2) {
        & pdflatex -interaction=nonstopmode -file-line-error "-output-directory=build" `
                   "-jobname=$job" $arg 2>&1 | Out-Null
    }

    $pdf = Join-Path $build "$job.pdf"
    if (-not (Test-Path $pdf)) {
        $log = Join-Path $build "$job.log"
        $why = if (Test-Path $log) {
            (Select-String -Path $log -Pattern "^.*:\d+:.*$" | Select-Object -First 1).Line
        } else { "no log produced" }
        $failed += "Lesson $n  --  $why"
        continue
    }

    # Sanity check before publishing: the deck must not carry a semester string, and
    # should not be wildly shorter than the version already published (which would
    # suggest a stub source, as happened with Lesson 39).
    $dest = Join-Path $OutDir "ECE447_Lesson$n.pdf"
    $warn = ""
    if (Get-Command pdftotext -ErrorAction SilentlyContinue) {
        $txt = & pdftotext -layout $pdf - 2>$null | Out-String
        if ($txt -match "(Fall|Spring|Summer)\s*20\d\d") { $warn += " [WARN: semester date present]" }
        $newPages = [regex]::Matches($txt, "\f").Count
        if (Test-Path $dest) {
            $oldTxt   = & pdftotext -layout $dest - 2>$null | Out-String
            $oldPages = [regex]::Matches($oldTxt, "\f").Count
            if ($oldPages -gt 0 -and $newPages -lt ($oldPages * 0.6)) {
                $failed += "Lesson $n  --  built $newPages pages vs $oldPages published; refusing to overwrite"
                continue
            }
        }
    }

    Copy-Item $pdf $dest -Force
    $built += ("Lesson {0,-3} {1,4} KB{2}" -f $n, [math]::Round((Get-Item $dest).Length / 1KB), $warn)
}

Pop-Location

Write-Output "===== BUILT ($($built.Count)) -> $OutDir ====="
$built | ForEach-Object { Write-Output "  $_" }
if ($skipped.Count) {
    Write-Output "`n===== SKIPPED ($($skipped.Count)) ====="
    $skipped | ForEach-Object { Write-Output "  $_" }
}
Write-Output "`n===== FAILED ($($failed.Count)) ====="
if ($failed.Count -eq 0) { Write-Output "  (none)" } else { $failed | ForEach-Object { Write-Output "  $_" } }
if ($failed.Count) { exit 1 }
