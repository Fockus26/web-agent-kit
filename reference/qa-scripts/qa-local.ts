/**
 * Servidor de QA contra una base LOCAL — nunca contra la de verdad.
 *
 * Uso (con node; Node ≥ 23.6):
 *   node scripts/qa-local.ts --port 4301            (= bun run qa:local -- --port 4301)
 *   node scripts/qa-local.ts --port 4301 --no-reset (conserva los datos de la corrida anterior)
 *   node scripts/qa-local.ts --port 4301 --offline  (sin Docker ni base: solo invitado)
 *
 * Qué hace:
 *   1. `supabase start` (Docker Desktop abierto): la pila local del proyecto.
 *   2. `supabase db reset`: base vacía con las migraciones y el seed del árbol actual (en un
 *      slot del pool, las de `main`). La base local es desechable: no guardes nada en ella.
 *   3. Crea las cuentas de prueba de `.env.test.local` en esa base (Auth de la pila local):
 *        EMAIL_TEST / PASSWORD_TEST              → rol "user"
 *        ADMIN_EMAIL_TEST / ADMIN_PASSWORD_TEST  → rol "admin"
 *        <ROL>_EMAIL_TEST / <ROL>_PASSWORD_TEST  → rol "<rol>"
 *      El rol va a `app_metadata.role`. Si el proyecto lo decide de otra forma, es la única
 *      parte propia de cada proyecto:
 *        - rol en una tabla (`profiles`) o acceso por suscripción/plan → `asignarRol`;
 *        - rol por una lista de correos en una variable (`ADMIN_EMAILS`) → `ROL_POR_ENV`.
 *   4. Levanta `bun run dev -- --port <puerto>` con las variables de Supabase apuntando a la
 *      pila local. Van por process.env, que gana a los `.env*` tanto en Next como en Vite
 *      (Astro, SvelteKit…): no se escribe ningún archivo y el slot queda limpio.
 *
 * Con `--offline` (máquina sin Docker, o el proyecto aún sin `supabase/config.toml` ni
 * migraciones): no levanta ninguna base. Las variables de Supabase se apuntan a una
 * dirección muerta (127.0.0.1:9) y el servidor arranca: se prueba como invitado y lo que
 * necesite datos falla en vez de tocar la base real.
 *
 * Antes de arrancar comprueba que el puerto está libre: si no, aborta (el servidor
 * saltaría al siguiente sin avisar y podría caer en el de otro slot del pool). Para
 * pararlo, en Windows: `taskkill /PID <pid de este script> /T /F` (con /T cae también el
 * servidor; un kill normal deja huérfano al hijo ocupando el puerto).
 *
 * Seguro: antes de arrancar, si alguna variable de `.env*` apunta a un Supabase remoto
 * (`*.supabase.co`) y este script no la sobrescribe, se aborta. Mejor no arrancar que
 * probar contra la base real por una variable con un nombre distinto.
 *
 * Los correos que mande la app (registro, recuperación) no salen: los recoge Mailpit
 * (la URL se imprime al arrancar).
 *
 * Sin `supabase/config.toml` (el proyecto no usa Supabase): arranca el servidor normal.
 *
 * Las contraseñas de prueba no se imprimen nunca. Las claves locales de la pila sí son
 * públicas (las mismas en toda instalación) y no son secretos.
 */

import { spawn, spawnSync } from 'node:child_process'
import { existsSync, readdirSync, readFileSync } from 'node:fs'
import { connect } from 'node:net'

// Variable de la app ← campo de `supabase status -o json`, para Next (NEXT_PUBLIC_*), Vite
// (VITE_*) y Astro (PUBLIC_*). Añade aquí la que use tu proyecto si tiene otro nombre (el
// chequeo de seguridad te avisará si falta alguna).
const MAPEO: Record<string, string> = {}
for (const prefijo of ['', 'NEXT_PUBLIC_', 'PUBLIC_', 'VITE_']) {
  MAPEO[`${prefijo}SUPABASE_URL`] = 'API_URL'
  MAPEO[`${prefijo}SUPABASE_ANON_KEY`] = 'ANON_KEY'
  MAPEO[`${prefijo}SUPABASE_PUBLISHABLE_KEY`] = 'PUBLISHABLE_KEY'
}
Object.assign(MAPEO, {
  SUPABASE_SERVICE_ROLE_KEY: 'SERVICE_ROLE_KEY',
  SUPABASE_SECRET_KEY: 'SECRET_KEY',
  DATABASE_URL: 'DB_URL',
  DIRECT_URL: 'DB_URL',
})

// Rol decidido por una lista de correos en una variable de entorno (p. ej. la app es admin
// si el correo está en ADMIN_EMAILS): rol → variable. El script la rellena con los correos
// de prueba de ese rol al arrancar el servidor. Vacío si el rol vive en la base.
const ROL_POR_ENV: Record<string, string> = {
  // admin: 'ADMIN_EMAILS',
}

const args = process.argv.slice(2)
const puerto = args[args.indexOf('--port') + 1]
if (!args.includes('--port') || !/^\d+$/.test(puerto ?? '')) {
  console.error('Uso: node scripts/qa-local.ts --port <puerto> [--no-reset] [--offline]')
  process.exit(2)
}
const reset = !args.includes('--no-reset')
const offline = args.includes('--offline')

// Un error en cualquier paso termina el proceso con un mensaje, en vez de dejarlo colgado.
function abortar(mensaje: string): never {
  console.error(mensaje)
  if (!offline) console.error('→ Sin Docker o sin base local, se puede probar como invitado con --offline.')
  process.exit(1)
}

// Ocupado = algo responde en IPv4 o en IPv6: hay servidores (Astro) que escuchan solo en
// [::1], y entonces reservar 127.0.0.1 saldría bien aunque el puerto esté en uso.
function responde(host: string, p: number): Promise<boolean> {
  return new Promise((resolver) => {
    const s = connect({ host, port: p })
    s.setTimeout(1000)
    s.once('connect', () => (s.destroy(), resolver(true)))
    s.once('timeout', () => (s.destroy(), resolver(false)))
    s.once('error', () => resolver(false))
  })
}
const ocupado = (await responde('127.0.0.1', Number(puerto))) || (await responde('::1', Number(puerto)))
if (ocupado) {
  console.error(
    `El puerto ${puerto} está ocupado (¿un servidor anterior de este slot?). No se arranca en otro:\n` +
      'el servidor saltaría al siguiente libre, que puede ser el de otro slot. Para el proceso que lo usa.',
  )
  process.exit(1)
}

function leerEnv(archivo: string): Record<string, string> {
  if (!existsSync(archivo)) return {}
  const salida: Record<string, string> = {}
  for (const linea of readFileSync(archivo, 'utf8').split(/\r?\n/)) {
    const m = linea.match(/^\s*(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)\s*$/)
    if (m) salida[m[1]] = m[2].replace(/^(['"])(.*)\1$/, '$2')
  }
  return salida
}

function supabase(...a: string[]): string {
  const r = spawnSync('supabase', a, { encoding: 'utf8', shell: process.platform === 'win32' })
  if (r.status !== 0) {
    const detalle = (r.stderr || r.stdout || '').trim()
    const docker = /docker|daemon|pipe/i.test(detalle) ? '\n→ ¿Está abierto Docker Desktop?' : ''
    abortar(`supabase ${a.join(' ')} falló:\n${detalle}${docker}`)
  }
  return r.stdout
}

// No vuelve: el script vive mientras viva el servidor.
function arrancarDev(env: NodeJS.ProcessEnv): Promise<never> {
  const hijo = spawn('bun', ['run', 'dev', '--', '--port', puerto], {
    stdio: 'inherit',
    env,
    shell: process.platform === 'win32',
  })
  // En Windows, con shell: true, `hijo` es la shell: kill() la mata a ella y el servidor
  // queda huérfano ocupando el puerto. taskkill /T tumba el árbol entero.
  const parar = () => {
    if (process.platform === 'win32' && hijo.pid) {
      spawnSync('taskkill', ['/PID', String(hijo.pid), '/T', '/F'], { stdio: 'ignore' })
    } else hijo.kill('SIGTERM')
  }
  for (const s of ['SIGINT', 'SIGTERM'] as const) process.on(s, parar)
  hijo.on('exit', (code) => process.exit(code ?? 0))
  return new Promise<never>(() => {})
}

// 1. ¿Hay algo que apunte a un Supabase remoto?
const envArchivos = readdirSync('.').filter((f) => /^\.env/.test(f) && f !== '.env.example')
const remotas = envArchivos.flatMap((f) =>
  Object.entries(leerEnv(f))
    .filter(([, v]) => /\.supabase\.(co|com)/i.test(v))
    .map(([k]) => ({ archivo: f, clave: k })),
)

if (offline) {
  // Todo lo que podría llegar a una base (lo de MAPEO y cualquier variable que apunte a un
  // Supabase remoto) va a una dirección donde no escucha nadie.
  const muerta = (k: string) =>
    MAPEO[k] === 'DB_URL'
      ? 'postgresql://offline@127.0.0.1:9/offline'
      : /URL$/.test(k)
        ? 'http://127.0.0.1:9'
        : 'offline'
  const env: NodeJS.ProcessEnv = { ...process.env, QA_LOCAL: '1', QA_OFFLINE: '1' }
  for (const k of [...Object.keys(MAPEO), ...remotas.map((r) => r.clave)]) env[k] = muerta(k)
  console.log('--offline: sin base. Las variables de la base apuntan a 127.0.0.1:9; solo se prueba como invitado.')
  console.log(`… bun run dev en el puerto ${puerto}`)
  await arrancarDev(env)
}

if (!existsSync('supabase/config.toml')) {
  if (remotas.length) {
    abortar(
      'Hay variables que apuntan a un Supabase remoto pero el proyecto no tiene supabase/ local:\n' +
        remotas.map((r) => `  ${r.archivo}: ${r.clave}`).join('\n') +
        '\nLa QA no corre contra la base real. Hace falta `supabase init` y las migraciones en el repo (backend-build).',
    )
  }
  console.log('Sin supabase/config.toml: no hay base externa que sustituir. Servidor normal.')
  await arrancarDev(process.env)
}

const sinCubrir = remotas.filter((r) => !(r.clave in MAPEO))
if (sinCubrir.length) {
  abortar(
    'Estas variables apuntan a Supabase remoto y el script no las sobrescribe (añádelas a MAPEO):\n' +
      sinCubrir.map((r) => `  ${r.archivo}: ${r.clave}`).join('\n'),
  )
}

// 2. Pila local y base limpia.
console.log('… supabase start')
supabase('start')
if (reset) {
  console.log('… supabase db reset (migraciones + seed)')
  supabase('db', 'reset')
}
const estado = JSON.parse(supabase('status', '-o', 'json')) as Record<string, string>
const api = estado.API_URL
const claveServicio = estado.SERVICE_ROLE_KEY
if (!api || !claveServicio) abortar('supabase status no devolvió API_URL / SERVICE_ROLE_KEY')

// 3. Cuentas de prueba.
async function asignarRol(id: string, rol: string): Promise<void> {
  // Por defecto el rol ya va en app_metadata al crear la cuenta. Si tu proyecto lo guarda en
  // una tabla, haz aquí el upsert con la API REST local, p. ej.:
  //   await fetch(`${api}/rest/v1/profiles`, { method: 'POST', headers: { ...cabeceras,
  //     Prefer: 'resolution=merge-duplicates' }, body: JSON.stringify({ id, role: rol }) })
  // Si el acceso depende de una suscripción o un plan (sin ella, el usuario solo ve el muro
  // de pago), dale aquí acceso a la cuenta de prueba del rol que lo necesite, p. ej.:
  //   if (rol === 'user') await fetch(`${api}/rest/v1/subscriptions`, { method: 'POST',
  //     headers: cabeceras, body: JSON.stringify({ user_id: id, plan: 'pro', status: 'active' }) })
  // Si el rol se decide por una lista de correos en una variable, no es aquí: ROL_POR_ENV.
  void id
  void rol
}

const cabeceras = {
  apikey: claveServicio,
  Authorization: `Bearer ${claveServicio}`,
  'Content-Type': 'application/json',
}
const pruebas = leerEnv('.env.test.local')
const cuentas = Object.keys(pruebas)
  .map((k) => k.match(/^(?:([A-Z0-9_]+)_)?EMAIL_TEST$/))
  .filter((m): m is RegExpMatchArray => m !== null)
  .map((m) => {
    const prefijo = m[1] ? `${m[1]}_` : ''
    return {
      rol: m[1] ? m[1].toLowerCase() : 'user',
      email: pruebas[`${prefijo}EMAIL_TEST`],
      password: pruebas[`${prefijo}PASSWORD_TEST`],
    }
  })

if (!cuentas.length) console.warn('! .env.test.local sin *_EMAIL_TEST: la QA solo podrá probar lo público.')
for (const c of cuentas) {
  if (!c.email || !c.password) {
    console.warn(`! rol ${c.rol}: falta el correo o la contraseña en .env.test.local; se salta`)
    continue
  }
  const r = await fetch(`${api}/auth/v1/admin/users`, {
    method: 'POST',
    headers: cabeceras,
    body: JSON.stringify({
      email: c.email,
      password: c.password,
      email_confirm: true,
      app_metadata: { role: c.rol },
    }),
  })
  if (r.ok) {
    const { id } = (await r.json()) as { id: string }
    await asignarRol(id, c.rol)
    console.log(`  + cuenta de prueba: rol ${c.rol}`)
  } else if (r.status === 422 && !reset) {
    console.log(`  = cuenta de prueba: rol ${c.rol} (ya existía)`)
  } else {
    abortar(`No se pudo crear la cuenta del rol ${c.rol}: ${r.status} ${await r.text()}`)
  }
}

// 4. Servidor apuntando a la pila local.
const env: NodeJS.ProcessEnv = { ...process.env, QA_LOCAL: '1' }
for (const [variable, campo] of Object.entries(MAPEO)) {
  if (estado[campo]) env[variable] = estado[campo]
}
for (const [rol, variable] of Object.entries(ROL_POR_ENV)) {
  env[variable] = cuentas.filter((c) => c.rol === rol && c.email).map((c) => c.email).join(',')
}
console.log(`Base local: ${api}${estado.MAILPIT_URL ? ` · correos en ${estado.MAILPIT_URL}` : ''}`)
console.log(`… bun run dev en el puerto ${puerto}`)
await arrancarDev(env)
