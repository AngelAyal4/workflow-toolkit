#!/bin/bash
# start-workspace.sh — Inicia tu entorno de desarrollo completo

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
DATABASE_URL=postgresql://user:pass@localhost:5432/dev
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
        
                # Carpetas de agentWorkspace (regla suprema: specs y plans por área)
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
        echo "export OPENCODE_MODEL=\"llama2-uncensored\"" >> "$PROJECT_PATH/.envrc"
        echo "export OPENCODE_BASE_URL=\"http://localhost:11434\"" >> "$PROJECT_PATH/.envrc"
        echo "export HERMES_MODEL=\"llama2-uncensored:latest\"" >> "$PROJECT_PATH/.envrc"
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

# 2. Abrir Obsidian (solo si no esta ya corriendo — si esta abierto, el 2do lanzamiento queda colgado esperando lock)
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

# 7. Previo: matar opencode CLI huérfano (evita procesos zombies)
pkill -9 -u "$USER" -f "opencode -m" 2>/dev/null
pkill -9 -u "$USER" -x opencode 2>/dev/null
sync

# 8. Iniciar workspace en tmux (mas estable que zellij: sin bug de sockets huerfanos)
echo "Iniciando workspace $PROJECT_TYPE/$PROJECT_NAME en tmux..."
SESSION="ws-$PROJECT_TYPE-$PROJECT_NAME"

# Limpiar una sesion tmux previa del mismo proyecto (si existe)
tmux has-session -t "$SESSION" 2>/dev/null && tmux kill-session -t "$SESSION"

# Segun stack: modelo de opencode y ventana de db
OPENCMD_BASE="opencode"
DB_KIND=""
case "$PROJECT_TYPE" in
    mern|mern-nextjs|pern-nextjs|astro) OPENCMD_BASE="opencode" ;;
esac

# Modelos por agente (OpenCode Go)
OPENCMD_PLAN="$OPENCMD_BASE --model zhipu/glm-5.3-flash --agent plan ."
OPENCMD_BUILD="$OPENCMD_BASE --model deepseek/deepseek-v4-1-flash --agent build ."
OPENCMD_TEST="$OPENCMD_BASE --model meta/muse-spark-1.3-contributor --agent test ."
case "$PROJECT_TYPE" in
    mern|mern-nextjs)  DB_KIND="mongo" ;;
    pern|pern-nextjs)  DB_KIND="postgres" ;;
    astro|astro-wp)    DB_KIND="wp" ;;
esac

# Ventana 1: Hermes (chat interactivo en directorio del proyecto)
tmux new-session -d -s "$SESSION" -c "$PROJECT_PATH" -n "$PROJECT_TYPE-hermes"
tmux send-keys -t "$SESSION:1.1" "cd $PROJECT_PATH && hermes chat --in $PROJECT_PATH --profile richard-dev --model meituan/longcat-2.0:free --reasoning max" C-m

# Ventana 2: OpenCode CLI — modo plan
tmux new-window -t "$SESSION" -n "opencode-plan"
tmux send-keys -t "$SESSION:opencode-plan.1" "$OPENCMD_PLAN" C-m

# Ventana 3: OpenCode CLI — modo build
tmux new-window -t "$SESSION" -n "opencode-build"
tmux send-keys -t "$SESSION:opencode-build.1" "$OPENCMD_BUILD" C-m

# Ventana 4: OpenCode CLI — modo QA y Security
tmux new-window -t "$SESSION" -n "opencode-qa"
tmux send-keys -t "$SESSION:opencode-qa.1" "$OPENCMD_TEST" C-m

# Ventana 5: base de datos (si aplica)
if [ -n "$DB_KIND" ]; then
    tmux new-window -t "$SESSION" -n "$DB_KIND"
    if [ "$PROJECT_TYPE" = "astro" ]; then
        tmux send-keys -t "$SESSION:$DB_KIND.1" "bash" C-m
    else
        tmux send-keys -t "$SESSION:$DB_KIND.1" "docker compose up $DB_KIND" C-m
    fi
fi

# Volver a la ventana de hermes y attach
tmux select-window -t "$SESSION:$PROJECT_TYPE-hermes"
# Re-ajusta la ventana al tamano real del terminal antes de plegarse
tmux resize-window -A 2>/dev/null

# Registrar/activar el proyecto en Hermes Desktop (sin Hermes CLI en tmux)
hermes project create "$PROJECT_NAME" --primary "$PROJECT_PATH" --use 2>/dev/null || {
    # Si ya existe, solo activarlo
    hermes project use "$PROJECT_NAME" 2>/dev/null
}

# El tmux se abre en la terminal desde la que se ejecuto ws
exec tmux attach -t "$SESSION"
