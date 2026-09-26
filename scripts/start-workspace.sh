#!/bin/bash
# start-workspace.sh — Inicia tu entorno de desarrollo completo con Herdr

WORKFLOW_STACK="${WORKFLOW_STACK:-$HOME/workflow-toolkit}"
PROJECT_TYPE=$1
PROJECT_NAME=$2

if [ -z "$PROJECT_TYPE" ] || [ -z "$PROJECT_NAME" ]; then
    echo "Uso: start-workspace.sh <php|mern|mern-nextjs|pern|pern-nextjs|python|astro> <nombre-proyecto>"
    echo ""
    echo "Proyectos existentes:"
    for stack in php-wordpress mern mern-nextjs pern pern-nextjs python astro; do
        echo "  $stack:"
        ls ~/workspace/projects/$stack 2>/dev/null | sed "s/^/    - /"
    done
    exit 1
fi

PROJECT_PATH="$HOME/workspace/projects/$PROJECT_TYPE/$PROJECT_NAME"
VAULT_PATH="$HOME/obsidian-vault"

# 1. Verificar que el proyecto existe
if [ ! -d "$PROJECT_PATH" ]; then
    echo "Proyecto no encontrado: $PROJECT_PATH"
    echo "Quieres crearlo? (s/n)"
    read -r respuesta
    if [ "$respuesta" = "s" ]; then
        mkdir -p "$PROJECT_PATH"
        cd "$PROJECT_PATH" || exit
        
        case $PROJECT_TYPE in
            mern)
                mkdir -p client server/routes server/models server/controllers server/middleware server/tests
                
                # Inicializar Node.js
                npm init -y
                npm install express cors mongoose dotenv bcrypt jsonwebtoken
                npm install --save-dev jest supertest nodemon
                
                # Crear package.json con scripts
                node -e "
                const fs = require('fs');
                const pkg = JSON.parse(fs.readFileSync('package.json'));
                pkg.scripts = {
                    start: 'node server/index.js',
                    dev: 'nodemon server/index.js',
                    test: 'jest --coverage'
                };
                pkg.main = 'server/index.js';
                fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2));
                "
                
                # Crear .gitignore
                echo 'node_modules/' > .gitignore
                echo '.env' >> .gitignore
                echo 'coverage/' >> .gitignore
                echo 'prompts/' >> .gitignore
                echo 'agentWorkspace/' >> .gitignore
        
                echo "version: \"3.8\"" > docker-compose.yml
                echo "services:" >> docker-compose.yml
                echo "  mongo:" >> docker-compose.yml
                echo "    image: mongo:7" >> docker-compose.yml
                echo "    ports:" >> docker-compose.yml
                echo "      - \"27017:27017\"" >> docker-compose.yml
                echo "    volumes:" >> docker-compose.yml
                echo "      - mongo_data:/data/db" >> docker-compose.yml
                echo "volumes:" >> docker-compose.yml
                echo "  mongo_data:" >> docker-compose.yml
                ;;
            mern-nextjs)
                # Crear proyecto Next.js fullstack con App Router
                npx create-next-app@latest . --typescript --tailwind --eslint --app --src-dir --import-alias "@/*" --no-turbopack --use-npm --yes 2>/dev/null || {
                    echo "create-next-app fallo, creando estructura manual..."
                    npm init -y
                    mkdir -p src/app src/components src/lib src/types src/hooks prisma
                }

                # Instalar dependencias del backend/API
                npm install mongoose dotenv bcryptjs jsonwebtoken zod
                npm install --save-dev @types/bcryptjs @types/jsonwebtoken

                # Instalar Tremor para dashboards/charts
                npm install @tremor/react recharts
                npm install --save-dev nodemon

                # Estructura backend (API routes + models + lib)
                mkdir -p src/app/api/auth src/app/api/transactions src/app/api/categories src/app/api/budgets src/app/api/reports
                mkdir -p src/models src/lib src/middleware src/types

                # package.json con scripts fullstack
                node -e "
                const fs = require('fs');
                const pkg = JSON.parse(fs.readFileSync('package.json'));
                pkg.scripts = {
                    dev: 'next dev',
                    build: 'next build',
                    start: 'next start',
                    lint: 'next lint',
                    test: 'jest --coverage'
                };
                fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2));
                "

                # .gitignore
                cat > .gitignore <<'EOF'
node_modules/
.next/
out/
build/
.env
.env.local
.env.*.local
coverage/
*.tsbuildinfo
next-env.d.ts
.DS_Store
npm-debug.log*
EOF

                # Docker Compose para MongoDB
                cat > docker-compose.yml <<'EOF'
version: "3.8"
services:
  mongo:
    image: mongo:7
    ports:
      - "27017:27017"
    volumes:
      - mongo_data:/data/db
volumes:
  mongo_data:
EOF

                # .env.example (sin secretos)
                cat > .env.example <<'EOF'
# MongoDB
MONGODB_URI=mongodb://localhost:27017/cashinsightapp
# JWT Secret (generar con: openssl rand -base64 32)
JWT_SECRET=your-jwt-secret-here
# NextAuth (cuando se implemente)
NEXTAUTH_SECRET=your-nextauth-secret
NEXTAUTH_URL=http://localhost:3000
EOF
                ;;
            pern)
                mkdir -p client server/{routes,models,controllers,middleware,tests}
                npm init -y
                npm install express cors pg dotenv bcrypt jsonwebtoken
                npm install --save-dev jest supertest nodemon
                
                # Crear package.json con scripts
                node -e "
                const fs = require('fs');
                const pkg = JSON.parse(fs.readFileSync('package.json'));
                pkg.scripts = {
                    start: 'node server/index.js',
                    dev: 'nodemon server/index.js',
                    test: 'jest --coverage'
                };
                pkg.main = 'server/index.js';
                fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2));
                "
                
                # Crear .gitignore
                echo 'node_modules/' > .gitignore
                echo '.env' >> .gitignore
                echo 'coverage/' >> .gitignore
                echo 'prompts/' >> .gitignore
                echo 'agentWorkspace/' >> .gitignore
        
                echo "version: \"3.8\"" > docker-compose.yml
                echo "services:" >> docker-compose.yml
                echo "  postgres:" >> docker-compose.yml
                echo "    image: postgres:16" >> docker-compose.yml
                echo "    environment:" >> docker-compose.yml
                echo "      POSTGRES_USER: user" >> docker-compose.yml
                echo "      POSTGRES_PASSWORD: pass" >> docker-compose.yml
                echo "      POSTGRES_DB: dev" >> docker-compose.yml
                echo "    ports:" >> docker-compose.yml
                echo "      - \"5432:5432\"" >> docker-compose.yml
                echo "    volumes:" >> docker-compose.yml
                echo "      - postgres_data:/var/lib/postgresql/data" >> docker-compose.yml
                echo "volumes:" >> docker-compose.yml
                echo "  postgres_data:" >> docker-compose.yml
                ;;
            pern-nextjs)
                # Crear proyecto Next.js fullstack con App Router + PostgreSQL
                npx create-next-app@latest . --typescript --tailwind --eslint --app --src-dir --import-alias "@/*" --no-turbopack --use-npm --yes 2>/dev/null || {
                    echo "create-next-app fallo, creando estructura manual..."
                    npm init -y
                    mkdir -p src/app src/components src/lib src/types src/hooks src/db
                }

                # Dependencias backend: pg (PostgreSQL) + validacion + auth
                npm install pg dotenv bcryptjs jsonwebtoken zod
                npm install --save-dev @types/pg @types/bcryptjs @types/jsonwebtoken nodemon

                # Estructura backend (API routes + db + lib)
                mkdir -p src/app/api/auth src/app/api/users src/app/api/turnos
                mkdir -p src/db src/lib src/middleware src/types

                # package.json con scripts fullstack
                node -e "
                const fs = require('fs');
                const pkg = JSON.parse(fs.readFileSync('package.json'));
                pkg.scripts = {
                    dev: 'next dev',
                    build: 'next build',
                    start: 'next start',
                    lint: 'next lint',
                    test: 'jest --coverage'
                };
                fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2));
                "

                # .gitignore
                cat > .gitignore <<'EOF'
node_modules/
.next/
out/
build/
.env
.env.local
.env.*.local
coverage/
*.tsbuildinfo
next-env.d.ts
.DS_Store
npm-debug.log*
EOF

                # Docker Compose para PostgreSQL 16
                cat > docker-compose.yml <<'EOF'
version: "3.8"
services:
  postgres:
    image: postgres:16
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
      POSTGRES_DB: dev
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
volumes:
  postgres_data:
EOF

                # .env.example (sin secretos)
                cat > .env.example <<'EOF'
# PostgreSQL (Docker local)
DATABASE_URL=postgresql://user:***@localhost:5432/dev
# Supabase/Neon (produccion): postgresql://...@... (host remoto)
# JWT Secret (generar con: openssl rand -base64 32)
JWT_SECRET=your-jwt-secret-here
# NextAuth (cuando se implemente)
NEXTAUTH_SECRET=your-nextauth-secret
NEXTAUTH_URL=http://localhost:3000
EOF
                ;;
            php)
                mkdir -p wp-content/themes wp-content/plugins
                ;;
            python)
                mkdir -p src tests notebooks
                python3 -m venv .venv
                ;;
            astro)
                # Inicializar Astro primero (directorio vacio)
                npm create astro@latest -- --template minimal --no-install --yes . 2>/dev/null || {
                    echo "npm create astro fallo, creando package.json manual..."
                    npm init -y
                }
                
                # Carpetas extra que el template minimal no genera
                mkdir -p src/content src/lib src/styles
                
                # Astro 7 + Tailwind 4 via plugin Vite.
                # @astrojs/tailwind esta DEPRECADO y no soporta Astro 7 (peer astro<=5).
                npm install astro@^7 @tailwindcss/vite tailwindcss@^4
                npm install --save-dev @astrojs/check typescript
                # sharp (transitiva de astro) hereda CVEs de libvips si queda <0.35.0
                npm audit fix >/dev/null 2>&1
                
                # Crear package.json con scripts
                node -e "
                const fs = require('fs');
                const pkg = JSON.parse(fs.readFileSync('package.json'));
                pkg.scripts = {
                    dev: 'astro dev',
                    build: 'astro build',
                    preview: 'astro preview',
                    check: 'astro check'
                };
                pkg.main = 'src/index.js';
                fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2));
                "
                
                # SSG estatico + Tailwind 4 (CSS-first: @import "tailwindcss" + tokens @theme)
                cat > astro.config.mjs <<'EOF'
import { defineConfig } from 'astro/config';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
  output: 'static',
  vite: {
    plugins: [tailwindcss()],
  },
});
EOF

                cat > src/styles/global.css <<'EOF'
@import "tailwindcss";

@theme {
  --color-ink: #0a0a0f;
  --color-panel: #14141c;
}
EOF

                # .env.example (sin secretos; stack estatico sin WP ni DB)
                cat > .env.example <<'EOF'
# Sitio estatico (SSG): no requiere variables.
# Si mas adelante hay forms/APIs, las env vars van aca (nunca en el repo).
EOF
                
                # .gitignore
                cat > .gitignore <<'EOF'
node_modules/
dist/
.astro/
.env
.env.local
.env.*.local
EOF
                ;;
        esac
        
        cp "$VAULT_PATH/02-Templates/Proyecto Template.md" "$PROJECT_PATH/AGENTS.md"
        
        # Sistema de memoria del proyecto (tipo Anthropic): carpeta + indice
        mkdir -p "$PROJECT_PATH/memory"
        if [ ! -f "$PROJECT_PATH/memory/MEMORY.md" ]; then
            printf '# MEMORY.md — Indice de memoria del proyecto\n\n(Un archivo por tema en memory/, cada entrada: `- [Title](file.md) — hook` <150 chars)\n' > "$PROJECT_PATH/memory/MEMORY.md"
        fi
        
        # Carpetas de agentWorkspace (regla suprema: specs y planes por área)
        mkdir -p "$PROJECT_PATH/agentWorkspace/_master"
        mkdir -p "$PROJECT_PATH/agentWorkspace/backend/specs"
        mkdir -p "$PROJECT_PATH/agentWorkspace/backend/plans"
        mkdir -p "$PROJECT_PATH/agentWorkspace/frontend/specs"
        mkdir -p "$PROJECT_PATH/agentWorkspace/frontend/plans"
        mkdir -p "$PROJECT_PATH/agentWorkspace/qa/specs"
        mkdir -p "$PROJECT_PATH/agentWorkspace/qa/plans"
        mkdir -p "$PROJECT_PATH/agentWorkspace/devops/specs"
        mkdir -p "$PROJECT_PATH/agentWorkspace/devops/plans"
        mkdir -p "$PROJECT_PATH/agentWorkspace/docs/specs"
        mkdir -p "$PROJECT_PATH/agentWorkspace/docs/plans"
        mkdir -p "$PROJECT_PATH/agentWorkspace/design-uiux/specs"
        mkdir -p "$PROJECT_PATH/agentWorkspace/design-uiux/plans"
        mkdir -p "$PROJECT_PATH/agentWorkspace/security/specs"
        mkdir -p "$PROJECT_PATH/agentWorkspace/security/plans"
        
        # Estructura OpenSpec
        mkdir -p "$PROJECT_PATH/openspec/specs"
        mkdir -p "$PROJECT_PATH/openspec/changes"
        cp "$WORKFLOW_STACK/openspec/config.yaml" "$PROJECT_PATH/openspec/config.yaml" 2>/dev/null || true
        echo "export PROJECT_TYPE=\"$PROJECT_TYPE\"" >> "$PROJECT_PATH/.envrc"
        echo "export OPENAI_API_KEY=\"not-needed-local\"" >> "$PROJECT_PATH/.envrc"
        echo "export OPENCODE_MODEL=\"qwen2.5:7b\"" >> "$PROJECT_PATH/.envrc"
        echo "export OPENCODE_BASE_URL=\"http://localhost:11434\"" >> "$PROJECT_PATH/.envrc"
        echo "export HERMES_MODEL=\"qwen2.5:7b\"" >> "$PROJECT_PATH/.envrc"
        echo "export HERMES_PROVIDER=\"ollama\"" >> "$PROJECT_PATH/.envrc"
        echo "export HERMES_BASE_URL=\"http://localhost:11434\"" >> "$PROJECT_PATH/.envrc"
        
        direnv allow "$PROJECT_PATH"
        
        OBS_PROJECT="$VAULT_PATH/01-Projects/$PROJECT_TYPE/$PROJECT_NAME"
        mkdir -p "$OBS_PROJECT/Logs de Sesiones"
        
        cp "$VAULT_PATH/02-Templates/Kanban Template.md" "$OBS_PROJECT/Tareas.md"
        cp "$VAULT_PATH/02-Templates/Criterios Template.md" "$OBS_PROJECT/Criterios de Exito.md"
        
        echo "Proyecto creado en $PROJECT_PATH"
        echo "Notas creadas en $OBS_PROJECT"
    else
        exit 1
    fi
fi

# 2. Abrir Obsidian (solo si no esta ya corriendo)
if pgrep -x obsidian >/dev/null 2>&1; then
    echo "Obsidian ya esta abierto. Saltando (evita lock colgado)."
else
    obsidian "$VAULT_PATH" &
fi

# 3. Navegar al proyecto
cd "$PROJECT_PATH" || exit

# 4. Cargar direnv
direnv allow 2>/dev/null
eval "$(direnv export bash)"

# 5. Iniciar servicios si hay docker-compose
if [ -f "docker-compose.yml" ]; then
    echo "Iniciando servicios con Docker..."
    docker compose up -d
fi

# 6. Previo: matar opencode CLI huérfano
pkill -9 -u "$USER" -f "opencode -m" 2>/dev/null
pkill -9 -u "$USER" -x opencode 2>/dev/null
sync

# 7. Iniciar workspace en Herdr
echo "Iniciando workspace $PROJECT_TYPE/$PROJECT_NAME en Herdr..."
WORKSPACE_LABEL="$PROJECT_TYPE-$PROJECT_NAME"

# Asegurar que el servidor está corriendo
if ! herdr status server >/dev/null 2>&1; then
    echo "Arrancando servidor Herdr..."
    herdr server &>/tmp/herdr-server.log &
    sleep 2
fi

# Verificar si el workspace ya existe (para no duplicar tabs)
EXISTING_WS=$(herdr workspace list 2>/dev/null | jq -r '.result.workspaces[] | select(.label == "'$WORKSPACE_LABEL'") | .workspace_id' 2>/dev/null)

if [ -n "$EXISTING_WS" ]; then
    echo "Workspace ya existe: $EXISTING_WS. Reutilizando..."
    WS_ID="$EXISTING_WS"
    # Obtener IDs de tabs y panes existentes
    TABS_JSON=$(herdr tab list --workspace "$WS_ID" 2>&1)
    TAB_HERMES_ID=$(echo "$TABS_JSON" | jq -r '.result.tabs[] | select(.label == "hermes") | .tab_id')
    TAB_PLAN_ID=$(echo "$TABS_JSON" | jq -r '.result.tabs[] | select(.label == "opencode-plan") | .tab_id')
    TAB_BUILD_ID=$(echo "$TABS_JSON" | jq -r '.result.tabs[] | select(.label == "opencode-build") | .tab_id')
    TAB_QA_ID=$(echo "$TABS_JSON" | jq -r '.result.tabs[] | select(.label == "opencode-qa") | .tab_id')
    PANE_TERM=$(echo "$TABS_JSON" | jq -r '.result.tabs[] | select(.label == "1") | .tab_id' 2>/dev/null)
    # Si no hay tab "1", usar el primer pane
    if [ -z "$PANE_TERM" ]; then
        PANE_TERM=$(herdr pane list --workspace "$WS_ID" 2>/dev/null | jq -r '.result.panes[0].pane_id')
    fi
    PANE_HERMES=$(herdr pane list --workspace "$WS_ID" 2>/dev/null | jq -r '.result.panes[] | select(.tab_id == "'$TAB_HERMES_ID'") | .pane_id' 2>/dev/null | head -1)
    PANE_PLAN=$(herdr pane list --workspace "$WS_ID" 2>/dev/null | jq -r '.result.panes[] | select(.tab_id == "'$TAB_PLAN_ID'") | .pane_id' 2>/dev/null | head -1)
    PANE_BUILD=$(herdr pane list --workspace "$WS_ID" 2>/dev/null | jq -r '.result.panes[] | select(.tab_id == "'$TAB_BUILD_ID'") | .pane_id' 2>/dev/null | head -1)
    PANE_QA=$(herdr pane list --workspace "$WS_ID" 2>/dev/null | jq -r '.result.panes[] | select(.tab_id == "'$TAB_QA_ID'") | .pane_id' 2>/dev/null | head -1)
    # DB
    DB_KIND=""
    case "$PROJECT_TYPE" in
        mern|mern-nextjs)  DB_KIND="mongo" ;;
        pern|pern-nextjs)  DB_KIND="postgres" ;;
        astro|astro-wp)    DB_KIND="wp" ;;
    esac
    if [ -n "$DB_KIND" ]; then
        TAB_DB_ID=$(echo "$TABS_JSON" | jq -r '.result.tabs[] | select(.label == "'$DB_KIND'") | .tab_id')
        PANE_DB=$(herdr pane list --workspace "$WS_ID" 2>/dev/null | jq -r '.result.panes[] | select(.tab_id == "'$TAB_DB_ID'") | .pane_id' 2>/dev/null | head -1)
    fi
else
    # Modelos por agente (OpenCode Go).
    # Override sin tocar el script: OPENCODE_MODEL_PLAN / _BUILD / _TEST,
    # HERMES_MODEL_TAG. Verificar con /models en el TUI (el catalogo Go rota).
    OPENCODE_MODEL_PLAN="${OPENCODE_MODEL_PLAN:-zhipu/glm-5.3-flash}"
    OPENCODE_MODEL_BUILD="${OPENCODE_MODEL_BUILD:-deepseek/deepseek-v4-1-flash}"
    OPENCODE_MODEL_TEST="${OPENCODE_MODEL_TEST:-meta/muse-spark-1.3-contributor}"
    HERMES_MODEL_TAG="${HERMES_MODEL_TAG:-meituan/longcat-2.0:free}"
    OPENCMD_BASE="opencode"
    DB_KIND=""
    case "$PROJECT_TYPE" in
        mern|mern-nextjs|pern-nextjs|astro) OPENCMD_BASE="opencode" ;;
    esac

    OPENCMD_PLAN="$OPENCMD_BASE --model $OPENCODE_MODEL_PLAN --agent plan ."
    OPENCMD_BUILD="$OPENCMD_BASE --model $OPENCODE_MODEL_BUILD --agent build ."
    OPENCMD_TEST="$OPENCMD_BASE --model $OPENCODE_MODEL_TEST --agent test ."
    case "$PROJECT_TYPE" in
        mern|mern-nextjs)  DB_KIND="mongo" ;;
        pern|pern-nextjs)  DB_KIND="postgres" ;;
        astro|astro-wp)    DB_KIND="wp" ;;
    esac

    # Crear workspace (incluye tab y root pane)
    echo "Creando workspace: $WORKSPACE_LABEL"
    WS_JSON=$(herdr workspace create --cwd "$PROJECT_PATH" --label "$WORKSPACE_LABEL" --focus 2>&1)
    WS_ID=$(echo "$WS_JSON" | jq -r '.result.workspace.workspace_id')
    PANE_TERM=$(echo "$WS_JSON" | jq -r '.result.root_pane.pane_id')

    if [ -z "$WS_ID" ] || [ "$WS_ID" = "null" ]; then
        echo "ERROR: No se pudo crear el workspace Herdr"
        echo "Detalles: $WS_JSON"
        exit 1
    fi

    # Crear tabs adicionales
    echo "Creando tabs..."
    TAB_HERMES_JSON=$(herdr tab create --workspace "$WS_ID" --label "hermes" --focus 2>&1)
    TAB_HERMES_ID=$(echo "$TAB_HERMES_JSON" | jq -r '.result.tab.tab_id')
    PANE_HERMES=$(echo "$TAB_HERMES_JSON" | jq -r '.result.root_pane.pane_id')

    TAB_PLAN_JSON=$(herdr tab create --workspace "$WS_ID" --label "opencode-plan" --focus 2>&1)
    PANE_PLAN=$(echo "$TAB_PLAN_JSON" | jq -r '.result.root_pane.pane_id')

    TAB_BUILD_JSON=$(herdr tab create --workspace "$WS_ID" --label "opencode-build" --focus 2>&1)
    PANE_BUILD=$(echo "$TAB_BUILD_JSON" | jq -r '.result.root_pane.pane_id')

    TAB_QA_JSON=$(herdr tab create --workspace "$WS_ID" --label "opencode-qa" --focus 2>&1)
    PANE_QA=$(echo "$TAB_QA_JSON" | jq -r '.result.root_pane.pane_id')

    # Tab de DB (si aplica)
    PANE_DB=""
    if [ -n "$DB_KIND" ]; then
        TAB_DB_JSON=$(herdr tab create --workspace "$WS_ID" --label "$DB_KIND" --focus 2>&1)
        PANE_DB=$(echo "$TAB_DB_JSON" | jq -r '.result.root_pane.pane_id')
    fi
fi

# Lanzar comandos en cada pane
# send-text escribe texto en el pane; send-keys enter lo ejecuta
# Los panes nuevos NO heredan --cwd del workspace, así que forzamos cd primero

echo "Lanzando agentes..."

# Pane terminal (bash simple - ya está listo, no necesita comando)
# El pane root ya tiene bash interactivo por defecto

# Pane hermes
herdr pane send-text "$PANE_HERMES" "cd '$PROJECT_PATH' && hermes chat --in '$PROJECT_PATH' --profile richard-dev --model $HERMES_MODEL_TAG --reasoning max" 2>/dev/null
herdr pane send-keys "$PANE_HERMES" enter 2>/dev/null

# Pane opencode plan
herdr pane send-text "$PANE_PLAN" "cd '$PROJECT_PATH' && $OPENCMD_PLAN" 2>/dev/null
herdr pane send-keys "$PANE_PLAN" enter 2>/dev/null

# Pane opencode build
herdr pane send-text "$PANE_BUILD" "cd '$PROJECT_PATH' && $OPENCMD_BUILD" 2>/dev/null
herdr pane send-keys "$PANE_BUILD" enter 2>/dev/null

# Pane opencode QA
herdr pane send-text "$PANE_QA" "cd '$PROJECT_PATH' && $OPENCMD_TEST" 2>/dev/null
herdr pane send-keys "$PANE_QA" enter 2>/dev/null

# Pane DB (si aplica)
if [ -n "$PANE_DB" ] && [ "$PANE_DB" != "null" ]; then
    if [ "$PROJECT_TYPE" = "astro" ]; then
        herdr pane send-text "$PANE_DB" "cd '$PROJECT_PATH' && bash" 2>/dev/null
        herdr pane send-keys "$PANE_DB" enter 2>/dev/null
    else
        herdr pane send-text "$PANE_DB" "cd '$PROJECT_PATH' && docker compose up $DB_KIND" 2>/dev/null
        herdr pane send-keys "$PANE_DB" enter 2>/dev/null
    fi
fi

# Volver al tab de hermes
herdr tab focus "$TAB_HERMES_ID" 2>/dev/null

# Registrar/activar el proyecto en Hermes Desktop
hermes project create "$PROJECT_NAME" --primary "$PROJECT_PATH" --use 2>/dev/null || {
    hermes project use "$PROJECT_NAME" 2>/dev/null
}

# Attach a la sesión Herdr (todos los workspaces conviven en la sesión default)
echo "Workspace listo. Conectando a Herdr..."
exec herdr
