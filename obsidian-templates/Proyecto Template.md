1|---
2|created: <% tp.date.now("YYYY-MM-DD") %>
3|stack: <% tp.system.suggester("Stack", ["mern", "pern", "php-wordpress", "python"]) %>
4|status: active
5|priority: <% tp.system.suggester("Prioridad", ["Urgente", "Alta", "Media", "Baja"]) %>
6|---
7|
8|# <% tp.file.title %>
9|
10|## Descripcion
11|<% tp.file.cursor(1) %>
12|
13|## Stack
14|- **Tipo:** `INPUT[stack]`
15|- **Lenguajes:** 
16|- **Frameworks:**
17|
18|## Estado del Proyecto
19|`INPUT[status]`
20|
21|## Criterios de Exito
22|- [ ] Criterio 1
23|- [ ] Criterio 2
24|- [ ] Criterio 3
25|
26|## Links
27|- [Tareas](Tareas.md)
28|- [Criterios de Exito](Criterios%20de%20Exito.md)
29|- [Tests](Tests%20de%20Verificacion.md)
30|
31|## AGENTS.md
32|```markdown
33|# Contexto del Proyecto: <% tp.file.title %>
34|
35|## Stack
36|- Tipo: {{stack}}
37|- Lenguajes: 
38|- Frameworks:
39|
40|## Reglas de Codificacion
41|1. Simplicidad primero
42|2. Cambios quirurgicos
43|3. Tests antes que codigo nuevo
44|4. Codigo limpio: nombres auto-explicativos, funciones <30 lineas, sin codigo muerto
45|5. Accesible: HTML semantico, labels en formularios, alt en imagenes, focus visible
46|6. Responsive: mobile-first, unidades rem/%, probar en 320/768/1280px, sin overflow
47|7. Seguridad: validar TODO input server-side, parametrizar SQL, escapar output (anti-XSS)
48|8. JAMAS hardcodear secretos: tokens/keys/passwords solo via variables de entorno (.env gitignored)
49|9. .env.example versionado con placeholders; .env y .env.local gitignored
50|10. Sin headers inseguros (CSP, X-Frame-Options) ni dependencias con CVEs (npm audit)
51|11. Seguridad: seguir la SECURITY-CHECKLIST.md del workflow-toolkit — rate limiting en endpoints públicos, errores genéricos al usuario, logging de anomalías, DB sin acceso público
52|
53|## Division de Trabajo (Workflow)
54|1. DEFINIR: Hermes — organiza, define arquitectura, specs y prompts. Crea SOLO archivos .md (specs, prompts, planes); NO ejecuta codigo, scaffold ni deps sin pedido explicito (evita gasto de tokens)
55|2. SYNC/DEPLOY: Hermes — commit/push con evidencia, sync Obsidian y tareas de deploy
56|3. ORQUESTAR: opencode plan — plan tecnico por fases (read-only)
57|4. EJECUTAR: opencode build — implementa el plan archivo por archivo
58|5. TESTEAR: opencode test — QA + seguridad, verifica con evidencia, reporta (no arregla)
59|
60|## Comandos
61|- `npm run dev`
62|- `npm test`
63|
64|## No editar
65|- /dist/**
66|- /coverage/**
67|- .env, .env.* (secretos reales)
68|
69|## Regla Suprema: agentWorkspace
69|
70|**Toda especificación, plan y documentación de desarrollo vive en `agentWorkspace/`.**
71|
72|Estructura:
73|```
74|agentWorkspace/
75|├── _master/           ← Plan maestro (DAG, criterios globales, decisiones)
76|├── backend/           ← Specs y planes de backend
77|├── frontend/          ← Specs y planes de frontend
78|├── qa/                ← Specs y planes de QA
79|├── devops/            ← Specs y planes de infra/deploy
80|├── design-uiux/       ← Specs y planes de diseño UI/UX
81|└── security/          ← Specs y planes de seguridad
82|```
83|
84|Cada área tiene `specs/` y `plans/`. Los specs se ejecutan en sesiones nuevas de OpenCode (sin contexto compartido) para evitar alucinaciones. Si se necesita referenciar código, se guarda en el spec o en un archivo accesible.
85|
86|**NO se guardan specs ni planes en la raíz del proyecto ni en carpetas genéricas.**
87|
88|### Flujo de trabajo
89|1. **Spec storm**: en sesión principal (Angel + Richard) se definen todos los specs del proyecto
90|2. **DAG**: Richard infiere el orden de ejecución de los `depends_on` de cada spec
91|3. **Ejecución**: Richard (ChiefAgent) delega cada spec a OpenCode en sesiones nuevas
92|4. **Verificación**: Richard revisa criterios de éxito y avanza al siguiente spec
93|
94|

## Memoria del Proyecto (sistema tipo Anthropic)
70|
71|Al aprender algo del usuario, del proyecto o del trabajo, guardarlo en `memory/` del proyecto, un archivo por tema (kebab-case), con frontmatter:
72|
73|```markdown
74|---
75|name: <slug-kebab-case>
76|description: <una linea — usada para decidir relevancia, se especifica>
77|metadata:
78|  type: user | feedback | project | reference
79|---
80|
81|<contenido: para feedback/project: regla/hecho, luego **Why:** (por que — incidente o preferencia) y **How to apply:** (cuando/cuando aplica)>
82|```
83|
84|Tipos:
85|- `user` — rol, objetivos, conocimiento, preferencias del usuario en este proyecto
86|- `feedback` — correcciones ("no, no asi") Y confirmaciones ("sí, perfecto"); guardar de ambos. Con **Why:** y **How to apply:**
87|- `project` — decisiones, metas, bugs, incidentes (estado: "quien hace que, por que, para cuando"). Convertir fechas relativas a absolutas ("jueves" → 2026-08-06)
88|- `reference` — punteros a recursos externos (repos, API docs, tableros, canales)
89|
90|NO guardar en memoria: patrones de codigo/estructura (se derivan del codigo), git history (autoritativo), recetas de debugging (el fix esta en el codigo + commit), estado efimero de la tarea actual.
91|
92|Reglas:
93|- MEMORY.md es un INDICE (lineas < 150 chars: `- [Title](file.md) — hook`), nunca contenido directo
94|- Confirmar el contenido del indice < 200 lineas
95|- Actualizar/eliminar memorias viejas o erradas; sin duplicados (actualizar el existente primero)
96|- "La memoria dice que X existe" ≠ "X existe ahora" — si la memoria nombra archivos/funciones, verificar con el codigo actual antes de recomendar
97|- Fechas del usuario → absolutas. Secuencia → orden de prioridad.
98|- Datos sensibles (SSN, cuentas, salud, direccion personal, secretos/tokens) NO se guardan salvo pedido explicito
99|```
100|
101|## Notas
102|