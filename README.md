<div align="center">

# 🚀 Workflow Toolkit

**Entorno de desarrollo full-stack con especificaciones, agentes de IA y memoria persistente.**

[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS%20%7C%20Windows-949494)](https://github.com/AngelAyal4/workflow-toolkit)
[![Shell](https://img.shields.io/badge/shell-bash%20%7C%20zsh-4EAA25)](https://github.com/AngelAyal4/workflow-toolkit)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

[Quickstart](#quickstart) • [Cómo se usa](#cómo-se-usa) • [Estructura](#estructura-del-repo) • [Integraciones](#integraciones) • [Contributing](#contributing)

</div>

---

## ¿Qué es?

Workflow Toolkit es un **ecosistema de desarrollo** que organiza tu entorno de trabajo completo en un solo repositorio: configuraciones, scripts, plantillas, skills de IA y flujos de trabajo. Está diseñado para que puedas bootstrapear una máquina nueva en minutos y mantener la consistencia entre entornos.

**Antes:** Configuraciones dispersas, aliases perdidos, cada proyecto empieza de cero, sin memoria entre sesiones.

**Después:** Un `git clone` + `./setup.sh` y tenés todo: tmux, aliases, agentes de IA, plantillas de Obsidian, y un flujo de trabajo estructurado con SDD (Spec-Driven Development).

---

## Features

| Feature | Qué hace |
|---|---|
| **Bootstrap en una pasada** | `./setup.sh` instala y configura todo el entorno |
| **agentWorkspace** | Sistema de specs, planes y orquestación multi-area para desarrollo autónomo |
| **ChiefAgent (Richard)** | Orquestador que delega specs a OpenCode y verifica criterios de éxito |
| **Multi-agent workflow** | Hermes (main specs) + OpenCode (plan-build-qa) + agentes especializados |
| **Skills de Hermes** | organic-routing, auto-memory, sdd-workflow, skill-style-guide, chief-agent, spec-storm |
| **Memoria persistente** | Session summaries automáticas, contexto cross-session |
| **Plantillas Obsidian** | Templates por stack (MERN, PERN, MEAN) + proyecto genérico |
| **Seguridad integrada** | SECURITY-CHECKLIST.md obligatoria (16 items) en cada feature |
| **Bucle de corrección** | test → fix → test automático hasta aprobar QA |
| **Multi-stack** | Crea proyectos MERN, PERN, MEAN, Astro con un comando |

---

## Quickstart

### Instalación (nueva máquina)

```bash
git clone https://github.com/AngelAyal4/workflow-toolkit.git
cd workflow-toolkit
chmod +x setup.sh
./setup.sh
```

Esto instala y configura:
- Paquetes base (git, curl, fzf, ripgrep, direnv, tmux, docker)
- Node.js LTS
- Ollama + modelos locales
- Aliases de shell + hook direnv
- Config de tmux (prefijo C-a, mouse on)
- Scripts del workspace
- Plantillas de Obsidian
- Config de OpenCode
- **Skills de Hermes** (organic-routing, auto-memory, sdd-workflow, skill-style-guide)
- Cron de backup diario del vault

### Crear un proyecto

```bash
# Crear proyecto con stack MERN
ws mern taskboard

# O con PERN (PostgreSQL + Next.js)
ws pern cashinsight
```

Esto crea y abre automáticamente en la terminal desde la que ejecutaste `ws`:
- Sesión de tmux con 5 ventanas: terminal, OpenCode plan/build/test, DB
- Carpeta `agentWorkspace/` con specs y planes por área (backend, frontend, qa, devops, docs)
- Proyecto de Hermes Desktop anclado a `PROJECT_PATH`

Ventanas de tmux:
| Ventana | Contenido | Modelo |
|---------|-----------|--------|
| `*-hermes` | Hermes (chat interactivo) | LongCat 2.0 (Nous, xhigh reasoning) |
| `opencode-plan` | OpenCode TUI — plan técnico | GLM-5.3-Flash (Go) |
| `opencode-build` | OpenCode TUI — implementación | DeepSeek V4.1 Flash (Go) |
| `opencode-qa` | OpenCode TUI — QA y Security | Muse Spark 1.3 (Go) |
| `wp`/`mongo`/`postgres` | Base de datos (según stack) | — |

La ventana de Hermes **no** se crea dentro de tmux: el trabajo con Hermes se hace desde la interfaz Desktop. Para salir del tmux sin cerrar la sesión, usá `Ctrl-b d`. Para volver a entrar manualmente:
```bash
tmux attach -t ws-mern-taskboard
```

Estructura generada:
```
<proyecto>/
├── agentWorkspace/        # Specs y planes (NO se sube a git)
│   ├── _master/           # Plan maestro (DAG, criterios globales)
│   ├── backend/specs/     # Specs de backend
│   ├── backend/plans/     # Planes de backend
│   ├── frontend/specs/    # Specs de frontend
│   ├── frontend/plans/    # Planes de frontend
│   ├── qa/specs/          # Specs de QA
│   ├── qa/plans/          # Planes de QA
│   ├── devops/specs/      # Specs de infra/deploy
│   ├── devops/plans/      # Planes de infra/deploy
├── design-uiux/specs/    # Specs de diseño UI/UX
├── design-uiux/plans/    # Planes de diseño UI/UX
├── security/specs/       # Specs de seguridad
└── security/plans/       # Planes de seguridad
├── memory/                # Memoria del proyecto
└── ...
```

---

## Cómo se usa

### Flujo agentWorkspace + ChiefAgent

```
1. SESIÓN PRINCIPAL (Angel + Richard)
   └── Spec storm: definen todos los specs del proyecto
   └── Richard infiere DAG de los depends_on
   └── Se crea agentWorkspace/ completo

2. APROBACIÓN
   └── Richard revisa cada spec vs criterios globales
   └── Si todo OK → ChiefAgent toma el control

3. EJECUCIÓN AUTÓNOMA (ChiefAgent = Richard)
   └── Lee plan maestro
   └── Por cada fase:
       a. Toma spec de área X
       b. Delega a OpenCode en sesión NUEVA
       c. Verifica criterios de éxito
       d. Si pasa → avanza
       e. Si falla → fix loop (3 iteraciones) → escala a Angel
   └── Reporte final

4. REVISIÓN FINAL
   └── Angel revisa el resultado
```

### Skills de Hermes

Las skills se cargan automáticamente en cada sesión de Hermes:

| Skill | Cuándo se activa | Qué hace |
|---|---|---|
| **organic-routing** | Al iniciar cualquier tarea | Rutea por complejidad: direct (1-3 archivos), delegated (4+), SDD (ambigüedad alta) |
| **auto-memory** | Al finalizar sesiones significativas | Guarda session summaries con decisiones, descubrimientos y contexto |
| **sdd-workflow** | Cuando el usuario dice "use SDD" | Ejecuta el flujo completo de Spec-Driven Development |
| **skill-style-guide** | Al crear/refactorar skills | Estándar LLM-first para authoring consistente |
| **chief-agent** | Cuando Richard orquesta agentWorkspace | Spec storm, DAG, delegación a OpenCode, verificación |

---

## Estructura del repo

```
workflow-toolkit/
├── agentWorkspace/              # Templates de specs y planes (NO es un proyecto real)
│   ├── _templates/              # Templates base (spec.md, plan.md)
│   ├── _master/                 # (vacío, se llena al crear proyecto)
│   ├── backend/                 # (vacío, se llena al crear proyecto)
│   ├── frontend/                # (vacío, se llena al crear proyecto)
│   ├── qa/                      # (vacío, se llena al crear proyecto)
│   ├── devops/                  # (vacío, se llena al crear proyecto)
│   └── docs/                    # (vacío, se llena al crear proyecto)
│   ├── design-uiux/             # (vacío, se llena al crear proyecto)
│   └── security/                # (vacío, se llena al crear proyecto)
├── configs/                     # Configs de referencia (tmux, opencode, envrc)
├── docs/                        # Documentación (seguridad, prompts, guías)
├── obsidian-templates/          # Plantillas de Obsidian (proyecto + por stack)
├── scripts/                     # Scripts del workspace (bucle-correccion, setup, backup)
├── skills/                      # Skills de Hermes
│   └── software-development/
│       ├── organic-routing/     # Ruteo por complejidad
│       ├── auto-memory/         # Session summaries automáticas
│       ├── sdd-workflow/        # Spec-Driven Development
│       ├── skill-style-guide/   # Estándar de authoring
│       ├── sdd-feature-delivery-review/  # Review pre-commit
│       └── chief-agent/         # Orquestación multi-area
├── setup.sh                     # Bootstrap del entorno (una pasada)
├── SECURITY-CHECKLIST.md        # Checklist de seguridad obligatoria (16 items)
└── README.md                    # Este archivo
```

---

## Integraciones

### Agentes de IA

| Agente | Rol | Cuándo se usa | Surface |
|---|---|---|---|
| **Hermes** | Orquestador + DEFINE + SYNC/DEPLOY | Organiza, crea specs, hace commit/push con evidencia | **Desktop app** (proyecto anclado a la ruta del proyecto) |
| **OpenCode** | Ejecutor (Plan + Implement) | Modelo potente para planificar, modelo eficiente para implementar | CLI en tmux |
| **OpenCode (agente test)** | QA + seguridad | Verifica, no implementa. Genera reportes con veredicto APROBADO/RECHAZADO | CLI en tmux |

### Herramientas externas

| Herramienta | Integración |
|---|---|
| **Obsidian** | Specs y planes como notas vinculadas al proyecto |
| **Git** | Cada feature = una spec + un branch corto |
| **Docker** | Stacks con docker-compose (PostgreSQL, MongoDB) |
| **tmux** | Multiplexor principal (prefijo C-a) |
| **Zellij** | Multiplexor secundario con layouts predefinidos |
| **eGEOagents** | AI SEO / citabilidad LLM (opcional) |

---

## Reglas del equipo

> Cuando un miembro pide crear un proyecto por chat (Hermes/Telegram), **primero se hacen preguntas** (tipo, propósito, requerimientos) y **recién después** se crea. Nunca crear sin aclarar.

> Toda feature debe tener una spec antes de implementar. La spec debe incluir requisitos, acceptance criteria, y edge cases.

> La SECURITY-CHECKLIST.md es obligatoria. Cada item debe estar resuelto o marcado como N/A con motivo.

---

## Troubleshooting

| Problema | Solución |
|---|---|
| `docker: permission denied` | Cerrá y reabrí la terminal (grupo docker) |
| OpenCode no ve Ollama | `ollama serve` en segundo plano + `curl localhost:11434/api/tags` |
| Hermes rechaza modelo local por contexto <64K | Usá `llama3.1:8b` (128K nativo) en `.envrc` y config |
| Alias no funcionan | `source ~/.bashrc` o reabrir terminal |
| `ws` no crea el proyecto | Asegurate de pasar `s` cuando pregunta "crear? (s/n)" |
| Skills no aparecen en nueva sesión | El loader se inicializa al start — cerrá y reabrí Hermes |

---

## Contributing

1. **Forkeá** el repo y creá una rama (`git checkout -b feature/mi-feature`)
2. **Seguí el flujo SDD**: creá una spec en `specs/` antes de implementar
3. **Verificá con el bucle de corrección**: `./scripts/bucle-correccion.sh --spec specs/mi-feature.md`
4. **Actualizá la documentación** si agregás nuevas herramientas o flujos
5. **Hacé commit** con [Conventional Commits](https://www.conventionalcommits.org/)
6. **Abrí un PR** con descripción clara y evidencia de funcionamiento

---

## License

MIT © Angel Ayala (AngelAyal4)
