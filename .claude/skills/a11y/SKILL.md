---
name: a11y
description: Puerta de accesibilidad WCAG 2.1 AA obligatoria antes de cerrar cualquier unidad de trabajo de frontend. Úsala siempre que termines un componente, una sección, una página o una fase de UI, ANTES de pedirle revisión a César y ANTES de cualquier commit. Cubre semántica, teclado, foco, ARIA, contraste, estados no visuales y movimiento, con verificación automática vía axe-core cuando hay entorno.
---

# Accesibilidad (WCAG 2.1 AA)

Esta skill es una **puerta**, no una sugerencia. Ninguna unidad de frontend llega a la
revisión de César sin haber pasado por aquí. El orden es siempre:

```
implementar → [a11y] → (seo si aplica) → pedir revisión → [git-flow] commit
```

Nunca al revés. Arreglar accesibilidad después del commit significa un segundo commit para
algo que debió salir bien la primera vez.

---

## 1. Verificación automática primero

Si el proyecto tiene entorno ejecutable, corre axe antes de leer nada a mano — es más rápido
y encuentra lo mecánico.

```bash
bun add -d @axe-core/playwright   # si no está
```

```ts
// scripts/a11y-check.ts
import { chromium } from '@playwright/test'
import AxeBuilder from '@axe-core/playwright'

const URLS = ['/', '/pricing']            // ajusta a lo que acabas de tocar
const BASE = process.env.BASE_URL ?? 'http://localhost:3000'

const browser = await chromium.launch()
let failed = false

for (const path of URLS) {
  const page = await browser.newPage()
  await page.goto(BASE + path, { waitUntil: 'networkidle' })

  const { violations } = await new AxeBuilder({ page })
    .withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa'])
    .analyze()

  for (const v of violations) {
    failed = true
    console.log(`\n[${v.impact}] ${v.id} — ${v.help}`)
    console.log(`  ${v.helpUrl}`)
    for (const node of v.nodes) console.log(`  → ${node.target.join(' ')}`)
  }
  await page.close()
}

await browser.close()
process.exit(failed ? 1 : 0)
```

```bash
# El servidor lo levanta César, no tú. Pídeselo y espera confirmación:
#   "Necesito el server corriendo para pasar axe. Levanta `bun dev` y avísame."
node scripts/a11y-check.ts   # con node, no con bun: en Windows, Playwright bajo Bun se cuelga al lanzar Chromium
```

Si César no quiere levantarlo ahora, **no insistas ni lo levantes tú**: haz la revisión
manual, y marca en la salida que axe quedó sin correr.

axe cubre aproximadamente el 40% de los criterios WCAG. **El resto es la revisión manual de
abajo — no la saltes porque axe salió verde.**

### Lighthouse (además de axe, no en lugar de)

axe es más preciso para accesibilidad; Lighthouse suma la categoría **Best Practices**
(errores de consola, imágenes sin dimensiones, libs con vulnerabilidades conocidas) y da
un número comparable en el tiempo. Corre el build de producción, no `dev`.

```bash
bun add -d lighthouse chrome-launcher   # si no está
```

```ts
// scripts/lighthouse.ts — corre con `node`, no `bun` (Lighthouse lanza Chrome real)
import { launch } from 'chrome-launcher'
import lighthouse from 'lighthouse'
import desktopConfig from 'lighthouse/core/config/desktop-config.js'

const BASE = process.env.BASE_URL ?? 'http://localhost:3000'
const ROUTES = ['/', '/pricing']         // ajusta
const CATS = ['performance', 'accessibility', 'best-practices', 'seo'] as const

const chrome = await launch({ chromeFlags: ['--headless=new', '--no-sandbox'] })
let failed = false

for (const route of ROUTES) {
  const { lhr } = (await lighthouse(BASE + route, { port: chrome.port, logLevel: 'error' }, desktopConfig))!
  const scores = CATS.map((c) => `${c} ${Math.round((lhr.categories[c]?.score ?? 0) * 100)}`).join('  ·  ')
  console.log(`\n━━ ${route}  →  ${scores}`)
  for (const cat of CATS) {
    const problems = (lhr.categories[cat]?.auditRefs ?? [])
      .map((r) => lhr.audits[r.id])
      .filter((a) => a && a.score !== null && a.score < 1 && !['informative', 'manual', 'notApplicable'].includes(a.scoreDisplayMode))
    if (!problems.length) continue
    // el dashboard/panel privado es `noindex` a propósito: no falles su SEO
    if ((cat === 'accessibility' || (cat === 'seo' && !route.startsWith('/dashboard'))) && (lhr.categories[cat].score ?? 0) < 1) failed = true
    console.log(`  ${cat}:`)
    for (const a of problems) console.log(`    • ${a.title}\n      ${a.description.replace(/\s*\[.*?\]\(.*?\)/g, '').replace(/\n/g, ' ').trim()}`)
  }
}
await chrome.kill().catch(() => {})   // EPERM al borrar el temp en Windows, inofensivo
process.exit(failed ? 1 : 0)
```

```bash
# `--mobile` para pasar `undefined` como config (el default de Lighthouse emula móvil)
bun run build && bun run start   # otra terminal
node scripts/lighthouse.ts
```

Metas: **accesibilidad y best-practices = 100**, **SEO = 100** en rutas públicas.
Performance ≥ 90 (el resto lo cubre la skill `seo`). El score de SEO en una página
`noindex` intencional no cuenta.

Los ítems de accesibilidad que Lighthouse marca casi siempre ya los agarró axe; los de
Best Practices son nuevos y hay que atender: un `errors-in-console` suele ser un `fetch`
roto o un script de terceros que no existe en ese entorno (ej. `@vercel/analytics` fuera
de Vercel — condiciónalo a `process.env.VERCEL`).

---

## 2. Revisión manual — checklist base

Aplica a todo lo que hayas tocado.

### Semántica
- [ ] Un solo `<h1>` por página; jerarquía `h1 → h2 → h3` sin saltar niveles.
- [ ] Landmarks presentes: `<header>`, `<nav>`, `<main>`, `<footer>`, `<aside>`. Un solo
      `<main>`. Si hay dos `<nav>`, cada uno con `aria-label` distinto.
- [ ] Listas reales (`<ul>/<li>`) para lo que es una lista, no `<div>` apilados.
- [ ] Cero `<div onClick>` sin rol: si es clickeable, es `<button>` o `<a>`. Un `<a>` sin
      `href` no es enfocable.
- [ ] `<a>` navega, `<button>` acciona. No los intercambies porque uno se veía mejor.

### Teclado
- [ ] Todo lo interactivo se alcanza con `Tab` y se activa con `Enter` (y `Space` en botones).
- [ ] El orden de tab sigue el orden visual. Cero `tabindex` positivo.
- [ ] Anillo de foco **visible siempre** y con contraste ≥ 3:1 contra el fondo. Si quitaste
      el outline por diseño, tienes que haber puesto algo en su lugar:
      `focus-visible:ring-2 focus-visible:ring-offset-2`.
- [ ] Cero trampas de foco: de todo se sale con `Tab` o `Escape`.
- [ ] Modales/drawers: el foco entra al abrir, queda atrapado dentro mientras está abierto,
      `Escape` cierra, y al cerrar el foco **vuelve al elemento que lo abrió**.
- [ ] Hay un "skip to content" si el nav tiene más de ~5 enlaces.

### Nombre accesible
- [ ] Todo control tiene nombre: texto visible, `aria-label`, o `aria-labelledby`.
- [ ] Botones de solo ícono → `aria-label` descriptivo de la **acción**, no del ícono
      ("Cerrar menú", no "equis").
- [ ] Enlaces con texto que significa algo fuera de contexto. "Leer más" ×6 en una página es
      un fallo real: usa `aria-label` para diferenciarlos.
- [ ] `<img>` con `alt` real; decorativas con `alt=""` (vacío, no ausente).
- [ ] SVG informativo: `role="img"` + `<title>`. SVG decorativo: `aria-hidden="true"`.

### Formularios
- [ ] Cada input con `<label>` asociado por `htmlFor`/`id`. Un placeholder **no** es label.
- [ ] Errores asociados por `aria-describedby` y anunciados con `role="alert"` o
      `aria-live="polite"`.
- [ ] Campo inválido marcado con `aria-invalid="true"`.
- [ ] El mensaje de error dice **cómo arreglarlo**, no solo que está mal.
- [ ] `autocomplete` correcto en campos de datos personales (`email`, `name`, `tel`,
      `street-address`, `cc-number`…).
- [ ] Campos requeridos indicados con texto o `aria-required`, no solo con un asterisco rojo.

### Estados no visuales
- [ ] Ningún estado se comunica **solo con color**. Error, éxito, seleccionado, activo:
      siempre color **+** ícono, texto o forma.
- [ ] Loading: `aria-busy="true"` o un `aria-live` que anuncie el resultado al terminar.
- [ ] Deshabilitado: `disabled` real (no solo `opacity-50` + `pointer-events-none`).
- [ ] Toggles/tabs/accordions con `aria-expanded`, `aria-selected`, `aria-controls` según
      el patrón APG correspondiente.

### Contraste
- [ ] Texto normal ≥ 4.5:1 contra su fondo real.
- [ ] Texto grande (≥24px, o ≥19px bold) ≥ 3:1.
- [ ] Bordes de inputs, íconos informativos y anillos de foco ≥ 3:1.
- [ ] Texto sobre imagen o gradiente: verifica contra la zona **más clara** de la imagen, no
      contra el promedio. Si no da, hace falta un overlay o un scrim.
- [ ] Verifica en modo claro **y** oscuro si el proyecto tiene ambos.

### Movimiento y tiempo
- [ ] `prefers-reduced-motion: reduce` respetado: animaciones de decoración se apagan o se
      reducen a un fade.
- [ ] Nada parpadea más de 3 veces por segundo.
- [ ] Carruseles y autoplay con control de pausa. Nada que se mueva solo sin poder pararlo.
- [ ] Sin límites de tiempo que no se puedan extender.

### Media
- [ ] Video con subtítulos (`<track kind="captions">`). Sin subtítulos, el video no está
      terminado.
- [ ] Audio con transcripción.
- [ ] Nada con autoplay y sonido.

### Zoom y reflow
- [ ] A 200% de zoom no se pierde contenido ni funcionalidad.
- [ ] A 320px de ancho **no hay scroll horizontal** (WCAG 1.4.10). Esta es la que más falla:
      revisa tablas, `min-width` fijos, y texto largo sin `break-words`.

---

## 3. Hallazgo de implementación vs. decisión de diseño

Esta distinción decide si arreglas o escalas.

- **De implementación** — falta un `alt`, falta un `aria-label`, el foco no es visible, el
  orden de tab está mal, no hay `<label>`. **Arréglalo tú mismo, en el momento.**

- **De decisión de diseño** — el token `primary` de la paleta no llega a 4.5:1 sobre el
  fondo claro; la tipografía base de 13px es ilegible; el estado activo solo se distingue
  por color en todo el sistema. **No lo parches en un componente suelto.** Parchear el
  síntoma en un sitio deja el mismo bug en los otros veinte y rompe la consistencia del
  sistema.

  Para estos: repórtalo, propón el cambio concreto de token, y escálalo a César. Si él lo
  aprueba, el cambio va en `context/COLORS.md` o `DESIGN_TOKENS.md` **y** en el theme, con
  su fila en `decisions/` — no en el componente.

**Nunca inventes contenido para tapar un hallazgo.** Si falta un `alt` real, un texto de
error o una transcripción, pon un placeholder marcado y agrega la fila a
`context/CONTENT_CHECKLIST.md`. Redactar tú el copy final y entregarlo como definitivo es
peor que dejarlo pendiente: se cuela a producción sin que nadie lo revise.

---

## 4. Severidades

| Nivel | Qué es | Qué hacer |
|---|---|---|
| **Crítico** | Bloquea a usuarios de teclado o lector de pantalla; falla AA en texto de uso común | Arreglar antes de cerrar. Sin excepción. |
| **Alto** | Degrada mucho pero tiene workaround (jerarquía de headings rota, landmark faltante) | Arreglar antes de cerrar, salvo que César diga otra cosa. |
| **Medio** | Mejora recomendada, no bloqueante | Arreglar si es barato; si no, registrar. |
| **Bajo** | Buena práctica | Registrar y seguir. |

---

## 5. Salida

Cierra siempre con este bloque, aunque salga limpio:

```
## a11y — <componente/sección/página>

**axe-core:** <N violaciones / ✅ 0 / ⚠️ no se pudo ejecutar: razón>
**Revisión manual:** <N hallazgos>

### Corregido
- [<nivel>] <qué estaba mal> → <qué se cambió> (<archivo>)

### Escalado a decisión de diseño
- [<nivel>] <qué falla> — token/regla afectada: <cuál>
  Propuesta: <cambio concreto> · Decide: César

### Contenido pendiente
- <qué falta> → fila #<N> en CONTENT_CHECKLIST.md

**Estado de la puerta:** ✅ pasa / ⚠️ pasa con N hallazgos abiertos / ❌ no pasa
```

Si el estado es ❌, **no continúes al commit**. Si es ⚠️, César tiene que aceptar
explícitamente los hallazgos abiertos antes de que `git-flow` siga.

---

## 6. Referencias de patrones

Cuando implementes un widget compuesto (tabs, combobox, menú, disclosure, dialog, tooltip,
treeview), **no lo improvises**: sigue el patrón de WAI-ARIA Authoring Practices para ese
widget exacto. Si el proyecto usa shadcn/ui o Radix, esos primitivos ya implementan el patrón
correcto — úsalos en vez de reescribir el comportamiento de teclado a mano. Es el caso donde
"lo hago yo rápido" produce más bugs de accesibilidad que cualquier otro.
