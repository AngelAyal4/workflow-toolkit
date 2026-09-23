#!/bin/bash
# sync-obsidian.sh — Sync bidireccional del vault de Obsidian vía git
# Se ejecuta desde cron periódicamente para mantener Fedora y Ubuntu sincronizados.

VAULT_PATH="$HOME/obsidian-vault"
cd "$VAULT_PATH" || exit 1

# Verificar que es un repo git
if [ ! -d .git ]; then
    echo "ERROR: $VAULT_PATH no es un repo git"
    exit 1
fi

# Cargar token GitHub desde .bashrc (cron no lo carga)
GITHUB_TOKEN=$(grep '^export GITHUB_TOKEN=' ~/.bashrc 2>/dev/null | sed 's/.*="//' | cut -d'"' -f1)
if [ -n "$GITHUB_TOKEN" ]; then
    export GITHUB_TOKEN
fi

# Configurar identidad git si no está
if ! git config user.name >/dev/null 2>&1; then
    git config user.name "AngelAyal4"
fi
if ! git config user.email >/dev/null 2>&1; then
    git config user.email "ajoseayala.00@gmail.com"
fi

# Verificar si hay cambios locales
if git diff --quiet && git diff --cached --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then
    echo "Sin cambios locales. Solo pull..."
    git pull origin main --rebase 2>&1 || git pull origin main 2>&1
    exit 0
fi

# Commit de cambios locales
git add -A
git commit -m "sync: $(date '+%Y-%m-%d %H:%M:%S') desde $(hostname)" 2>&1

# Push a GitHub
git push origin main 2>&1

# Pull para traer cambios de la otra máquina (si los hay)
git pull origin main --rebase 2>&1 || git pull origin main 2>&1

echo "Sync completado: $(date '+%Y-%m-%d %H:%M:%S')"
