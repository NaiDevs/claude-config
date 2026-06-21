# Hook PostToolUse: detecta git commit y escribe en Obsidian Daily
param()

try {
    $json = $input | Out-String
    if (-not $json) { exit 0 }

    $data = $json | ConvertFrom-Json -ErrorAction Stop

    # Extraer la salida del tool
    $resp = $data.tool_response
    $out = ""
    if ($resp -is [string]) {
        $out = $resp
    } elseif ($null -ne $resp.stdout) {
        $out = [string]$resp.stdout
    } elseif ($null -ne $resp.output) {
        $out = [string]$resp.output
    } else {
        $out = $resp | ConvertTo-Json -Depth 5 -Compress
    }

    # Detectar commit exitoso: patrón "[branch hash] mensaje"
    $m = [regex]::Match($out, '\[([^\] ]+) [a-f0-9]{5,}\] (.+)')
    if (-not $m.Success) { exit 0 }

    $branch = $m.Groups[1].Value.Trim()
    $msg    = ($m.Groups[2].Value -split '\\n')[0].Trim()

    # Extraer nombre del proyecto desde -C "path"
    $cmd  = [string]$data.tool_input.command
    $proj = "proyecto"
    if ($cmd -match '-C\s+"([^"]+)"') { $proj = Split-Path $matches[1] -Leaf }
    elseif ($cmd -match "-C\s+'([^']+)'") { $proj = Split-Path $matches[1] -Leaf }
    elseif ($cmd -match '-C\s+(\S+)') { $proj = Split-Path $matches[1] -Leaf }

    # Resolver path del vault de Obsidian — prioridad: env var OBSIDIAN_VAULT > detección por OS
    $vaultBase = $env:OBSIDIAN_VAULT
    if (-not $vaultBase) {
        $isWin = ($env:OS -eq "Windows_NT") -or ($PSVersionTable.Platform -eq "Win32NT") -or (-not $PSVersionTable.Platform)
        if ($isWin) {
            $vaultBase = "$env:USERPROFILE\OneDrive\Documentos\Obsidian"
        } elseif ($IsMacOS) {
            $candidates = @(
                "$HOME/Library/CloudStorage/OneDrive-Personal/Documentos/Obsidian",
                "$HOME/OneDrive/Documentos/Obsidian",
                "$HOME/Documents/Obsidian"
            )
            $vaultBase = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
        } else {
            $vaultBase = "$HOME/OneDrive/Documentos/Obsidian"
        }
    }

    if (-not $vaultBase -or -not (Test-Path $vaultBase)) { exit 0 }

    $today    = Get-Date -Format "yyyy-MM-dd"
    $time     = Get-Date -Format "HH:mm"
    $dailyDir = Join-Path $vaultBase "Daily"
    $dp       = Join-Path $dailyDir "$today.md"

    if (-not (Test-Path $dailyDir)) { New-Item -ItemType Directory -Force $dailyDir | Out-Null }
    if (-not (Test-Path $dp)) { "# $today" | Set-Content $dp -Encoding utf8 }

    "- [$time] commit en $proj ($branch): $msg" | Add-Content $dp -Encoding utf8

} catch {
    exit 0
}

exit 0
