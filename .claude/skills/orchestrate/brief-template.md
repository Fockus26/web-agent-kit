# Orquestación del {{FECHA}} — brief común para los workers

> Lo lee **cada worker** antes de empezar. Su prompt trae solo lo específico de su unidad.
> Carpeta principal del repo: `{{RUTA_ABSOLUTA}}` (ahí viven los archivos locales/gitignored:
> `context/CURRENT_PHASE.md`, `context/CONTENT_CHECKLIST.md`, `context/PHASE_LOG/`,
> `context/plans/`, `.env`).

## Unidades y orden

| # | Rama | Qué | Ola | Puerto |
|---|---|---|---|---|
| W1 | `{{feat/...}}` | {{...}} | 1 | {{4331}} |

La ola 2 sale de `main` **después** de que se mergeen {{W…}} (tocan {{qué archivos}}).

## Números reservados

| Unidad | Archivo de decisiones | IDs | Filas de `CONTENT_CHECKLIST` |
|---|---|---|---|
| W1 | `context/decisions/{{NN}}-{{tema}}.md` | {{D0NN–D0NN}} | {{NN–NN}} |

No uses números fuera de tu rango.

## Decisiones de César para esta tanda

- {{ej. "cada worker puede levantar su servidor en su puerto"}}
- {{ej. "W1 puede aplicar columnas nuevas vía MCP; nada de borrar"}}

## Reglas de la tanda (además de `CLAUDE.md`)

1. **Lee solo** `CLAUDE.md` y lo que tu prompt cite (rutas, líneas, decisiones). No leas
   `context/` entero; lo demás, con `grep`.
2. **Rama:** `git fetch origin && git switch -c <tu-rama> origin/main`.
3. **Archivos locales compartidos:** no edites `CURRENT_PHASE.md` ni `CONTENT_CHECKLIST.md`.
   Escribe `context/PHASE_LOG/<tu-rama-con-guiones>.md` en la carpeta principal; si no
   tienes permiso de escritura ahí, entrégalo completo en tu informe final.
4. **Decisiones:** tu archivo de decisiones va en git, con su fila de una línea al final de
   `DECISIONS_INDEX.md`. En conflicto al sincronizar, conserva las filas de los dos lados.
5. **Versión y changelog:** parte de la versión de `main`; si al sincronizar otra unidad ya
   tomó tu número, sube la tuya por encima y deja tu entrada arriba.
6. **Servidor:** {{autorizado: `bun run dev -- --port <tu puerto>` en segundo plano, en tu
   worktree, tras `bun install` y copiar el `.env` de la carpeta principal (nunca se
   commitea). Apágalo al terminar. | no autorizado: verificación por código, márcalo.}}
7. **Navegador:** crea tu propia pestaña y pasa su `tabId` en cada llamada. Verifica
   midiendo el DOM (no con capturas vistas). Scripts con Playwright: con `node`.
8. **Datos reales:** el `.env` apunta a {{producción}}. No crees cuentas ni escribas datos;
   verifica como invitado o interceptando respuestas en la página (solo para depurar).
9. **Tests:** `bun run test:related` mientras trabajas; `bun run test` completo antes del PR.
10. **Verificación mínima antes del PR:** typecheck, lint (sin errores nuevos en lo tuyo),
    tests, build; si tocaste UI, skill `a11y` (axe claro y oscuro, 320 px, teclado).
11. **Capturas:** si cambió algo visible, `bun run shots` + `bun run shots:publish` y el
    markdown al PR. No abras las imágenes.
12. **Sin poder preguntar:** ante un dato que falte, lo conservador + "Decisión tomada /
    alternativa" en el PR. No te bloquees.
13. **Copy nuevo = provisional:** marcado en el código + tu fila reservada del checklist.
14. **Cierre:** commits Conventional (solo tus archivos), push de tu rama, `gh pr create`
    con la plantilla. **Nunca** `gh pr merge`, push a `main`, force-push ni amend de lo
    empujado. Base de datos: solo lo aditivo autorizado; nada destructivo.
15. **Informe final** (lo lee el orquestador, sé breve): URL del PR, versión, verificado /
    no verificado, decisiones abiertas, acciones manuales, bugs vistos de paso, y tu
    PHASE_LOG si no pudiste escribirlo.
