---
name: spec-storm
description: Use before writing specs. Drives design-tree questions.
tags: [design-tree, interview, spec-storm, planning, agentWorkspace]
---

# Spec Storm

## Qué es

Spec Storm es el proceso de definición rigurosa de un spec **antes** de escribirlo. Usa la metodología de Design Tree: cada decisión se ramifica en las decisiones que cuelgan de ella, y se trabaja por rondas de preguntas interdependientes.

Se llama así porque es un "tormenta de preguntas" que limpia la niebla antes de codificar.

## Cuándo se activa

- El usuario dice "hagamos un spec" o "definí este feature"
- Se inicia un nuevo proyecto y se empieza el spec storm
- El usuario tiene una idea vaga que necesita aterrizarse
- Antes de cada spec del agentWorkspace

## El Árbol de Decisiones (Design Tree)

Cada decisión tiene hijas: decisiones que dependen de ella para poder formularse o responderse.

```
[¿Auth con JWT o sesiones?]
     \           \
   [JWT]       [sesiones]
     |             |
[Expiración]  [Almacenamiento]
     |
[Refresh token]
```

La **frontera** (frontier) son todas las decisiones cuyos prerequisitos ya están resueltos. Es decir, las preguntas que se pueden hacer **ahora** sin depender de respuestas que todavía no llegaron.

## Rondas de Preguntas

Se trabaja en rondas. En cada ronda:

1. Richard identifica la frontera actual
2. Formula todas las preguntas de la frontera en **una sola ronda**
3. Da su respuesta recomendada
4. Espera la respuesta del usuario
5. Recalcula la frontera con las respuestas
6. Si la frontera no está vacía, repite

### Formato de Ronda

Cada pregunta se formatea así:

```
❓ **Q1** — **<título>**:
<cuerpo de la pregunta, puede tener múltiples opciones>

➡️ **Recomendación**: <la opción que Richard recomienda y por qué>

---

❓ **Q2** — **<título>**:
<cuerpo de la pregunta>

➡️ **Recomendación**: <recomendación>
```

### Criterio de Pregunta

Si una pregunta **depende** de otra pregunta que todavía está abierta, va en la **siguiente ronda**, no en la actual.

**Test de niebla vs ticket:** ¿Puedo formular la pregunta con precisión ahora mismo? Si sí → es pregunta de esta ronda. Si no → va a una ronda posterior cuando la información esté disponible.

### Rol de Richard

- **NO delegar investigación**: Si Richard puede buscar un hecho (filesystem, docs, codebase), lo hace él. No le pide al usuario buscar nada.
- **Decisiones son del usuario**: Las preguntas son para que el usuario decida, no para que Richard adivine.
- **Recomendaciones**: Cada pregunta incluye una recomendación razonada, no solo opciones.

## Criterio de Parada

El spec storm termina cuando la **frontera está vacía**: cada rama del árbol fue visitada, nada queda asumido sin confirmar.

**Richard NO pasa a escribir el spec hasta que el usuario confirma que el árbol está completo.**

## Output Final

Al terminar el spec storm, Richard tiene toda la información para escribir un spec completo en `agentWorkspace/{area}/specs/{id}.md` usando el template correspondiente.

## Integración con agentWorkspace

```
1. Spec Storm → Richard hace rondas de preguntas
2. Usuario responde en tiempo real
3. Cuando la frontera está vacía, Richard escribe el spec
4. Se repite para cada spec del proyecto
5. Se ensambla el DAG (plan maestro) desde los depends_on
6. ChiefAgent toma el control para ejecutar
```

## Estructura de Archivos

Los specs generados van a:
```
agentWorkspace/
├── _master/
│   ├── glossary.md       ← Glosario del proyecto (términos consistentes)
│   ├── plan.md           ← Plan maestro / DAG
│   └── criteria.md       ← Criterios de éxito globales
├── backend/specs/
├── frontend/specs/
├── qa/specs/
├── devops/specs/
├── design-uiux/specs/
├── security/specs/
└── docs/specs/
```

## Glosario del Proyecto

El `_master/glossary.md` mantiene consistencia terminológica entre todos los specs. Cada spec storm revisa y actualiza el glosario según las decisiones tomadas.

```markdown
# Glosario — [Proyecto]

| Término | Definición | Contexto |
|---------|-----------|----------|
| User | Persona que usa la app | Backend, Frontend |
| Wallet | Billetera interna del usuario | Backend, Frontend |
| Transacción | Movimiento de dinero entre wallets | Backend, DB |
```

## Ejemplo de Ronda

```
❓ **Q1** — **Sistema de autenticación**:
¿Qué sistema de autenticación usamos para la app?

Opciones:
- JWT con access + refresh tokens (stateless, escalable)
- Sesiones con cookies (más simple, stateful)
- OAuth con Google/GitHub (sin manejar passwords)

➡️ **Recomendación**: JWT con access + refresh tokens. Es stateless, escala horizontalmente, y nos da control granular sobre expiración.

---

❓ **Q2** — **Base de datos**:
¿Qué base de datos principal usamos?

Opciones:
- PostgreSQL (relacional, robusto, joins)
- MongoDB (documento, flexible, rápido para prototipos)

➡️ **Recomendación**: PostgreSQL. Para datos financieros, las transacciones ACID y la integridad referencial son importantes.
```