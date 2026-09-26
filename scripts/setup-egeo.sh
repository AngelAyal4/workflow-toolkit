#!/bin/bash
# setup-egeo.sh — Instala o actualiza eGEOagents (toolkit GEO/AEO, MIT)
# Uso: bash setup-egeo.sh
# Instala en ~/workspace/tools/eGEOagents y deja el prompt listo en workflow-toolkit.

set -e

TOOLS_DIR="$HOME/workspace/tools"
REPO_DIR="$TOOLS_DIR/eGEOagents"
WORKFLOW="$HOME/workflow-toolkit"
PROMPT_DST="$WORKFLOW/prompts/04-geo-optimizer.md"

echo "==> eGEOagents setup"
echo "    Repo: $REPO_DIR"

# 1. Instalar o actualizar el repo (shallow clone — solo la rama principal)
if [ -d "$REPO_DIR/.git" ]; then
    echo "==> Repo existente: actualizando..."
    git -C "$REPO_DIR" fetch origin --depth 1
    git -C "$REPO_DIR" reset --hard origin/main
else
    echo "==> Clonando eGEOagents (shallow)..."
    mkdir -p "$TOOLS_DIR"
    git clone --depth 1 https://github.com/mverab/eGEOagents.git "$REPO_DIR"
fi

# 2. Dependencias Python (solo para la CLI egeo — opcional)
if command -v python3 >/dev/null 2>&1; then
    echo "==> Verificando deps Python (pyyaml, jsonschema)..."
    python3 -c "import yaml, jsonschema" 2>/dev/null || \
        echo "    ⚠️  Faltan deps (pip install pyyaml jsonschema). La CLI 'egeo' requiere el agente LLM; el flujo normal usa el prompt GEO directamente."
fi

# 3. Verificar que el prompt GEO del workflow-toolkit existe (se crea manualmente)
if [ -f "$PROMPT_DST" ]; then
    echo "==> Prompt GEO presente: $PROMPT_DST"
else
    echo "==> ⚠️  Prompt GEO no encontrado: crealo con el contenido de prompts/04-geo-optimizer.md (o copialo del repo en .claude/commands/)."
fi

echo ""
echo "==> ✅ eGEOagents listo."
echo "    - Repo:  $REPO_DIR"
echo "    - CLI:   cd $REPO_DIR && python3 -m egeo --help"
echo "    - Uso:   pegar workflow-toolkit/prompts/04-geo-optimizer.md en opencode (agente build/geo)"
echo "    - Docs:  $REPO_DIR/docs/getting-started.md"
