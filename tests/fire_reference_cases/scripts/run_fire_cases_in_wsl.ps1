param(
    [string[]]$Slugs,
    [int]$TimeoutSeconds = 600,
    [switch]$ParseOnSuccess
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$casesRoot = $projectRoot

function Convert-ToWslPath {
    param([string]$Path)

    $full = (Resolve-Path $Path).Path
    $normalized = $full.Replace("\", "/")
    if ($normalized -match "^([A-Za-z]):(.*)$") {
        return "/mnt/" + $matches[1].ToLower() + $matches[2]
    }
    return $normalized
}

if (-not $Slugs -or $Slugs.Count -eq 0) {
    $Slugs = Get-ChildItem $casesRoot -Directory | Select-Object -ExpandProperty Name
}

foreach ($slug in $Slugs) {
    $caseDir = Join-Path $casesRoot $slug
    if (-not (Test-Path $caseDir)) {
        Write-Warning "Skipping missing case directory: $slug"
        continue
    }

    $wslSource = Convert-ToWslPath $caseDir
    $bash = @'
set -euo pipefail
slug="__SLUG__"
source_dir="__SOURCE__"
timeout_s="__TIMEOUT__"
target="/home/lwd/fire_reference_cases/$slug"
rm -rf "$target"
mkdir -p "$target"
cp -a "$source_dir"/. "$target"/
cd "$target"
find . -maxdepth 1 -type f \( -name '*.config' -o -name '*.m' -o -name '*.wl' -o -name '*.md' \) -print0 | xargs -0 sed -i 's/\r$//'

rm -f "${slug}.start" "${slug}.tables" prepare.log fire.log
wolframscript -file PrepareStart.m > prepare.log 2>&1

status=0
if [ ! -f "${slug}.start" ]; then
  status=125
else
set +e
timeout "${timeout_s}" /home/lwd/git/fire/FIRE6/bin/FIRE6 -c "${slug}" > fire.log 2>&1
status=$?
set -e
fi

cp -f prepare.log "$source_dir"/prepare.log || true
[ -f fire.log ] && cp -f fire.log "$source_dir"/fire.log || true
[ -f "${slug}.start" ] && cp -f "${slug}.start" "$source_dir"/"${slug}.start" || true
[ -f "${slug}.tables" ] && cp -f "${slug}.tables" "$source_dir"/"${slug}.tables" || true
exit $status
'@
    $bash = $bash.Replace("__SLUG__", $slug).Replace("__SOURCE__", $wslSource).Replace("__TIMEOUT__", $TimeoutSeconds.ToString())
    $tempScript = Join-Path $env:TEMP ("codex_fire_" + $slug + ".sh")
    [System.IO.File]::WriteAllText($tempScript, ($bash -replace "`r`n", "`n"), [System.Text.Encoding]::ASCII)
    $wslTempScript = Convert-ToWslPath $tempScript

    Write-Host "Running FIRE case $slug ..."
    try {
        wsl bash $wslTempScript
        $exitCode = $LASTEXITCODE
    }
    finally {
        if (Test-Path $tempScript) {
            Remove-Item $tempScript -Force
        }
    }
    if ($exitCode -eq 0) {
        Write-Host "Completed $slug"
        if ($ParseOnSuccess) {
            wolframscript -file (Join-Path $projectRoot "scripts\\parse_fire_reference_tables.wls") $slug
        }
    } elseif ($exitCode -eq 124) {
        Write-Warning "Timeout while running $slug"
    } elseif ($exitCode -eq 125) {
        Write-Warning "PrepareStart did not produce a .start file for $slug"
    } else {
        Write-Warning "FIRE returned exit code $exitCode for $slug"
    }
}
