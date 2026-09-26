#!/bin/bash
# openspec-validate.sh — Valida specs contra config OpenSpec
# Verifica consistencia, formato y completitud de los specs.

set -euo pipefail

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

# Función: verificar que existe config.yaml
check_config_exists() {
    if [[ ! -f "openspec/config.yaml" ]]; then
        echo -e "${RED}❌ openspec/config.yaml no encontrado${NC}"
        echo "   Ejecutá: openspec-init para crear uno"
        ((ERRORS++))
        return 1
    fi
    echo -e "${GREEN}✅ openspec/config.yaml existe${NC}"
    return 0
}

# Función: verificar estructura de spec
check_spec_structure() {
    local file="$1"
    local filename
    filename=$(basename "$file")
    
    echo -e "\n${BLUE}Verificando: ${filename}${NC}"
    
    # Verificar frontmatter YAML
    if ! head -1 "$file" | grep -q "^---$"; then
        echo -e "  ${RED}❌ Falta frontmatter YAML (debe empezar con ---)${NC}"
        ((ERRORS++))
    fi
    
    # Verificar campos obligatorios
    local required_fields=("id" "area" "depends_on" "estimated_time")
    for field in "${required_fields[@]}"; do
        if ! grep -q "^${field}:" "$file"; then
            echo -e "  ${RED}❌ Campo obligatorio faltante: ${field}${NC}"
            ((ERRORS++))
        fi
    done
    
    # Verificar sección de Objetivo
    if ! grep -q "^## Objetivo" "$file"; then
        echo -e "  ${RED}❌ Falta sección '## Objetivo'${NC}"
        ((ERRORS++))
    fi
    
    # Verificar sección de Criterios de Éxito
    if ! grep -q "^## Criterios de Éxito" "$file"; then
        echo -e "  ${RED}❌ Falta sección '## Criterios de Éxito'${NC}"
        ((ERRORS++))
    else
        # Verificar que hay al menos un criterio
        local criteria_count
        criteria_count=$(grep -c "^- \[ \]" "$file" 2>/dev/null || echo 0)
        if [[ $criteria_count -lt 1 ]]; then
            echo -e "  ${YELLOW}⚠️  No hay criterios de éxito definidos${NC}"
            ((WARNINGS++))
        fi
    fi
    
    # Verificar escenarios Given/When/Then
    if grep -q "^## Escenarios" "$file"; then
        local scenario_count
        scenario_count=$(grep -c "^### Escenario" "$file" 2>/dev/null || echo 0)
        if [[ $scenario_count -lt 1 ]]; then
            echo -e "  ${YELLOW}⚠️  No hay escenarios definidos${NC}"
            ((WARNINGS++))
        else
            # Verificar estructura Given/When/Then
            local given_count
            given_count=$(grep -c "\*\*Given\*\*" "$file" 2>/dev/null || echo 0)
            local when_count
            when_count=$(grep -c "\*\*When\*\*" "$file" 2>/dev/null || echo 0)
            local then_count
            then_count=$(grep -c "\*\*Then\*\*" "$file" 2>/dev/null || echo 0)
            
            if [[ $given_count -ne $scenario_count ]]; then
                echo -e "  ${RED}❌ Escenarios sin 'Given' (${given_count}/${scenario_count})${NC}"
                ((ERRORS++))
            fi
            if [[ $when_count -ne $scenario_count ]]; then
                echo -e "  ${RED}❌ Escenarios sin 'When' (${when_count}/${scenario_count})${NC}"
                ((ERRORS++))
            fi
            if [[ $then_count -ne $scenario_count ]]; then
                echo -e "  ${RED}❌ Escenarios sin 'Then' (${then_count}/${scenario_count})${NC}"
                ((ERRORS++))
            fi
        fi
    fi
    
    # Verificar RFC 2119 keywords
    if grep -q "^## Reglas" "$file"; then
        local rfc_keywords=("MUST" "SHOULD" "MAY" "SHALL" "RECOMMENDED" "OPTIONAL")
        local has_rfc=false
        for keyword in "${rfc_keywords[@]}"; do
            if grep -q "${keyword}:" "$file"; then
                has_rfc=true
                break
            fi
        done
        if [[ "$has_rfc" == false ]]; then
            echo -e "  ${YELLOW}⚠️  No se usaron keywords RFC 2119 en las reglas${NC}"
            ((WARNINGS++))
        fi
    fi
}

# Función: verificar consistencia con config.yaml
check_config_consistency() {
    local file="$1"
    local filename
    filename=$(basename "$file")
    
    echo -e "\n${BLUE}Verificando consistencia con config.yaml: ${filename}${NC}"
    
    
    # Verificar que el área del spec es válida
    local area
    area=$(grep "^area:" "$file" | head -1 | sed 's/area: //')
    local valid_areas=("backend" "frontend" "qa" "devops" "docs" "design-uiux" "security")
    local valid=false
    for va in "${valid_areas[@]}"; do
        if [[ "$area" == "$va" ]]; then
            valid=true
            break
        fi
    done
    
    if [[ "$valid" == false ]]; then
        echo -e "  ${RED}❌ Área inválida: ${area}${NC}"
        echo -e "     Áreas válidas: ${valid_areas[*]}"
        ((ERRORS++))
    fi
}

# Función: verificar que no hay specs duplicados
check_duplicate_specs() {
    echo -e "\n${BLUE}Verificando specs duplicados...${NC}"
    
    local specs_dir="agentWorkspace"
    if [[ ! -d "$specs_dir" ]]; then
        echo -e "  ${YELLOW}⚠️  agentWorkspace/ no encontrado${NC}"
        return
    fi
    
    # Buscar IDs duplicados
    local ids
    ids=$(find "$specs_dir" -name "*.md" -exec grep "^id:" {} \; | sort)
    local dups
    dups=$(echo "$ids" | uniq -d)
    
    if [[ -n "$dups" ]]; then
        echo -e "  ${RED}❌ IDs duplicados encontrados:${NC}"
        echo "$dups" | while read -r dup; do
            echo -e "     - $dup"
        done
        ((ERRORS++))
    else
        echo -e "  ${GREEN}✅ No hay IDs duplicados${NC}"
    fi
}

# Función: verificar que los depends_on apuntan a specs existentes
check_depends_on() {
    echo -e "\n${BLUE}Verificando dependencias...${NC}"
    
    local specs_dir="agentWorkspace"
    if [[ ! -d "$specs_dir" ]]; then
        return
    fi
    
    # Obtener todos los IDs existentes
    local existing_ids
    existing_ids=$(find "$specs_dir" -name "*.md" -exec grep "^id:" {} \; | sed 's/id: //' | sort)
    
    # Verificar cada spec
    find "$specs_dir" -name "*.md" | while read -r file; do
        local deps
        deps=$(grep "^depends_on:" "$file" | sed 's/depends_on: //')
        
        # Parsear dependencias (formato: [spec1, spec2])
        deps=$(echo "$deps" | tr -d '[]' | tr ',' '\n' | tr -d ' ')
        
        for dep in $deps; do
            if [[ -n "$dep" ]]; then
                if ! echo "$existing_ids" | grep -q "^${dep}$"; then
                    echo -e "  ${RED}❌ $(basename "$file") depende de '${dep}' que no existe${NC}"
                    ((ERRORS++))
                fi
            fi
        done
    done
}

# Función: verificar que no hay archivos protegidos modificados
check_protected_files() {
    echo -e "\n${BLUE}Verificando archivos protegidos...${NC}"
    
    if [[ ! -f "openspec/config.yaml" ]]; then
        return
    fi
    
    # Extraer archivos protegidos del config
    local protected
    protected=$(grep -A20 "^protected:" openspec/config.yaml 2>/dev/null | grep "^- " | sed 's/^- //' || true)
    
    for pattern in $protected; do
        # Verificar si hay cambios en staging que afectan archivos protegidos
        local staged
        staged=$(git diff --cached --name-only 2>/dev/null | grep -E "$pattern" || true)
        if [[ -n "$staged" ]]; then
            echo -e "  ${RED}❌ Archivo protegido en staging: ${staged}${NC}"
            ((ERRORS++))
        fi
    done
}

# Función: generar reporte
generate_report() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║              📊 Reporte de Validación OpenSpec              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    
    if [[ $ERRORS -gt 0 ]]; then
        echo -e "${RED}❌ ${ERRORS} error(es) encontrado(s)${NC}"
    fi
    
    if [[ $WARNINGS -gt 0 ]]; then
        echo -e "${YELLOW}⚠️  ${WARNINGS} warning(s)${NC}"
    fi
    
    if [[ $ERRORS -eq 0 && $WARNINGS -eq 0 ]]; then
        echo -e "${GREEN}✅ Todas las validaciones pasaron${NC}"
    fi
    
    echo ""
}

# Función principal
run_validation() {
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║           🔍 OpenSpec Validation — Workflow Stack           ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Verificar config
    check_config_exists || return 1
    
    # Buscar specs
    local specs
    specs=$(find agentWorkspace -name "*.md" 2>/dev/null || true)
    
    if [[ -z "$specs" ]]; then
        echo -e "${YELLOW}No se encontraron specs en agentWorkspace/${NC}"
        return 0
    fi
    
    # Validar cada spec
    for spec in $specs; do
        check_spec_structure "$spec"
        check_config_consistency "$spec"
    done
    
    # Validaciones globales
    check_duplicate_specs
    check_depends_on
    check_protected_files
    
    # Reporte
    generate_report
    
    return $ERRORS
}

# CLI
case "${1:-validate}" in
    validate)
        run_validation
        ;;
    check)
        run_validation
        ;;
    *)
        echo "Uso: $0 {validate|check}"
        exit 1
        ;;
esac
