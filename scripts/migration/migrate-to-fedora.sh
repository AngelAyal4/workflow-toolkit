#!/usr/bin/env bash
# =============================================================================
# MIGRATION SCRIPT: Ubuntu → Fedora
# Ejecutar desde la máquina Ubuntu (origen)
# =============================================================================
# Uso: ./migrate-to-fedora.sh [USER@]HOST_FEDORA [PUERTO]
# Ejemplo: ./migrate-to-fedora.sh angel@192.168.1.5
# =============================================================================

set -euo pipefail

# --- Configuración ---
FEDORA_HOST="${1:?ERROR: Especificar host Fedora (ej: angel@192.168.1.5)}"
SSH_PORT="${2:-22}"
UBU_HOME="/home/compu"
FED_HOME="/home/angel"
LOG_FILE="/tmp/migration-$(date +%Y%m%d-%H%M%S).log"

# Directorios y archivos a migrar (relativos a $HOME o rutas absolutas)
MIGRATE_PATHS=(
    "$UBU_HOME/workflow-toolkit"
    "$UBU_HOME/obsidian-vault"
    "$UBU_HOME/scripts"
    "$UBU_HOME/.config/tmux"
    "$UBU_HOME/.config/opencode"
    "$UBU_HOME/.config/gh"
    "$UBU_HOME/.config/hermes"
    "$UBU_HOME/.config/direnv"
    "$UBU_HOME/.config/tiling-assistant"
    "$UBU_HOME/.bashrc"
    "$UBU_HOME/.gitconfig"
)

# Archivos individuales SSH a copiar (NO claves privadas)
SSH_FILES=(
    "$UBU_HOME/.ssh/authorized_keys"
    "$UBU_HOME/.ssh/known_hosts"
)

# Patrones a excluir (rsync --exclude)
EXCLUDES=(
    # Basura y temporales
    ".DS_Store"
    "Thumbs.db"
    "*.tmp"
    "*.swp"
    "*.bak"
    "*~"
    "__pycache__"
    "*.pyc"
    ".venv/"
    "venv/"
    "env/"
    ".tox/"
    "*.egg-info/"
    "node_modules/"
    
    # Hermes: estado dinámico y credenciales (NO migrar)
    ".hermes/auth.json*"
    ".hermes/auth.lock"
    ".hermes/gateway.*"
    ".hermes/state.db*"
    ".hermes/processes.json"
    ".hermes/cron/cron.db"
    ".hermes/sessions/"
    ".hermes/terminal-sessions/"
    ".hermes/sandboxes/"
    ".hermes/pending_messages/"
    ".hermes/pairing/"
    ".hermes/bootstrap-cache/"
    ".hermes/desktop/desktop-build-stamp.json"
    ".hermes/desktop-plugins/"
    ".hermes/logs/"
    ".hermes/spawn-ledger.json"
    ".hermes/verification_evidence.db"
    ".hermes/projects.db"
    ".hermes/kanban.db*"
    ".hermes/context_length_cache.yaml"
    ".hermes/provider_models_cache.json"
    ".hermes/ollama_cloud_models_cache.json"
    ".hermes/models_dev_cache.*"
    ".hermes/hermes-agent/"
    ".hermes/runtime/"
    ".hermes/platforms/"
    ".hermes/state-snapshots/"
    ".hermes/shared/"
    ".hermes/image_cache/"
    ".hermes/audio_cache/"
    ".hermes/pastes/"
    ".hermes/pets/"
    ".hermes/hooks/"
    ".hermes/lsp/"
    ".hermes/node/"
    ".hermes/cache/"
    ".hermes/install_id"
    ".hermes/tui-theme-boot.json"
    ".hermes/google_client_secret.json"
    ".hermes/google_token.json"
    
    # Git dentro de proyectos (se clonan frescos si hace falta)
    # No excluimos .git de workflow-toolkit porque queremos el historial
    
    # Obsidian: caché y plugins que pueden conflictuar
    ".obsidian/workspace.json"
    ".obsidian/workspace-mobile.json"
    ".obsidian/appearance.json"
    ".obsidian/core-plugins-migration.json"
    ".obsidian/app.json"
)

# Construir argumentos de exclusión
EXCLUDE_ARGS=()
for pattern in "${EXCLUDES[@]}"; do
    EXCLUDE_ARGS+=(--exclude="$pattern")
done

# --- Funciones ---
log() {
    echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

check_ssh() {
    log "Verificando conexión SSH a $FEDORA_HOST..."
    if ! ssh -o ConnectTimeout=10 -o BatchMode=yes -p "$SSH_PORT" "$FEDORA_HOST" "echo SSH_OK" 2>/dev/null | grep -q "SSH_OK"; then
        log "ERROR: No se pudo conectar por SSH a $FEDORA_HOST:$SSH_PORT"
        log "Verificá que:"
        log "  1. La clave SSH está en authorized_keys de Fedora"
        log "  2. sshd está corriendo en Fedora"
        log "  3. El puerto $SSH_PORT está abierto"
        exit 1
    fi
    log "✓ Conexión SSH OK"
}

fedora_mkdirs() {
    log "Creando estructura de directorios en Fedora..."
    ssh -p "$SSH_PORT" "$FEDORA_HOST" "mkdir -p \
        $FED_HOME/workflow-toolkit \
        $FED_HOME/obsidian-vault \
        $FED_HOME/scripts \
        $FED_HOME/.config/tmux \
        $FED_HOME/.config/opencode \
        $FED_HOME/.config/gh \
        $FED_HOME/.config/hermes \
        $FED_HOME/.config/direnv \
        $FED_HOME/.config/tiling-assistant \
        $FED_HOME/.ssh"
    log "✓ Directorios creados"
}

sync_path() {
    local src="$1"
    local filename
    filename=$(basename "$src")
    
    if [ ! -e "$src" ]; then
        log "⚠ OMITIDO: $src (no existe)"
        return
    fi
    
    log "Sincronizando: $src"
    
    # Si es directorio, sincronizar contenido
    if [ -d "$src" ]; then
        rsync -avz --progress \
            -e "ssh -p $SSH_PORT" \
            "${EXCLUDE_ARGS[@]}" \
            --delete \
            "$src/" \
            "$FEDORA_HOST:$FED_HOME/$filename/" \
            2>&1 | tee -a "$LOG_FILE"
    else
        # Si es archivo, copiar directo
        rsync -avz --progress \
            -e "ssh -p $SSH_PORT" \
            "$src" \
            "$FEDORA_HOST:$FED_HOME/$filename" \
            2>&1 | tee -a "$LOG_FILE"
    fi
    
    log "✓ $filename sincronizado"
}

sync_ssh_files() {
    log "Sincronizando archivos SSH..."
    for f in "${SSH_FILES[@]}"; do
        if [ -f "$f" ]; then
            local fname
            fname=$(basename "$f")
            rsync -avz -e "ssh -p $SSH_PORT" "$f" "$FEDORA_HOST:$FED_HOME/.ssh/$fname" 2>&1 | tee -a "$LOG_FILE"
            log "✓ $fname sincronizado"
        fi
    done
}

fix_permissions() {
    log "Ajustando permisos en Fedora..."
    ssh -p "$SSH_PORT" "$FEDORA_HOST" "chmod 700 $FED_HOME/.ssh && chmod 600 $FED_HOME/.ssh/*"
    log "✓ Permisos SSH ajustados"
}

fix_paths() {
    log "Reemplazando paths /home/compu → $FED_HOME en archivos migrados..."
    
    # En workflow-toolkit/scripts/start-workspace.sh y otros scripts
    ssh -p "$SSH_PORT" "$FEDORA_HOST" "
        # Fix bashrc
        if [ -f $FED_HOME/.bashrc ]; then
            sed -i 's|/home/compu|/home/angel|g' $FED_HOME/.bashrc
        fi
        
        # Fix tmux.conf paths si referencian home
        if [ -f $FED_HOME/.config/tmux/tmux.conf ]; then
            sed -i 's|/home/compu|/home/angel|g' $FED_HOME/.config/tmux/tmux.conf
        fi
        
        # Fix opencode config si existe
        if [ -f $FED_HOME/.config/opencode/config.yaml ]; then
            sed -i 's|/home/compu|/home/angel|g' $FED_HOME/.config/opencode/config.yaml
        fi
        
        # Fix hermes config.yaml si existe
        if [ -f $FED_HOME/.config/hermes/config.yaml ]; then
            sed -i 's|/home/compu|/home/angel|g' $FED_HOME/.config/hermes/config.yaml
        fi
    "
    
    log "✓ Paths corregidos"
}

print_summary() {
    echo ""
    echo "========================================"
    echo "  MIGRACIÓN COMPLETADA"
    echo "========================================"
    echo ""
    echo "  Log: $LOG_FILE"
    echo ""
    echo "  Lo que se migró:"
    echo "    • workflow-toolkit (repo completo con .git)"
    echo "    • obsidian-vault (notas completas)"
    echo "    • scripts/ (backup-obsidian, context-bridge)"
    echo "    • tmux.conf (prefix C-a, tema Tokyo Night)"
    echo "    • .bashrc (aliases: ws, oc, sail, gs/gc/gp)"
    echo "    • .gitconfig (name/email)"
    echo "    • gh CLI config"
    echo "    • opencode config"
    echo "    • hermes/ (skills, profiles, cron, config.yaml)"
    echo "    • SSH (authorized_keys, known_hosts)"
    echo ""
    echo "  Lo que NO se migró (por seguridad):"
    echo "    ✗ Claves SSH privadas (generar nuevas)"
    echo "    ✗ Hermes auth.json (autenticar de nuevo)"
    echo "    ✗ Sesiones activas, state.db, processes"
    echo "    ✗ node_modules, .venv, cachés"
    echo ""
    echo "  ========================================"
    echo "  POST-MIGRACIÓN (ejecutar en Fedora):"
    echo "  ========================================"
    echo ""
    echo "  1. Instalar dependencias:"
    echo "     sudo dnf install tmux git gh direnv python3-paramiko"
    echo ""
    echo "  2. Instalar OpenCode:"
    echo "     curl -fsSL https://opencode.ai/install | bash"
    echo "     # Agregar al PATH: export PATH=\$HOME/.opencode/bin:\$PATH"
    echo ""
    echo "  3. Instalar Hermes Agent:"
    echo "     # Seguir docs: https://hermes-agent.nousresearch.com/docs"
    echo ""
    echo "  4. Generar nueva clave SSH para Fedora:"
    echo "     ssh-keygen -t ed25519 -C 'angel@fedora'"
    echo "     # Luego agregar a GitHub: gh auth login"
    echo ""
    echo "  5. Verificar shell (Fedora usa zsh por defecto):"
    echo "     # Si usás bash:"
    echo "     chsh -s /bin/bash"
    echo "     # Si usás zsh, fuente .bashrc desde .zshrc:"
    echo "     echo '[ -f ~/.bashrc ] && source ~/.bashrc' >> ~/.zshrc"
    echo ""
    echo "  6. Abrir tmux y probar:"
    echo "     tmux new -s test"
    echo ""
    echo "  ========================================"
    echo ""
}

# --- Ejecución principal ---
echo "========================================"
echo "  MIGRACIÓN Ubuntu → Fedora"
echo "========================================"
echo "  Origen: $UBU_HOME (Ubuntu)"
echo "  Destino: $FED_HOME@$FEDORA_HOST (Fedora)"
echo "  Log: $LOG_FILE"
echo "========================================"
echo ""

check_ssh
fedora_mkdirs

# Migrar cada ruta
for path in "${MIGRATE_PATHS[@]}"; do
    sync_path "$path"
done

# SSH files
sync_ssh_files

# Post-procesamiento
fix_permissions
fix_paths

# Resumen
print_summary

echo "Log completo: $LOG_FILE"
