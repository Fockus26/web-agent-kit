# Orquestación del {{FECHA}} — brief común para los workers

> {{Fase 0N, ola N de M — plan: `context/plans/fase-0N-<nombre>.md` | Tanda suelta}}

> Lo lee **cada worker** antes de empezar. Su prompt trae solo lo específico de su unidad.
> Carpeta principal del repo: `{{RUTA_ABSOLUTA}}` (ahí viven los archivos locales/gitignored:
> `context/CURRENT_PHASE.md`, `context/CONTENT_CHECKLIST.md`, `context/PHASE_LOG/`,
> `context/plans/`, `.env`).

## Unidades y orden

| # | Rama | Qué | Ola | Slot / puerto |
|---|---|---|---|---|
| W1 | `{{feat/...}}` | {{...}} | 1 | {{wt1 / 4301}} |

Slot y puerto los da `wt take` al lanzar; el mensaje con el que se lanza cada worker los repite.

La ola 2 sale de `main` **después** de que se mergeen {{W…}} (tocan {{qué archivos}}).

## Números reservados

| Unidad | IDs de decisión | Filas de `CONTENT_CHECKLIST` |
|---|---|---|
| W1 | {{D0NN–D0NN}} | {{NN–NN}} |

No uses números fuera de tu rango.

## Decisiones de César para esta tanda

- {{ej. "cada worker puede levantar su servidor en su puerto"}}
- {{ej. "W1 puede aplicar columnas nuevas vía MCP; nada de borrar"}}

## Reglas de la tanda (además de `CLAUDE.md`)

1. **Lee solo** `CLAUDE.md` y lo que tu prompt cite (rutas, líneas, decisiones). No leas
   `context/` entero; lo demás, con `grep`.
2. **Slot y rama:** trabajas SOLO en la ruta de tu slot del pool (`..\<repo>-wt\wtN`), que
   ya viene con tu rama creada, `node_modules` instalado y los `.env*` copiados. No crees
   ni borres worktrees, no corras `wt` y no cambies de rama.
3. **Archivos locales compartidos:** no edites `CURRENT_PHASE.md` ni `CONTENT_CHECKLIST.md`.
   Escribe `context/PHASE_LOG/<tu-rama-con-guiones>.md` en la carpeta principal; si no
   tienes permiso de escritura ahí, entrégalo completo en tu informe final.
4. **Decisiones:** un archivo por decisión, `context/decisions/D0NN-<tema>.md`, con los IDs
   de tu rango y la cabecera de una línea (formato en `context/decisions/README.md`). Va en
   git. No hay índice que editar.
5. **Changeset:** el salto que dice tu prompt (patch/minor/major, o ninguno). Si lleva, un
   `.changeset/<desc-kebab>.md` escrito a mano (formato en `git-flow` §2.1) con el texto en
   lenguaje de usuario. No toques `version` ni `CHANGELOG.md`: los escribe el PR de versión.
6. **Servidor:** {{autorizado: `bun run dev -- --port <el puerto de tu slot>` en segundo
   plano, en tu slot (ya está instalado y con `.env*`). Apágalo al terminar. | no
   autorizado: verificación por código, márcalo.}}
7. **Navegador:** crea tu propia pestaña y pasa su `tabId` en cada llamada. Verifica
   midiendo el DOM (no con capturas vistas). Scripts con Playwright: con `node`.
8. **Datos reales:** el `.env` apunta a {{producción}}. No inicies sesión, no crees cuentas
   ni escribas datos; verifica como invitado o interceptando respuestas en la página (solo
   para depurar). La prueba con sesión y datos la hace `wave-qa` cuando la ola esté
   mergeada: en tu PR, "Cómo probarlo" dice qué flujo y con qué rol, para que la pueda hacer.
9. **Tests:** `bun run test:related` mientras trabajas; `bun run test` completo antes del PR.
10. **Verificación mínima antes del PR:** typecheck, lint (sin errores nuevos en lo tuyo),
    tests, build; si tocaste UI, skill `a11y` (axe claro y oscuro, 320 px, teclado).
11. **Capturas:** si cambió algo visible, `bun run shots` + `bun run shots:publish` y el
    markdown al PR. No abras las imágenes.
12. **Sin poder preguntar:** ante un dato que falte, lo conservador + "Decisión tomada /
    alternativa" en el PR. No te bloquees.
13. **Copy nuevo = provisional:** marcado en el código + tu fila reservada del checklist.
14. **Cierre:** commits Conventional (solo tus archivos), push de tu rama, `gh pr create`
    con la plantilla. Deja el slot limpio: todo commiteado y empujado (`git status` vacío),
    o el orquestador no podrá liberarlo. **Nunca** `gh pr merge`, push a `main`, force-push
    ni amend de lo empujado. Base de datos: solo lo aditivo autorizado; nada destructivo.
15. **Informe final** (lo lee el orquestador, sé breve): URL del PR, slot, changeset, verificado /
    no verificado, decisiones abiertas, acciones manuales, bugs vistos de paso, y tu
    PHASE_LOG si no pudiste escribirlo.
