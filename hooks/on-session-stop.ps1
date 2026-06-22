# Hook Stop: lee el transcript de la sesion y escribe resumen en Obsidian Daily
param()

try {
    $json = $input | Out-String
    if (-not $json -or $json.Trim() -eq "") { exit 0 }

    $data = $json | ConvertFrom-Json -ErrorAction Stop
    $sessionId = [string]$data.session_id
    if (-not $sessionId) { exit 0 }

    # Ubicacion del transcript
    $transcriptPath = "$env:USERPROFILE\.claude\projects\C--Users-naide\$sessionId.jsonl"
    if (-not (Test-Path $transcriptPath)) { exit 0 }

    # Extraer los primeros mensajes reales del usuario
    $userMessages = @()
    foreach ($line in (Get-Content $transcriptPath -Encoding utf8 -ErrorAction SilentlyContinue)) {
        try {
            $obj = $line | ConvertFrom-Json -ErrorAction SilentlyContinue
            if ($obj.type -eq "user" -and $obj.message.role -eq "user") {
                $content = $obj.message.content
                $text = ""
                if ($content -is [string]) {
                    $text = $content.Trim()
                } elseif ($content -is [array]) {
                    $textBlock = $content | Where-Object { $_.type -eq "text" } | Select-Object -First 1
                    if ($textBlock) { $text = [string]$textBlock.text.Trim() }
                }
                # Filtrar: ignorar mensajes cortos, de sistema, o contenido de skills (empieza con #)
                if ($text.Length -gt 5 -and
                    -not $text.StartsWith("<") -and
                    -not $text.StartsWith("#") -and
                    -not $text.StartsWith("---")) {
                    $short = if ($text.Length -gt 90) { $text.Substring(0, 90) + "..." } else { $text }
                    $userMessages += ($short -replace "`n", " " -replace "`r", "")
                }
            }
        } catch {}
        if ($userMessages.Count -ge 5) { break }
    }

    # No registrar sesiones triviales
    if ($userMessages.Count -lt 2) { exit 0 }

    $vaultBase = if ($env:OBSIDIAN_VAULT) { $env:OBSIDIAN_VAULT } else { "$env:USERPROFILE\OneDrive\Documentos\Obsidian" }
    if (-not (Test-Path $vaultBase)) { exit 0 }

    $today    = Get-Date -Format "yyyy-MM-dd"
    $time     = Get-Date -Format "HH:mm"
    $dailyDir = Join-Path $vaultBase "Daily"
    $dp       = Join-Path $dailyDir "$today.md"

    if (-not (Test-Path $dailyDir)) { New-Item -ItemType Directory -Force $dailyDir | Out-Null }
    if (-not (Test-Path $dp)) {
        [System.IO.File]::WriteAllText($dp, "# $today`n", [System.Text.Encoding]::UTF8)
    }

    $summary = "`n## Sesion Claude $time`n"
    foreach ($msg in $userMessages) {
        $summary += "- $msg`n"
    }

    [System.IO.File]::AppendAllText($dp, $summary, [System.Text.Encoding]::UTF8)

} catch {
    exit 0
}

exit 0
