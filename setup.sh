#!/bin/bash
# ============================================================================
#  setup.sh — Bootstrap del Workflow Stack Full-Stack
#  Instala y configura TODO el entorno de desarrollo en una sola pasada.
#
#  Uso:
#      git clone https://github.com/AngelAyal4/workflow-toolkit.git
#      cd workflow-toolkit
#      chmod +x setup.sh
#      ./setup.sh
#
#  SOLO EJECUTAR UNA VEZ. Es idempotente: si algo ya está, lo saltea.
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------- Utilidades -----------------------------------------------
green()  { printf '\033[32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }
red()    { printf '\033[31m%s\033[0m\n' "$*"; }
banner() { printf '\n\033[1m%s\033[0m\n' "──── $* ────"; }

have() { command -v "$1" >/dev/null 2>&1; }

# ---------- 1. Paquetes base (Debian/Ubuntu) ---------------------
install_system_pkgs() {
    banner "Paquetes base"
    if ! have apt-get; then
        yellow "  ⚠️ No se detectó apt (Debian/Ubuntu/WSL)."
        yellow "    Instalá manualmente: git, curl, wget, fzf, ripgrep, direnv, herdr, docker."
        return 0
    fi
    sudo apt-get update -qq
    sudo apt-get install -y -qq \
        git curl wget unzip \
        fzf ripgrep \
        direnv \
        docker.io docker-compose-v2

    # Permitir a este usuario usar docker sin sudo (efectivo tras re-login)
    sudo usermod -aG docker "$USER" 2>/dev/null || true
    green "  ✓ paquetes base instalados"
    yellow "  (docker sin sudo: reiniciá sesión o cerrá terminal)"
}

# ---------- 1b. Herdr (multiplexor agent-aware) ------------------
install_herdr() {
    banner "Herdr (multiplexor agent-aware)"
    if have herdr; then
        green "  ✓ herdr $(herdr --version 2>/dev/null | awk '{print $2}') ya instalado"
        return
    fi
    if have curl; then
        curl -fsSL https://herdr.dev/install.sh | sh
        green "  ✓ herdr instalado"
        yellow "  (ejecutá 'herdr' para iniciar)"
    else
        yellow "  ⚠️ curl no encontrado — instalá herdr manualmente desde https://herdr.dev"
    fi
}

# ---------- 2. Node.js LTS --------------------------------------
install_node() {
    if have node && have npm; then
        green "  ✓ Node $(node -v) ya instalado"
        return
    fi
    banner "Node.js LTS"
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y -qq nodejs
    green "  ✓ Node $(node -v)"
}

# ---------- 3. Ollama (modelos locales) ----------------------------
install_ollama() {
    if ! have ollama && [ -z "$(curl -s --max-time 2 http://localhost:11434/api/tags 2>/dev/null)" ]; then
        banner "Ollama"
        curl -fsSL https://ollama.com/install.sh | sh
    fi
    if have ollama; then
        ollama pull llama2-uncensored 2>/dev/null || true
        ollama pull llama3.1:8b 2>/dev/null || true
        green "  ✓ Ollama listo (modelos: llama2-uncensored, llama3.1:8b)"
        yellow "  (si Hermes exige >=64K de contexto, usá llama3.1:8b)"
    fi
}

# ---------- 4. Shell: aliases + hook direnv + GH helper ------------
setup_shell() {
    banner "Aliases y configuración de shell"
    local base="$HOME/.bashrc"

    # aliases (idempotente)
    local aliases_block="# === WORKFLOW STACK ==="
    if ! grep -qF "$aliases_block" "$base" 2>/dev/null; then
        cat >> "$base" <<'EOF'

# === WORKFLOW STACK ===
alias ws='~/scripts/start-workspace.sh'
alias obs='obsidian ~/obsidian-vault &'
alias hdl='herdr workspace list'
alias hda='herdr'
alias da='direnv allow'
alias dr='direnv reload'
alias oc='opencode'
alias gs='git status'
alias ga='git add .'
alias gc='git commit -m'
alias gp='git push'
alias gl='git log --oneline -10'
EOF
        green "  ✓ aliases agregados a $base"
    else
        green "  ✓ aliases ya presentes"
    fi

    # hook de direnv
    if ! grep -q 'direnv hook bash' "$base" 2>/dev/null; then
        echo 'eval "$(direnv hook bash)"' >> "$base"
        green "  ✓ hook de direnv agregado"
    fi

    # git: helper para setting el repo del vault
    if ! grep -q 'alias vault-status' "$base" 2>/dev/null; then
        cat >> "$base" <<'BAS'
# Vault de Obsidian (repo git compartido)
vault(){ cd ~/obsidian-vault && git "$@"; }
BAS
    fi
}

# ---------- 4b. GitHub CLI --------------------------------------
setup_gh() {
    if have gh && gh auth status >/dev/null 2>&1; then
        green "  ✓ GitHub CLI autenticado"
    else
        yellow "  ⚠️ Ejecutá 'gh auth login' para autenticar GitHub CLI"
    fi
}

# ---------- 5. Config de herdr (multiplexor agent-aware) ----------
setup_herdr() {
    banner "Config de herdr (multiplexor agent-aware)"
    mkdir -p "$HOME/.config/herdr"
    cp "$SCRIPT_DIR/configs/herdr.toml" "$HOME/.config/herdr/config.toml" 2>/dev/null || true
    green "  ✓ herdr config listo (prefix ctrl+b)"
}

# ---------- 6. Scripts propios ---------------------------------
setup_scripts() {
    banner "Scripts del workspace"
    mkdir -p "$HOME/scripts"
    cp "$SCRIPT_DIR/scripts/"*.sh "$SCRIPT_DIR/scripts/obsidian-context-bridge.py" "$HOME/scripts/" 2>/dev/null || true
    chmod +x "$HOME/scripts"/*.sh "$HOME/scripts/obsidian-context-bridge.py" 2>/dev/null || true
    green "  ✓ scripts listos"
}

# ---------- 6b. OpenCode Desktop (GUI) --------------------------
setup_opencode_desktop() {
    banner "OpenCode Desktop"
    if command -v ai.opencode.desktop >/dev/null 2>&1; then
        green "  ✓ ya instalado ($(ai.opencode.desktop --version 2>/dev/null | grep -o 'version: [0-9.]*' | head -1 || echo 'desconocido'))"
    else
        yellow "  ⚠️ No instalado — descargalo en https://opencode.ai/docs/desktop"
        yellow "     (o el .deb de tu equipo). El script start-workspace lo abre automaticamente."
    fi
}

# ---------- 7. Plantillas de Obsidian -------------------------------
setup_obsidian_templates() {
    banner "Plantillas de Obsidian"
    mkdir -p "$HOME/obsidian-vault/02-Templates"
    cp -rn "$SCRIPT_DIR/obsidian-templates/"* "$HOME/obsidian-vault/02-Templates/" 2>/dev/null || true
    green "  ✓ plantillas copiadas (proyecto + por stack)"
}

# ---------- 8 Config opencode (solo generar si falta) ------------
setup_opencode() {
    banner "Config de OpenCode"
    mkdir -p "$HOME/.config/opencode/prompts"
    if [ ! -f "$HOME/.config/opencode/opencode.json" ]; then
        # Usar el ejemplo del repo como base
        if [ -f "$SCRIPT_DIR/configs/opencode.example.json" ]; then
            sed "s|~/|$HOME/|g" "$SCRIPT_DIR/configs/opencode.example.json" > "$HOME/.config/opencode/opencode.json"
        else
            cat > "$HOME/.config/opencode/opencode.json" <<'EOF'
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "ollama": {
      "models": { "ollama/llama2-uncensored": { "_launch": true } },
      "name": "Ollama (local)",
      "npm": "@ai-sdk/openai-compatible",
      "options": { "baseURL": "http://127.0.0.1:11434/v1" }
    }
  },
  "mcp": {}
}
EOF
        fi
        green "  ✓ opencode.json generado desde el ejemplo (ajustá paths si difieren)"
    else
        yellow "  ⚠️ opencode.json ya existe — no lo toco (completá MCP/cloud si hace falta)"
    fi
    # Prompt del agente test (QA) — necesario para que {file:./prompts/testeador.md} resuelva
    if [ -f "$SCRIPT_DIR/prompts/testeador.md" ]; then
        cp "$SCRIPT_DIR/prompts/testeador.md" "$HOME/.config/opencode/prompts/testeador.md"
        green "  ✓ prompt del agente test copiado a ~/.config/opencode/prompts/"
    fi
}

# ---------- 8b. Configs de referencia ----------------
setup_configs() {
    banner "Configs de referencia"
    mkdir -p "$HOME/workflow-toolkit-configs"
    cp "$SCRIPT_DIR/configs/"* "$HOME/workflow-toolkit-configs/" 2>/dev/null || true
    green "  ✓ ejemplos guardados en ~/workflow-toolkit-configs (bashrc, opencode, envrc)"
}

# ---------- 8c. Documentación ----------------
setup_docs() {
    banner "Documentación"
    mkdir -p "$HOME/workflow-toolkit-configs/docs"
    cp "$SCRIPT_DIR/docs/"* "$HOME/workflow-toolkit-configs/docs/" 2>/dev/null || true
    green "  ✓ documentación copiada a ~/workflow-toolkit-configs/docs"
}

# ---------- 8d. Sync Obsidian (git bidireccional) ---
setup_obsidian_sync() {
    banner "Sync Obsidian (git)"
    mkdir -p "$HOME/scripts"
    if [ -f "$SCRIPT_DIR/scripts/sync-obsidian.sh" ]; then
        cp "$SCRIPT_DIR/scripts/sync-obsidian.sh" "$HOME/scripts/"
        chmod +x "$HOME/scripts/sync-obsidian.sh"
        green "  ✓ sync-obsidian.sh copiado"
    else
        yellow "  ⚠️ sync-obsidian.sh no encontrado en el repo"
    fi

    # Cron de sync cada 15 minutos (reemplaza backup local)
    mkdir -p "$HOME/backups/obsidian"
    (crontab -l 2>/dev/null | grep -v 'backup-obsidian.sh') | crontab -
    (crontab -l 2>/dev/null; echo "*/15 * * * * \${HOME}/scripts/sync-obsidian.sh >> \${HOME}/backups/obsidian/sync.log 2>&1") | crontab
    green "  ✓ cron sync cada 15 min configurado"
}

# ---------- 9. Cron: backup diario del vault -------------------
setup_cron() {
    banner "Cron de backup"
    local line="0 2 * * * ${HOME}/scripts/backup-obsidian.sh >> ${HOME}/backups/obsidian/backup.log 2>&1"
    mkdir -p "$HOME/backups/obsidian"
    ( crontab -l 2>/dev/null | grep -qv 'backup-obsidian.sh' ) && \
        ( crontab -l 2>/dev/null; echo "$line" ) | crontab || yellow "  ⚠️ no pude tocar crontab"
    green "  ✓ backup programado a las 02:00"
}

# ---------- 10. Obsidian vault (clonar el vault?) --------------
setup_vault() {
    banner "Vault de Obsidian"
    if [ -d "$HOME/obsidian-vault/.git" ]; then
        green "  ✓ vault ya es un repo"
    else
        yellow "  ⚠️ No hay vault git. Opción (para compartir contenido):
           git clone <URL-vault> ~/obsidian-vault"
    fi
}

# ---------- 11. Skills de Hermes ---------------------------------
setup_skills() {
    banner "Skills de Hermes"
    mkdir -p "$HOME/.hermes/skills"
    if [ -d "$SCRIPT_DIR/skills" ]; then
        cp -rn "$SCRIPT_DIR/skills/"* "$HOME/.hermes/skills/" 2>/dev/null || true
        green "  ✓ skills copiadas a ~/.hermes/skills/"
    else
        yellow "  ⚠️ No se encontró directorio skills/ en el repo"
    fi
}

# ==================================================================
# MAIN
# ==================================================================
banner "Workflow Stack Bootstrap"
echo "     Repo: https://github.com/AngelAyal4/workflow-toolkit"
echo "     Distro: $(uname -s) $(uname -m)"
echo ""

install_system_pkgs
install_herdr
install_node
install_ollama
setup_shell
setup_gh
setup_herdr
setup_scripts
setup_opencode_desktop
setup_obsidian_templates
setup_opencode
setup_configs
setup_docs
setup_obsidian_sync
setup_vault
setup_skills

echo ""
banner "✔ Workflow instalado"
echo "
Proximos pasos:
  1. Cerrar y reabrir la terminal (aplicar aliases + grupo docker + direnv)
  2. Configurá tus MCP servers en opencode (obsidian-context, github) y tu provider cloud
  3. En Obsidian activá los plugins: Tasks, Kanban, Dataview, Templater
  4. Levantá tu primer proyecto:   ws mern mi-app
  5. Las skills ya están disponibles en la nueva sesión de Hermes
"