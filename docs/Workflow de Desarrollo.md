---
created: 2026-08-05
updated: 2026-09-26
tags: [workflow, stack, desarrollo, referencia, herdr]
area: desarrollo
---

# Workflow de Desarrollo — Manual de Referencia

> **Qué es:** Pipeline completo para crear y gestionar proyectos full-stack con especificaciones, agentes de IA y memoria persistente.
> Cada proyecto se crea desde un **stack definido** (plantilla), pasa por **Spec Storm** (definición rigurosa), se valida con **OpenSpec**, se orquesta con **ChiefAgent** y se sincroniza entre el código (`~/workspace`), el segundo cerebro (Obsidian), el multiplexor (**Herdr**, agent-aware) y las integraciones (direnv, Docker).

---

## 1. Resumen del flujo

```
Pedís "creame un proyecto X" (Richard/Hermes Desktop)
        │
        ▼
┌─────────────────────────────────────────────────────────────┐
│ 1. SPEC STORM (Richard — Design Tree + OpenSpec)            │
│    ❓ Q1 — Stack backend: NestJS o Express?                 │
│    ➡️ Recomendación: NestJS                                 │
│    ❓ Q2 — Auth: JWT o sesiones?                            │
│    ➡️ Recomendación: JWT con refresh tokens                 │
│    ... (hasta frontier = vacío)                             │
│    Output: openspec/config.yaml + specs en agentWorkspace/  │
└─────────────────────────────────────────────────────────────┘
        │ (specs aprobados)
        ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. PLAN MAESTRO (Richard infiere DAG)                       │
│    - Lee specs, infiere depends_on                          │
│    - Arma _master/plan.md con fases                        │
│    - Define criterios de éxito globales                     │
│    - Crea _master/glossary.md                              │
└─────────────────────────────────────────────────────────────┘
        │ (plan aprobado)
        ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. EJECUCIÓN AUTÓNOMA (ChiefAgent = Richard)               │
│    - Por cada fase (en orden):                              │
│      a. Lee spec de área X                                 │
│      b. Delega a OpenCode en sesión NUEVA                   │
│      c. Verifica criterios de éxito                         │
│      d. Si pasa → avanza                                   │
│      e. Si falla → fix loop (3 iteraciones) → escala a vos │
└─────────────────────────────────────────────────────────────┘
        │
        ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. VERIFICACIÓN Y ENTREGA                                   │
│    - security-check.sh → no hay secrets en staging          │
│    - memory-manager.sh → se guardaron decisiones            │
│    - Commit → Push → Sync Obsidian                          │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Los stacks disponibles

Un **stack** = plantilla de proyecto con estructura, dependencias y config propias.

| Stack | Tabs Herdr | Carpeta proyectos | Caso en `start-workspace.sh` |
|-------|--------------|-------------------|------------------------------|
| **PHP / WordPress** | `php-nvim` → `opencode-plan` → `opencode-build` → `opencode-test` → [`db`] | `~/workspace/projects/php-wordpress/` | `php` |
| **MERN** | `mern-nvim` → `opencode-plan` → `opencode-build` → `opencode-test` → `mongo` | `~/workspace/projects/mern/` | `mern` |
| **MERN + Next.js** | `mern-nextjs-nvim` → `opencode-plan` → `opencode-build` → `opencode-test` → `mongo` | `~/workspace/projects/mern-nextjs/` | `mern-nextjs` |
| **PERN** | `pern-nvim` → `opencode-plan` → `opencode-build` → `opencode-test` → `postgres` | `~/workspace/projects/pern/` | `pern` |
| **PERN + Next.js** | `pern-nextjs-nvim` → `opencode-plan` → `opencode-build` → `opencode-test` → `postgres` | `~/workspace/projects/pern-nextjs/` | `pern-nextjs` |
| **Python** | `python-nvim` → `opencode-plan` → `opencode-build` → `opencode-test` → [`db`] | `~/workspace/projects/python/` | `python` |
| **Astro** | `astro-nvim` → `opencode-plan` → `opencode-build` → `opencode-test` → [`db`] | `~/workspace/projects/astro/` | `astro` |
| **Astro + WP Headless** | `astro-wp-nvim` → `opencode-plan` → `opencode-build` → `opencode-test` → `wp` | `~/workspace/projects/astro-wp/` | `astro-wp` |

> `[db]` = solo si el stack usa base de datos (`mongo`, `postgres`, `wp`).

### Tabs de Herdr

Cada workspace de **Herdr** abre (vía `herdr workspace create` + `herdr tab create`):
1. **`hermes`** → Hermes chat (perfil `richard-dev`, LongCat 2.0, reasoning max)
2. **`opencode-plan`** → OpenCode TUI — plan técnico (GLM-5.3-Flash)
3. **`opencode-build`** → OpenCode TUI — implementación (DeepSeek V4.1 Flash)
4. **`opencode-qa`** → OpenCode TUI — QA y seguridad (Muse Spark 1.3)
5. **`mongo`/`postgres`/`wp`** → Base de datos según stack (solo si aplica; `docker compose up <db>`)

Detalles que explican por qué funciona así:
- Config en `~/.config/herdr/config.toml` (prefijo `ctrl+b`, tema catppuccin).
- Los panes nuevos NO heredan el `--cwd` del workspace: `start-workspace.sh` fuerza `cd` en cada pane antes de lanzar comandos (`pane send-text` + `send-keys enter`).
- Si el workspace ya existe, el script lo reutiliza (idempotente) en vez de duplicar tabs.
- Salir sin cerrar la sesión: `Ctrl+b q`. Volver: `herdr` (alias `hda`). Listar: `herdr workspace list` (alias `hdl`).
- Herdr reemplaza a tmux (sep-2026, agent-aware: trackea estado working/idle/blocked). tmux queda como legacy solo para sesiones viejas.

## 3. Estructura generada por `ws`

```
~/workspace/projects/<stack>/<proyecto>/
├── openspec/                    # OpenSpec (NO se sube a git)
│   ├── config.yaml              # Contexto del proyecto (stack, arquitectura, reglas)
│   ├── specs/                   # Specs versionados (opcional)
│   └── changes/                 # Registro de cambios
├── agentWorkspace/              # Specs y planes (NO se sube a git)
│   ├── _master/
│   │   ├── plan.md              # Plan maestro (DAG y fases)
│   │   ├── criteria.md          # Criterios de éxito globales
│   │   └── glossary.md          # Términos del proyecto
│   ├── backend/specs/           # Specs de backend
│   ├── backend/plans/           # Planes de backend
│   ├── frontend/specs/          # Specs de frontend
│   ├── frontend/plans/          # Planes de frontend
│   ├── qa/specs/                # Specs de QA
│   ├── qa/plans/                # Planes de QA
│   ├── devops/specs/            # Specs de infra/deploy
│   ├── devops/plans/            # Planes de infra/deploy
│   ├── design-uiux/specs/       # Specs de diseño UI/UX
│   ├── design-uiux/plans/       # Planes de diseño UI/UX
│   ├── security/specs/          # Specs de seguridad
│   ├── security/plans/          # Planes de seguridad
│   ├── docs/specs/              # Specs de documentación
│   └── docs/plans/              # Planes de documentación
├── memory/                      # Memoria del proyecto
│   ├── MEMORY.md                # Índice
│   ├── project/                 # Memorías específicas del proyecto
│   └── global/                  # Memorías cross-proyecto
├── .envrc                       # direnv: variables del proyecto
├── .gitignore                   # Incluye: node_modules/, .env, coverage/, prompts/, agentWorkspace/
├── AGENTS.md                    # Contexto para OpenCode/Hermes
└── ...
```

---

## 4. Comandos y aliases

Cargados en `~/.bashrc`:

```bash
# Gestión del workspace
ws    # ~/scripts/start-workspace.sh <stack> <proyecto>  → crea y abre el entorno (Herdr)
obs   # obsidian ~/obsidian-vault &                      → abre el vault
hdl   # herdr workspace list                             → lista workspaces
hda   # herdr                                            → attach a Herdr
vault # cd ~/obsidian-vault && git "$@"                  → atajo git del vault
``````

### Uso principal: `ws <stack> <proyecto>`

```bash
# Crear proyecto NUEVO y abrir el workspace
ws mern blog-gpt

# Si el proyecto NO existe, pregunta si crearlo (s/n).
# Si existe, lo abre directamente.
```

---

## 5. Scripts del workflow-toolkit

| Script | Ruta | Función |
|--------|------|---------|
| **start-workspace** | `~/workflow-toolkit/scripts/start-workspace.sh` | Orquesta todo: crea estructura, copia plantillas, .envrc, direnv, docker-compose, OpenSpec, agentWorkspace, memory, y abre workspace Herdr |
| **model-router** | `~/workflow-toolkit/scripts/model-router.sh` | GGA: selecciona el mejor modelo según tarea y disponibilidad (opencode/nous/local) |
| **security-check** | `~/workflow-toolkit/scripts/security-check.sh` | Guardrails: verifica que no haya secrets en staging, .gitignore correcto, archivos protegidos |
| **memory-manager** | `~/workflow-toolkit/scripts/memory-manager.sh` | Memoria extendida: project/global dirs + TTL (90 días) |
| **openspec-validate** | `~/workflow-toolkit/scripts/openspec-validate.sh` | Valida specs contra config.yaml (estructura, escenarios, RFC 2119, dependencias) |
| **sync-obsidian** | `~/workflow-toolkit/scripts/sync-obsidian.sh` | Sync git bidireccional del vault (commit + push + pull --rebase). Corre cada 15 min por cron. **Reemplaza a backup-obsidian** |
| **backup-obsidian** | `~/workflow-toolkit/scripts/backup-obsidian.sh` | Legacy: backup local (rsync + tar.gz, mantiene 10). Solo manual |
| **bucle-correccion** | `~/workflow-toolkit/scripts/bucle-correccion.sh` | Loop test → fix → test hasta aprobar QA |
| **obsidian-context-bridge** | `~/workflow-toolkit/scripts/obsidian-context-bridge.py` | Bridge MCP (stdio) que expone el vault a OpenCode/agentes: `list_projects`, `read_note`, `get_project_context` |

### Uso de los scripts

```bash
# Ver estado de proveedores y modelos disponibles
~/workflow-toolkit/scripts/model-router.sh status

# Ver modelo recomendado para cada tarea
~/workflow-toolkit/scripts/model-router.sh brainstorm
~/workflow-toolkit/scripts/model-router.sh plan
~/workflow-toolkit/scripts/model-router.sh build
~/workflow-toolkit/scripts/model-router.sh test

# Seguridad antes de commit
~/workflow-toolkit/scripts/security-check.sh check

# Memoria del proyecto
~/workflow-toolkit/scripts/memory-manager.sh init .          # Inicializar
~/workflow-toolkit/scripts/memory-manager.sh add project "Título" "Contenido..."  # Agregar
~/workflow-toolkit/scripts/memory-manager.sh gc .            # Limpiar memorias viejas
~/workflow-toolkit/scripts/memory-manager.sh status .        # Ver estado

# Validar specs OpenSpec
~/workflow-toolkit/scripts/openspec-validate.sh validate

# Sincronizar Obsidian entre máquinas (también corre solo cada 15 min por cron)
~/workflow-toolkit/scripts/sync-obsidian.sh
``````

---

## 6. Modelos por tarea (Model Router)

| Tarea | OpenCode Go ($10/mes) | Nous Portal (free) | Local (Ollama) |
|-------|----------------------|-------------------|----------------|
| **Brainstorming** | Muse Spark 1.3 | LongCat 2.0 | qwen3.5:27b |
| **Plan** | GLM-5.3-Flash | Step 3.7 Flash | deepseek-v4-flash |
| **Build** | DeepSeek V4 Flash | Laguna XS 2.1 | llama2-uncensored |
| **Test/QA** | Muse Spark 1.3 | Ling 3.0 Flash Fin | llama2-uncensored |

### Regla de oro

- **Invertir en planificar** (mejor modelo disponible)
- **Ahorrar en ejecutar** (modelo económico que siga instrucciones)

> Modelos reales que levanta `start-workspace.sh` hoy: tab `hermes` → LongCat 2.0 (perfil `richard-dev`, reasoning max); `opencode-plan` → GLM-5.3-Flash; `opencode-build` → DeepSeek V4.1 Flash; `opencode-qa` → Muse Spark 1.3.

---

## 7. Skills de Hermes

| Skill | Cuándo se activa | Qué hace |
|-------|-----------------|----------|
| **spec-storm** | Antes de escribir specs | Design Tree (rondas de preguntas) + OpenSpec (escenarios Given/When/Then + RFC 2119) |
| **chief-agent** | Cuando Richard orquesta agentWorkspace | Lee plan maestro, delega specs a OpenCode, verifica criterios de éxito |
| **organic-routing** | Al iniciar cualquier tarea | Rutea por complejidad: direct, delegated, SDD |
| **auto-memory** | Al finalizar sesiones significativas | Guarda session summaries |
| **sdd-workflow** | Cuando el usuario dice "use SDD" | Ejecuta Spec-Driven Development completo |
| **skill-style-guide** | Al crear/refactorar skills | Estándar LLM-first para authoring |
| **app-quality-gates** | Antes de cada commit | 7 reglas obligatorias (código limpio, a11y, responsive, seguridad, secrets, `.env.example`, headers/audit) — referenciada en los templates por stack |
| **i-have-adhd** | En cada respuesta | Formato ADHD-friendly: próxima acción primero, corto y accionable |

---

## 8. OpenSpec

OpenSpec es el sistema de especificaciones que vive en el repo del proyecto:

### `openspec/config.yaml`

Define el contexto del proyecto:
- Tech stack
- Arquitectura
- Reglas de desarrollo (proposal, specs, design, tasks, apply, verify)
- Configuración de testing
- Archivos protegidos

### Validación

```bash
~/workflow-toolkit/scripts/openspec-validate.sh validate
```

Verifica:
- ✅ Estructura del spec (frontmatter, campos obligatorios)
- ✅ Escenarios Given/When/Then completos
- ✅ Keywords RFC 2119 (MUST, SHOULD, MAY)
- ✅ Consistencia con `openspec/config.yaml`
- ✅ No hay IDs duplicados
- ✅ Los `depends_on` apuntan a specs existentes
- ✅ No hay archivos protegidos modificados

---

## 9. Integraciones

- **Obsidian** → El vault se sincroniza con el proyecto vía notas en `01-Projects/<stack>/<proyecto>/` + sync git bidireccional (`sync-obsidian.sh`, cron cada 15 min, log en `~/backups/obsidian/sync.log`)
- **GitHub CLI** → Autenticado con `gh` (`GITHUB_TOKEN` en `~/.bashrc`, también cargado por el cron)
- **Docker / Docker Compose** → Para contenedores de bases de datos (MongoDB, PostgreSQL, WordPress/MySQL 8)
- **Herdr** → Multiplexor principal agent-aware (prefijo `ctrl+b`, config `~/.config/herdr/config.toml`); aliases `hdl`/`hda`; detach con `Ctrl+b q`
- **tmux** → Legacy (solo si tenés sesiones viejas activas)
- **Neovim** → Editor de código principal
- **Hermes Desktop** → Chat con Richard para Spec Storm y ChiefAgent (proyecto anclado a `PROJECT_PATH`)

---

## 10. Ejemplos de uso reales

### Ejemplo 1 — Proyecto nuevo con Spec Storm

```
(usuario) "Quiero hacer un CRM con auth, dashboard y API REST"

(Richard — spec-storm):
❓ Q1 — Stack backend: NestJS o Express?
➡️ Recomendación: NestJS (TypeScript, escalable)

❓ Q2 — Auth: JWT o sesiones?
➡️ Recomendación: JWT con refresh tokens

❓ Q3 — DB: PostgreSQL o MongoDB?
➡️ Recomendación: PostgreSQL (datos relacionales)

... (hasta que frontier = vacío)

(Richard escribe specs en agentWorkspace/{area}/specs/ + openspec/config.yaml)
(Richard ejecuta openspec-validate.sh)
(Richard arma plan maestro en _master/plan.md)
```

### Ejemplo 2 — Crear proyecto manual

```bash
ws pern cashinsight
# → Crea estructura + openspec/ + agentWorkspace/ + memory/
# → Abre workspace Herdr: hermes │ opencode-plan │ opencode-build │ opencode-qa │ postgres
```

### Ejemplo 3 — Verificar seguridad antes de commit

```bash
~/workflow-toolkit/scripts/security-check.sh check
# ✅ Todas las verificaciones pasaron
```

### Ejemplo 4 — Ver modelos disponibles

```bash
~/workflow-toolkit/scripts/model-router.sh status
# OpenCode Go: ✅ disponible
# Nous Portal:  ✅ disponible
# Ollama:       ❌ no disponible
```

---

### Ejemplo 5 — Sincronizar Obsidian entre máquinas

```bash
~/workflow-toolkit/scripts/sync-obsidian.sh
# Sin cambios locales → solo pull --rebase.
# Con cambios → commit "sync: <fecha> desde <host>" + push + pull.
# El cron lo corre cada 15 min y escribe en ~/backups/obsidian/sync.log
```

---

## 11. Archivos y directorios clave

```
~/workflow-toolkit/                  # Repo del workflow-toolkit
├── scripts/
│   ├── start-workspace.sh         # Orquesta todo (Herdr CLI)
│   ├── model-router.sh            # GGA: modelos por tarea
│   ├── security-check.sh          # Guardrails de seguridad
│   ├── memory-manager.sh          # Memoria extendida
│   ├── openspec-validate.sh       # Valida specs OpenSpec
│   ├── sync-obsidian.sh           # Sync git del vault (reemplaza backup)
│   ├── backup-obsidian.sh         # Legacy: backup local
│   └── obsidian-context-bridge.py # Bridge MCP del vault
├── configs/
│   └── herdr.toml                 # Config Herdr (prefix ctrl+b, catppuccin)
├── obsidian-templates/            # Plantillas (proyecto + por stack)
├── setup.sh                       # Bootstrap (herdr + sync + skills)
├── agentWorkspace/
│   └── _templates/
│       └── spec.md                # Template de spec (OpenSpec)
├── openspec/
│   └── config.yaml                # Template de config OpenSpec
├── skills/
│   ├── software-development/
│   │   ├── spec-storm/            # Skill de Spec Storm
│   │   ├── chief-agent/           # Skill de ChiefAgent
│   │   └── ...
│   ├── stacks/                    # Skills por stack
│   │   ├── react/
│   │   ├── node/
│   │   ├── python/
│   │   ├── go/
│   │   └── astro/
│   ├── tasks/                     # Skills por tarea
│   │   ├── debug/
│   │   ├── review/
│   │   ├── test/
│   │   └── deploy/
│   └── personas/                  # Skills por persona
│       └── gentleman/
└── ...

~/obsidian-vault/
├── 01-Projects/                   # Notas de proyectos
├── 04-Resources/                  # Recursos y referencias
│   └── Workflow de Desarrollo.md  # Este archivo
└── ...
```

---

> **Regla de oro:** al crear un proyecto, *siempre* Richard hace Spec Storm primero. No se escribe código hasta que los specs están completos y validados.

---

## 12. Qué cambió (sep-2026) — si venías de tmux/backup

1. **tmux → Herdr.** El multiplexor ahora es Herdr (agent-aware: sabe si un agente está working/idle/blocked, mejor persistencia y control por CLI). `setup.sh` ahora hace `install_herdr()` + `setup_herdr()`; `start-workspace.sh` crea el workspace con `herdr workspace create`, los tabs con `herdr tab create` y manda comandos con `pane send-text` + `send-keys enter`. Salís sin cerrar con `Ctrl+b q`. Por qué: tmux no sabía nada de agentes y cada reconexión era manual; Herdr sí.
2. **Backup local → sync git.** `sync-obsidian.sh` hace commit + push + pull `--rebase` del vault y corre cada 15 min por cron (log en `~/backups/obsidian/sync.log`). `backup-obsidian.sh` queda como legacy manual. Por qué: hay dos máquinas (Ubuntu + Fedora) y el tar.gz local no las sincronizaba; git sí, con historia.
3. **Kaspian → Richard.** El orquestador (ChiefAgent) se renombró a Richard (perfil `richard-dev`). Si ves "Kaspian" en notas viejas, es lo mismo.
4. **Templates con Reglas de Calidad.** Astro/PERN/PHP/Python ahora exigen las 7 reglas de `app-quality-gates` (código limpio, a11y, responsive, seguridad, secrets, `.env.example`, headers/audit). El template genérico además exige la `SECURITY-CHECKLIST.md` (rate limiting, errores genéricos, logging de anomalías, DB sin acceso público).
5. **Astro SSG puro + PERN-NextJS nuevo.** El template Astro ahora es SSG estático puro (Astro 7 + Tailwind 4, sin WordPress; lo headless vive en `Astro-WP`). Se agregó `PERN-NextJS` (Next.js 15 + Postgres 16 + Prisma/pg + JWT en cookies httpOnly). `Astro-WP` se conserva como template propio del vault.
