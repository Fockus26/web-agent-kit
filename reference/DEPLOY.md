# Repo en GitHub y despliegue en Vercel

Se decide en el arranque (`project-kickoff`, Bloque B) y lo ejecuta el agente **solo si César
dijo que sí en la entrevista**: crear un repo, cambiar ajustes de GitHub y conectar Vercel son
acciones hacia fuera. La respuesta de la entrevista es la autorización; si no se preguntó, se
pregunta antes de ejecutar.

Preguntas (una tanda, con opciones):

1. **¿Creo el repo en GitHub?** No / sí, privado / sí, público — ¿en tu cuenta o en una
   organización (cuál)? Si el repo ya existe: su URL.
2. **¿Despliego en Vercel?** No / sí, en tu cuenta / sí, en la cuenta del cliente (la crea o
   invita él). El plan Hobby de Vercel es para uso personal no comercial: un sitio de un
   cliente va en Pro o en la cuenta del cliente. Si hay dominio: cuál y quién gestiona su DNS.
3. Si no es Vercel (VPS, hosting del cliente): dónde, y queda como unidad de la fase 09.

---

## 1. GitHub

Requisitos: `gh auth status` en verde. Si no, se le pide a César que corra `gh auth login`
(el agente nunca escribe credenciales).

```bash
git add -A && git commit -m "chore: inicializa proyecto con web-agent-kit"   # si no hay commits
gh repo create <dueño>/<repo> --private --source . --push                    # o --public
```

Ajustes del repo (antes eran "acciones manuales de César"; con su sí, los hace el agente):

```bash
# Borrar la rama remota al mergear el PR
gh api -X PATCH repos/<dueño>/<repo> -F delete_branch_on_merge=true

# Que la Action de Changesets pueda abrir el PR de versión
gh api -X PUT repos/<dueño>/<repo>/actions/permissions/workflow \
  -f default_workflow_permissions=read -F can_approve_pull_request_reviews=true

# Proteger main (modo pr). En repos privados del plan gratuito responde 403: ver GUIA §3
gh api -X PUT repos/<dueño>/<repo>/branches/main/protection --input - <<'EOF'
{"required_status_checks":{"strict":false,"contexts":["ci"]},"enforce_admins":false,
 "required_pull_request_reviews":{"required_approving_review_count":0},
 "restrictions":null,"allow_force_pushes":false,"allow_deletions":false}
EOF
```

Comprueba cada uno leyéndolo de vuelta (`gh api repos/<dueño>/<repo> -q .delete_branch_on_merge`,
etc.) y deja `context/GIT_STATE.md` en modo `pr`. Si la protección da 403, dilo y sigue: las
reglas de `CLAUDE.md` siguen prohibiendo empujar a `main`.

## 2. Vercel

Requisitos: CLI (`bunx vercel --version`) con sesión (`bunx vercel whoami`). Si no hay
sesión, César corre `bunx vercel login`. Si el MCP de Vercel está conectado, se puede usar
para consultar despliegues y logs; crear y enlazar el proyecto va por CLI.

```bash
bunx vercel link --yes --scope <equipo>       # crea/enlaza el proyecto; añade .vercel a .gitignore
bunx vercel git connect                       # despliega con cada push: preview por PR, producción al mergear a main
bunx vercel env add NEXT_PUBLIC_SITE_URL production    # el valor lo da César (dominio final)
bunx vercel env add NEXT_PUBLIC_SITE_URL preview
```

- Framework: Next.js, detección automática; **bun** se detecta por `bun.lock`.
- `NEXT_PUBLIC_SITE_URL` sin dominio todavía: la URL `*.vercel.app` de producción, y queda
  fila en `CONTENT_CHECKLIST.md` para cambiarla al conectar el dominio.
- Todas las variables de `.env.example` que el build necesite, en los entornos que
  correspondan. **Los valores secretos los pone César** (o te los pasa por el canal que él
  elija); nunca se escriben en el repo ni en el chat.
- Dominio: `bunx vercel domains add <dominio>` y los registros DNS que imprima van a
  "Acciones de César" (los cambia quien gestione el DNS).
- Los previews por PR se enlazan solos en el PR (bot de Vercel): son la forma más rápida de
  que César revise sin levantar nada. Si el proyecto es privado y tiene Deployment
  Protection, el preview pide sesión de Vercel: normal.

### 2b. Adoptar un proyecto de Vercel que ya existe

Cuando el despliegue ya se hizo a mano (pasó: el proyecto vivía en Vercel y el repo no lo
sabía). No se crea otro: se enlaza el que hay y se comprueba que hace lo que el kit espera.

1. **Localizarlo** sin enlazar nada todavía: `bunx vercel project ls --scope <equipo>` (o
   el MCP de Vercel, `list_projects`). César confirma cuál es si hay dudas.
2. **Enlazar** ese, no uno nuevo: `bunx vercel link --yes --project <nombre> --scope <equipo>`
   → escribe `.vercel/project.json`. Comprueba el resultado con
   `bunx vercel project inspect --non-interactive` (dueño y proyecto correctos).
3. **Conexión con git**: que esté conectado al repo de GitHub del proyecto y que la rama
   de producción sea `main` (`vercel git connect` si no lo está). Sin eso no hay preview
   por PR.
4. **Variables**: `bunx vercel env ls` contra `.env.example`; lo que falte, como en §2
   (los valores secretos, César).
5. Abre un PR de prueba y confirma que el bot de Vercel deja el enlace del preview.

## 3. Después del primer despliegue

- [ ] Producción responde 200 en `/`, 404 en una ruta inventada (con la pantalla del sitio),
      y `robots.txt` / `sitemap.xml` con el dominio correcto.
- [ ] Tarjeta OG revisada sobre la URL desplegada (`reference/BRAND-ASSETS.md`).
- [ ] Variables de mantenimiento (`MAINTENANCE_MODE`, `MAINTENANCE_UNTIL`) definidas como
      apagadas o ausentes (`reference/STATUS-SCREENS.md`).
- [ ] `PROJECT_CONTEXT.md` › Despliegue con: proyecto de Vercel, URL de producción,
      dominio y quién gestiona el DNS.
