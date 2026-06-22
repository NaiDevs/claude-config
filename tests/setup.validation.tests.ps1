# tests/setup.validation.tests.ps1
# Pester v5 — valida que setup.ps1 instala los archivos correctos
# Uso: Invoke-Pester ./tests/setup.validation.tests.ps1 -Output Detailed

BeforeAll {
    $IsWin      = ($env:OS -eq "Windows_NT") -or ($PSVersionTable.Platform -eq "Win32NT") -or (-not $PSVersionTable.Platform)
    $HomeDir    = if ($IsWin) { $env:USERPROFILE } else { $HOME }
    $ClaudeHome = if ($IsWin) { "$HomeDir\.claude" } else { "$HomeDir/.claude" }
    $CodexHome  = if ($IsWin) { "$HomeDir\.codex"  } else { "$HomeDir/.codex"  }
    $ScriptDir  = Split-Path -Parent $PSScriptRoot

    $EncodedHome = if ($IsWin) {
        $HomeDir -replace "^([A-Za-z]):\\", '$1--' -replace "\\", "-"
    } else {
        $HomeDir -replace "^/", "" -replace "/", "-"
    }
    $MemoryPath = Join-Path $ClaudeHome "projects\$EncodedHome\memory"
}

Describe "Herramientas del sistema" {
    It "git esta disponible" {
        Get-Command git -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    It "Node.js esta disponible" {
        Get-Command node -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
    It "npm esta disponible" {
        Get-Command npm -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
}

Describe "Claude Code — archivos instalados" {
    It "CLAUDE.md existe" {
        Test-Path "$ClaudeHome\CLAUDE.md" | Should -BeTrue
    }
    It "commands/ tiene archivos .md" {
        $count = (Get-ChildItem "$ClaudeHome\commands\*.md" -ErrorAction SilentlyContinue).Count
        $count | Should -BeGreaterThan 0
    }
    It "settings.json es JSON valido" {
        { Get-Content "$ClaudeHome\settings.json" -Raw | ConvertFrom-Json } | Should -Not -Throw
    }
    It "settings.json tiene mcpServers" {
        $s = Get-Content "$ClaudeHome\settings.json" -Raw | ConvertFrom-Json
        $s.mcpServers | Should -Not -BeNullOrEmpty
    }
    It "settings.json tiene hooks PostToolUse" {
        $s = Get-Content "$ClaudeHome\settings.json" -Raw | ConvertFrom-Json
        $s.hooks.PostToolUse | Should -Not -BeNullOrEmpty
    }
    It "settings.json tiene hook Stop" {
        $s = Get-Content "$ClaudeHome\settings.json" -Raw | ConvertFrom-Json
        $s.hooks.Stop | Should -Not -BeNullOrEmpty
    }
    It "projects-registry.md existe" {
        Test-Path "$ClaudeHome\projects-registry.md" | Should -BeTrue
    }
    It "hook on-git-commit.ps1 existe" {
        Test-Path "$ClaudeHome\hooks\on-git-commit.ps1" | Should -BeTrue
    }
    It "carpeta de memoria existe" {
        Test-Path $MemoryPath | Should -BeTrue
    }
    It "MEMORY.md no tiene entradas duplicadas" {
        $memPath = Join-Path $MemoryPath "MEMORY.md"
        if (-not (Test-Path $memPath)) { Set-ItResult -Skipped -Because "MEMORY.md no existe aun" }
        $lines = Get-Content $memPath | Where-Object { $_ -match '^\- \[' }
        $unique = $lines | Select-Object -Unique
        $lines.Count | Should -Be $unique.Count
    }
}

Describe "Claude Code — skills instalados" {
    BeforeAll {
        $repoSkills = (Get-ChildItem "$ScriptDir\commands\*.md" -ErrorAction SilentlyContinue).BaseName
    }
    It "todos los skills del repo estan en commands/" {
        foreach ($skill in $repoSkills) {
            Test-Path "$ClaudeHome\commands\$skill.md" | Should -BeTrue -Because "$skill.md debe estar instalado"
        }
    }
}

Describe "Codex — archivos instalados" {
    BeforeEach {
        if (-not (Test-Path $CodexHome)) {
            Set-ItResult -Skipped -Because "Codex no esta instalado en este equipo"
        }
    }
    It "config.toml existe" {
        Test-Path "$CodexHome\config.toml" | Should -BeTrue
    }
    It "config.toml tiene MCPs configurados" {
        $content = Get-Content "$CodexHome\config.toml" -Raw -ErrorAction SilentlyContinue
        $content | Should -Match '\[mcp_servers\.'
    }
    It "skills/ tiene directorios" {
        $count = (Get-ChildItem "$CodexHome\skills" -Directory -ErrorAction SilentlyContinue).Count
        $count | Should -BeGreaterThan 0
    }
    It "projects-registry.md existe" {
        Test-Path "$CodexHome\projects-registry.md" | Should -BeTrue
    }
}

Describe "Repo — archivos criticos" {
    It "mcp.env.example existe" {
        Test-Path "$ScriptDir\mcp.env.example" | Should -BeTrue
    }
    It "mcp.env NO esta commiteado al repo" {
        $tracked = git -C $ScriptDir ls-files "mcp.env" 2>$null
        $tracked | Should -BeNullOrEmpty
    }
    It "CLAUDE.md existe en el repo" {
        Test-Path "$ScriptDir\CLAUDE.md" | Should -BeTrue
    }
    It "projects-registry.md existe en el repo" {
        Test-Path "$ScriptDir\projects-registry.md" | Should -BeTrue
    }
    It "hooks/on-git-commit.ps1 existe en el repo" {
        Test-Path "$ScriptDir\hooks\on-git-commit.ps1" | Should -BeTrue
    }
    It "memory/MEMORY.md no tiene duplicados en el repo" {
        $memPath = "$ScriptDir\memory\MEMORY.md"
        if (-not (Test-Path $memPath)) { Set-ItResult -Skipped -Because "no existe aun" }
        $lines  = Get-Content $memPath | Where-Object { $_ -match '^\- \[' }
        $unique = $lines | Select-Object -Unique
        $lines.Count | Should -Be $unique.Count
    }
}

Describe "Seguridad — secretos" {
    It "mcp.env no esta en git tracking" {
        $tracked = git -C $ScriptDir ls-files "mcp.env" 2>$null
        $tracked | Should -BeNullOrEmpty
    }
    It ".gitignore incluye mcp.env" {
        $gi = Get-Content "$ScriptDir\.gitignore" -Raw -ErrorAction SilentlyContinue
        $gi | Should -Match 'mcp\.env'
    }
    It "settings.json no contiene tokens (no 'ghp_' ni 'sk-')" {
        $s = Get-Content "$ClaudeHome\settings.json" -Raw -ErrorAction SilentlyContinue
        if (-not $s) { Set-ItResult -Skipped -Because "settings.json no existe" }
        $s | Should -Not -Match 'ghp_[A-Za-z0-9]+'
        $s | Should -Not -Match 'sk-[A-Za-z0-9]+'
    }
}
