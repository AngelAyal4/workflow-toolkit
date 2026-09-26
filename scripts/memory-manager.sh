#!/bin/bash
# memory-manager.sh — Sistema de memoria extendido con global/ y project/ + TTL
# Basado en Engram de Gentleman Programming

set -euo pipefail

# Configuración
MEMORY_DIR="${MEMORY_DIR:-./memory}"
MAX_MEMORY_AGE_DAYS="${MAX_MEMORY_AGE_DAYS:-90}"
MAX_MEMORY_INDEX_LINES=200

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Función: inicializar estructura de memoria
init_memory() {
    local project_path="${1:-.}"
    local project_name
    project_name=$(basename "$(cd "$project_path" && pwd)")
    
    echo "Inicializando estructura de memoria para: $project_name"
    
    # Memoria del proyecto
    mkdir -p "$project_path/memory/project"
    mkdir -p "$project_path/memory/global"
    
    # Crear MEMORY.md del proyecto si no existe
    if [[ ! -f "$project_path/memory/MEMORY.md" ]]; then
        cat > "$project_path/memory/MEMORY.md" <<EOF
# MEMORY.md — Índice de memoria del proyecto: $project_name

## Proyecto (\`memory/project/\`)
(Un archivo por tema en memory/project/, cada entrada: \`- [Title](project/file.md) — hook\` <150 chars)

## Global (\`memory/global/\`)
(Memorías cross-proyecto relevantes para este proyecto)

## Reglas
- MEMORY.md es un ÍNDICE (líneas < 150 chars), nunca contenido directo
- Confirmar el índice < ${MAX_MEMORY_INDEX_LINES} líneas
- Actualizar/eliminar memorias viejas o erradas; sin duplicados
- Fechas del usuario → absolutas. Secuencia → orden de prioridad.
- Datos sensibles NO se guardan salvo pedido explícito
- TTL: Las memorías caducan después de ${MAX_MEMORY_AGE_DAYS} días (usá \`memory-manager gc\` para limpiar)
EOF
    fi
    
    # Crear .gitignore para memoria
    if [[ ! -f "$project_path/memory/.gitignore" ]]; then
        cat > "$project_path/memory/.gitignore" <<EOF
# No subir memorias globales (son locales)
/global/
EOF
    fi
    
    echo -e "${GREEN}✅ Estructura de memoria inicializada${NC}"
}

# Función: agregar memoria
add_memory() {
    local type="${1:-project}"  # project o global
    local title="${2:-}"
    local content="${3:-}"
    local project_path="${4:-.}"
    
    if [[ -z "$title" ]]; then
        echo -e "${RED}Error: Título requerido${NC}"
        return 1
    fi
    
    local target_dir="$project_path/memory/$type"
    mkdir -p "$target_dir"
    
    local filename
    filename=$(echo "$title" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-')
    local filepath="$target_dir/${filename}.md"
    
    cat > "$filepath" <<EOF
---
name: ${filename}
description: ${title}
metadata:
  type: ${type}
  created: $(date -Iseconds)
  expires: $(date -Iseconds -d "+${MAX_MEMORY_AGE_DAYS} days" 2>/dev/null || date -v+${MAX_MEMORY_AGE_DAYS}d -Iseconds 2>/dev/null || echo "never")
---

${content}
EOF
    
    echo -e "${GREEN}✅ Memoria agregada: ${filepath}${NC}"
    
    # Actualizar índice
    update_index "$project_path"
}

# Función: actualizar índice MEMORY.md
update_index() {
    local project_path="${1:-.}"
    local memory_file="$project_path/memory/MEMORY.md"
    
    local project_entries=""
    local global_entries=""
    
    # Entradas de project/
    if [[ -d "$project_path/memory/project" ]]; then
        for f in "$project_path/memory/project"/*.md; do
            [[ -f "$f" ]] || continue
            local name
            name=$(basename "$f" .md)
            local desc
            desc=$(grep "^description:" "$f" 2>/dev/null | head -1 | sed 's/description: //')
            project_entries+="- [${name}](project/${name}.md) — ${desc}\n"
        done
    fi
    
    # Entradas de global/
    if [[ -d "$project_path/memory/global" ]]; then
        for f in "$project_path/memory/global"/*.md; do
            [[ -f "$f" ]] || continue
            local name
            name=$(basename "$f" .md)
            local desc
            desc=$(grep "^description:" "$f" 2>/dev/null | head -1 | sed 's/description: //')
            global_entries+="- [${name}](global/${name}.md) — ${desc}\n"
        done
    fi
    
    # Reescribir MEMORY.md
    cat > "$memory_file" <<EOF
# MEMORY.md — Índice de memoria

## Proyecto (\`memory/project/\`)
${project_entries:-"(sin memorias de proyecto)"}

## Global (\`memory/global/\`)
${global_entries:-"(sin memorias globales)"}

## Reglas
- MEMORY.md es un ÍNDICE (líneas < 150 chars), nunca contenido directo
- Confirmar el índice < ${MAX_MEMORY_INDEX_LINES} líneas
- Actualizar/eliminar memorias viejas o erradas; sin duplicados
- Fechas del usuario → absolutas. Secuencia → orden de prioridad.
- Datos sensibles NO se guardan salvo pedido explícito
- TTL: Las memorías caducan después de ${MAX_MEMORY_AGE_DAYS} días
EOF
}

# Función: garbage collection (limpiar memorias caducadas)
gc() {
    local project_path="${1:-.}"
    local cleaned=0
    
    echo "🧹 Limpiando memorias caducadas..."
    
    for type in project global; do
        local dir="$project_path/memory/$type"
        [[ -d "$dir" ]] || continue
        
        for f in "$dir"/*.md; do
            [[ -f "$f" ]] || continue
            
            local expires
            expires=$(grep "^expires:" "$f" 2>/dev/null | head -1 | sed 's/expires: //')
            
            if [[ "$expires" != "never" && -n "$expires" ]]; then
                local expires_epoch
                expires_epoch=$(date -d "$expires" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%S" "$expires" +%s 2>/dev/null || echo 0)
                local now_epoch
                now_epoch=$(date +%s)
                
                if [[ $expires_epoch -lt $now_epoch ]]; then
                    echo "  🗑️  Caducado: $f (expiró: $expires)"
                    rm "$f"
                    ((cleaned++))
                fi
            fi
        done
    done
    
    # Actualizar índice
    update_index "$project_path"
    
    echo -e "${GREEN}✅ Limpieza completada: ${cleaned} memoria(s) eliminada(s)${NC}"
}

# Función: mostrar estado
status() {
    local project_path="${1:-.}"
    
    echo "=== Estado de Memoria ==="
    
    local project_count=0
    local global_count=0
    
    [[ -d "$project_path/memory/project" ]] && project_count=$(find "$project_path/memory/project" -name "*.md" 2>/dev/null | wc -l)
    [[ -d "$project_path/memory/global" ]] && global_count=$(find "$project_path/memory/global" -name "*.md" 2>/dev/null | wc -l)
    
    echo "  Proyecto: ${project_count} memorias"
    echo "  Global:   ${global_count} memorias"
    echo "  TTL:      ${MAX_MEMORY_AGE_DAYS} días"
}

# CLI
case "${1:-status}" in
    init)
        init_memory "${2:-.}"
        ;;
    add)
        add_memory "${2:-project}" "${3:-}" "${4:-}" "${5:-.}"
        ;;
    gc)
        gc "${2:-.}"
        ;;
    status)
        status "${2:-.}"
        ;;
    *)
        echo "Uso: $0 {init|add|gc|status} [args]"
        echo ""
        echo "Comandos:"
        echo "  init [path]              — Inicializar estructura de memoria"
        echo "  add <type> <title> <content> [path] — Agregar memoria"
        echo "  gc [path]                — Limpiar memorias caducadas"
        echo "  status [path]            — Mostrar estado"
        exit 1
        ;;
esac
