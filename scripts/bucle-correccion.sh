#!/bin/bash
# bucle-correccion.sh — Bucle de corrección automática SDD (build → test → fix → test...)
#
# Uso:
#   bash bucle-correccion.sh <proyecto> [--max-iter 3] [--model <provider/model>] [--spec <spec.md>]
#
# Ejemplos:
#   bash bucle-correccion.sh ~/workspace/projects/pern-nextjs/ditahelp
#   bash bucle-correccion.sh . --max-iter 5 --spec specs/feature-turnos.md
#
# Cómo funciona:
#   1. Corré el TESTEADOR (opencode run --agent test) con el prompt de testeador.md
#   2. El testeador escribe qa-report.md en la raíz del proyecto (veredicto: APROBADO/RECHAZADO)
#   3. Si APROBADO → fin. Si RECHAZADO → corré el CORRECTOR (opencode run --agent build)
#      con prompts/corrector.md + el reporte → vuelve a testear
#   4. Hasta --max-iter iteraciones o aprobación
#
# Requisitos: opencode CLI instalado (opencode run), prompts en ~/workflow-toolkit/prompts/

set -euo pipefail

WORKFLOW="${WORKFLOW_STACK:-$HOME/workflow-toolkit}"
PROMPTS_DIR="$WORKFLOW/prompts"
TESTER_PROMPT="$PROMPTS_DIR/testeador.md"
CORRECTOR_PROMPT="$PROMPTS_DIR/corrector.md"
MAX_ITER=3
MODEL=""
SPEC=""
AUTO=""
# ── Parseo de args ────────────────────────────────────────────────
PROJECT_PATH="${1:-}"
if [ -z "$PROJECT_PATH" ] || [ ! -d "$PROJECT_PATH" ]; then
    echo "❌ Uso: bucle-correccion.sh <proyecto> [--max-iter N] [--model provider/model] [--spec spec.md] [--auto]"
    echo "   Proyecto no encontrado: '$PROJECT_PATH'"
    exit 1
fi
shift

while [ $# -gt 0 ]; do
    case "$1" in
        --max-iter) MAX_ITER="$2"; shift 2 ;;
        --model)    MODEL="$2"; shift 2 ;;
        --spec)     SPEC="$(realpath "$2")"; shift 2 ;;
        --auto)     AUTO="--auto" ;;
        *) echo "⚠️  Argumento desconocido: $1 (ignorado)"; shift ;;
    esac
done

if [ ! -f "$TESTER_PROMPT" ]; then
    echo "❌ No existe el prompt del testeador: $TESTER_PROMPT"
    exit 1
fi
if [ ! -f "$CORRECTOR_PROMPT" ]; then
    echo "❌ No existe el prompt del corrector: $CORRECTOR_PROMPT"
    exit 1
fi

QA_REPORT="$PROJECT_PATH/qa-report.md"
MODEL_ARGS=""
[ -n "$MODEL" ] && MODEL_ARGS="-m $MODEL"

# IMPORTANTE: el prompt se EMBEBE en el mensaje (opencode rechaza leer archivos
# fuera del directorio del proyecto en modo `run` — "external_directory").
TESTER_TEXT=$(cat "$TESTER_PROMPT")
CORRECTOR_TEXT=$(cat "$CORRECTOR_PROMPT")

echo "═══════════════════════════════════════════════════════"
echo "🔄 BUCLE DE CORRECCIÓN AUTOMÁTICA — SDD"
echo "   Proyecto : $PROJECT_PATH"
echo "   Max iter : $MAX_ITER"
echo "   Modelo   : ${MODEL:-default}"
echo "   Spec     : ${SPEC:-ninguna}"
echo "   Auto     : ${AUTO:-no (permisos interactivos)}"
echo "═══════════════════════════════════════════════════════"

run_tester() {
    rm -f "$QA_REPORT"
    echo ""
    echo "🔍 [Test] Corriendo testeador (iteración $1)..."
    # El prompt del testeador ya ordena escribir qa-report.md con veredicto APROBADO/RECHAZADO.
    opencode run --agent test $MODEL_ARGS $AUTO --dir "$PROJECT_PATH" \
        "$TESTER_TEXT

INSTRUCCIÓN EXTRA DEL BUCLE: escribí tu reporte final en $QA_REPORT (markdown) y que la última línea sea exactamente: **APROBADO** o **RECHAZADO**." \
        || { echo "⚠️  opencode test falló (exit $?) — continuando con el reporte si existe"; }
}

run_corrector() {
    echo ""
    echo "🔧 [Fix] Corriendo corrector (iteración $1)..."
    opencode run --agent build $MODEL_ARGS $AUTO --dir "$PROJECT_PATH" \
        "$CORRECTOR_TEXT

INSTRUCCIÓN EXTRA DEL BUCLE: el reporte QA actual está en $QA_REPORT — corregí SOLO los bugs listados ahí. No introduzcas cambios fuera del reporte." \
        || { echo "❌ opencode build falló (exit $?)"; exit 1; }
}

get_verdict() {
    if [ ! -f "$QA_REPORT" ]; then
        echo "NO_REPORT"
        return
    fi
    if grep -qiF "**APROBADO**" "$QA_REPORT" || grep -qi "APROBADO" "$QA_REPORT"; then
        echo "APROBADO"
    elif grep -qiF "**RECHAZADO**" "$QA_REPORT" || grep -qi "RECHAZADO" "$QA_REPORT"; then
        echo "RECHAZADO"
    else
        echo "SIN_VEREDICTO"
    fi
}

VERDICT=""
for i in $(seq 1 "$MAX_ITER"); do
    run_tester "$i"
    VERDICT=$(get_verdict)

    case "$VERDICT" in
        APROBADO)
            echo ""
            echo "✅ APROBADO en la iteración $i — el reporte final está en $QA_REPORT"
            exit 0
            ;;
        RECHAZADO)
            if [ "$i" -eq "$MAX_ITER" ]; then
                echo ""
                echo "❌ RECHAZADO tras $MAX_ITER iteraciones. Corregir manualmente."
                echo "   Reporte: $QA_REPORT"
                exit 1
            fi
            echo "   → Bugs encontrados. Corrección automática en curso..."
            run_corrector "$i"
            ;;
        NO_REPORT|SIN_VEREDICTO)
            echo "⚠️  No se pudo determinar el veredicto (reporte ausente o sin marcador)."
            if [ "$i" -eq "$MAX_ITER" ]; then
                echo "❌ Sin veredicto tras $MAX_ITER iteraciones — revisar manualmente."
                exit 1
            fi
            # Sin reporte: reintentar con un fix genérico (el corrector puede retocar y retestar)
            run_corrector "$i"
            ;;
    esac
done

echo "❌ Bucle terminó sin aprobar."
exit 1