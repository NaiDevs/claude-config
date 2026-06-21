# Hook PostToolUse: detecta git commit y escribe en Obsidian Daily
param()

try {
    $json = $input | Out-String
    if (-not $json) { exit 0 }

    $data = $json | ConvertFrom-Json -ErrorAction Stop

    # Extraer la salida del tool — puede venir en distintos campos según la versión de Claude Code
    $resp = $data.tool_response
    $out = ""
    if ($resp -is [string]) {
        $out = $resp
    } elseif ($null -ne $resp.stdout) {
        $out = [string]$resp.stdout
    } elseif ($null -ne $resp.output) {
        $out = [string]$resp.output
    } else {
        # Fallback: serializar todo el objeto y buscar el patrón en el JSON
        $out = $resp | ConvertTo-Json -Depth 5 -Compress
    }

    # Detectar si hubo commit exitoso: patrón "[branch hash] mensaje"
    $m = [regex]::Match($out, '\[([^\] ]+) [a-f0-9]{5,}\] (.+)')
    if (-not $m.Success) { exit 0 }

    $branch = $m.Groups[1].Value.Trim()
    $msg    = ($m.Groups[2].Value -split '\\n')[0].Trim()

    # Extraer nombre del proyecto desde -C "path"
    $cmd  = [string]$data.tool_input.command
    $proj = "proyecto"
    if ($cmd -match '-C\s+"?([^"]+)"?') {
        $proj = Split-Path $matches[1] -Leaf
    } elseif ($cmd -match '-C\s+''?([^'']+)''?') {
        $proj = Split-Path $matches[1] -Leaf
    }

    $today = Get-Date -Format "yyyy-MM-dd"
    $time  = Get-Date -Format "HH:mm"
    $dp    = "C:\Users\naide\OneDrive\Documentos\Obsidian\Daily\$today.md"

    if (-not (Test-Path $dp)) {
        "# $today" | Set-Content $dp -Encoding utf8
    }

    "- [$time] commit en $proj ($branch): $msg" | Add-Content $dp -Encoding utf8

} catch {
    # No bloquear el flujo si algo falla — silencio
    exit 0
}

exit 0
