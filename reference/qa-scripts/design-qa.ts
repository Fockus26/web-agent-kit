/**
 * QA de diseño — barrido automatizado
 *
 * Uso:
 *   bun add -d @playwright/test @axe-core/playwright
 *   bunx playwright install chromium
 *   (el servidor corriendo, ver TOKEN-ECONOMY.md §1)
 *   node reference/qa-scripts/design-qa.ts
 *
 * Con node, no con bun: en Windows, Playwright lanzado desde un script de Bun se cuelga
 * al arrancar Chromium (comprobado). Node ≥ 23.6 ejecuta el .ts directamente.
 *
 * Genera capturas en qa-output/ y un reporte en qa-output/report.md.
 * Este script NO decide si algo está bien: recoge evidencia. El agente design-qa
 * la interpreta.
 */

import { chromium, type Page } from '@playwright/test'
import AxeBuilder from '@axe-core/playwright'
import { mkdir, writeFile } from 'node:fs/promises'

// ── Configuración ────────────────────────────────────────────────────────────
const BASE = process.env.BASE_URL ?? 'http://localhost:3000'
const ROUTES = ['/']                       // ajusta a las rutas del proyecto
const OUT = 'qa-output'

const WIDTHS = [320, 360, 390, 430, 768, 1024, 1280, 1440, 1920, 2560, 3840]

const CVD_FILTERS: Record<string, string> = {
  protanopia:    '0.567 0.433 0 0 0  0.558 0.442 0 0 0  0 0.242 0.758 0 0  0 0 0 1 0',
  deuteranopia:  '0.625 0.375 0 0 0  0.700 0.300 0 0 0  0 0.300 0.700 0 0  0 0 0 1 0',
  tritanopia:    '0.950 0.050 0 0 0  0 0.433 0.567 0 0  0 0.475 0.525 0 0  0 0 0 1 0',
  achromatopsia: '0.299 0.587 0.114 0 0  0.299 0.587 0.114 0 0  0.299 0.587 0.114 0 0  0 0 0 1 0',
}

type Finding = { route: string; kind: string; detail: string }
const findings: Finding[] = []
const slug = (s: string) => s.replace(/[^a-z0-9]+/gi, '-').replace(/^-|-$/g, '') || 'root'

// ── Comprobaciones ───────────────────────────────────────────────────────────

/** Scroll horizontal: el fallo #1 en anchos pequeños (WCAG 1.4.10). */
async function checkOverflow(page: Page, route: string, width: number) {
  const r = await page.evaluate(() => {
    const d = document.documentElement
    if (d.scrollWidth <= d.clientWidth) return null
    const guilty: string[] = []
    for (const el of document.querySelectorAll<HTMLElement>('*')) {
      const box = el.getBoundingClientRect()
      if (box.right > d.clientWidth + 1 || box.left < -1) {
        guilty.push(`${el.tagName.toLowerCase()}${el.className ? '.' + String(el.className).split(' ')[0] : ''}`)
      }
      if (guilty.length >= 5) break
    }
    return { scrollWidth: d.scrollWidth, clientWidth: d.clientWidth, guilty }
  })
  if (r) {
    findings.push({
      route, kind: `overflow@${width}`,
      detail: `scrollWidth ${r.scrollWidth} > viewport ${r.clientWidth}. Candidatos: ${r.guilty.join(', ')}`,
    })
  }
}

/** Objetivos táctiles por debajo de 44x44 en anchos de mobile. */
async function checkTapTargets(page: Page, route: string, width: number) {
  if (width > 768) return
  const small = await page.evaluate(() => {
    const out: string[] = []
    const sel = 'a, button, input, select, textarea, [role="button"], [role="link"]'
    for (const el of document.querySelectorAll<HTMLElement>(sel)) {
      const b = el.getBoundingClientRect()
      if (b.width === 0 || b.height === 0) continue
      if (b.width < 44 || b.height < 44) {
        out.push(`${el.tagName.toLowerCase()} "${(el.textContent ?? '').trim().slice(0, 24)}" ${Math.round(b.width)}x${Math.round(b.height)}`)
      }
    }
    return out.slice(0, 10)
  })
  if (small.length) {
    findings.push({ route, kind: `tap-target@${width}`, detail: small.join(' · ') })
  }
}

/** Líneas de texto excesivamente largas en pantallas grandes. */
async function checkLineLength(page: Page, route: string, width: number) {
  if (width < 1920) return
  const long = await page.evaluate(() => {
    const out: string[] = []
    for (const el of document.querySelectorAll<HTMLElement>('p, li')) {
      const text = (el.textContent ?? '').trim()
      if (text.length < 100) continue
      const fontSize = parseFloat(getComputedStyle(el).fontSize)
      const chars = el.getBoundingClientRect().width / (fontSize * 0.5)
      if (chars > 75) out.push(`~${Math.round(chars)} caracteres por línea: "${text.slice(0, 40)}…"`)
    }
    return out.slice(0, 5)
  })
  if (long.length) findings.push({ route, kind: `line-length@${width}`, detail: long.join(' · ') })
}

/** Recorrido de foco: detecta paradas invisibles o fuera del viewport. */
async function checkFocusOrder(page: Page, route: string) {
  const stops: string[] = []
  for (let i = 0; i < 60; i++) {
    await page.keyboard.press('Tab')
    const s = await page.evaluate(() => {
      const a = document.activeElement as HTMLElement | null
      if (!a || a === document.body) return null
      const b = a.getBoundingClientRect()
      const cs = getComputedStyle(a)
      return {
        tag: a.tagName.toLowerCase(),
        name: (a.getAttribute('aria-label') ?? a.textContent ?? '').trim().slice(0, 30),
        visible: b.width > 0 && b.height > 0,
        inViewport: b.top >= -1 && b.bottom <= window.innerHeight + 1,
        hasRing: cs.outlineStyle !== 'none' || cs.boxShadow !== 'none',
      }
    })
    if (!s) break
    const key = `${s.tag}:${s.name}`
    if (stops.includes(key) && stops.length > 3) break        // dio la vuelta
    stops.push(key)
    if (!s.visible) findings.push({ route, kind: 'focus-invisible', detail: `${key} — elemento enfocable sin dimensiones` })
    else if (!s.inViewport) findings.push({ route, kind: 'focus-offscreen', detail: `${key} — foco fuera del viewport` })
    else if (!s.hasRing) findings.push({ route, kind: 'focus-no-ring', detail: `${key} — sin indicador de foco visible` })
  }
}

/** Valores de color fuera de la paleta no se detectan aquí — eso es grep sobre el código. */

// ── Barrido ──────────────────────────────────────────────────────────────────
async function run() {
  await mkdir(OUT, { recursive: true })
  const browser = await chromium.launch()

  for (const route of ROUTES) {
    const rs = slug(route)

    // 1. Barrido de anchos
    for (const width of WIDTHS) {
      const ctx = await browser.newContext({ viewport: { width, height: 900 } })
      const page = await ctx.newPage()
      await page.goto(BASE + route, { waitUntil: 'networkidle' })
      await page.screenshot({ path: `${OUT}/${rs}-w${width}.png`, fullPage: true })
      await checkOverflow(page, route, width)
      await checkTapTargets(page, route, width)
      await checkLineLength(page, route, width)
      await ctx.close()
    }

    // 2. Daltonismo (a 1440)
    for (const [name, matrix] of Object.entries(CVD_FILTERS)) {
      const ctx = await browser.newContext({ viewport: { width: 1440, height: 900 } })
      const page = await ctx.newPage()
      await page.goto(BASE + route, { waitUntil: 'networkidle' })
      await page.addStyleTag({
        content: `html{filter:url(#cvd)}`,
      })
      await page.evaluate((m) => {
        const ns = 'http://www.w3.org/2000/svg'
        const svg = document.createElementNS(ns, 'svg')
        svg.setAttribute('style', 'position:absolute;width:0;height:0')
        svg.innerHTML = `<filter id="cvd"><feColorMatrix type="matrix" values="${m}"/></filter>`
        document.body.appendChild(svg)
      }, matrix)
      await page.screenshot({ path: `${OUT}/${rs}-cvd-${name}.png`, fullPage: true })
      await ctx.close()
    }

    // 3. Preferencias del sistema
    for (const [name, opts] of Object.entries({
      dark:           { colorScheme: 'dark' as const },
      'reduced-motion': { reducedMotion: 'reduce' as const },
      'forced-colors':  { forcedColors: 'active' as const },
    })) {
      const ctx = await browser.newContext({ viewport: { width: 1440, height: 900 } })
      const page = await ctx.newPage()
      await page.emulateMedia(opts)
      await page.goto(BASE + route, { waitUntil: 'networkidle' })
      await page.screenshot({ path: `${OUT}/${rs}-${name}.png`, fullPage: true })
      await ctx.close()
    }

    // 4. Zoom 400% (reflow, WCAG 1.4.10)
    {
      const ctx = await browser.newContext({ viewport: { width: 1280, height: 800 } })
      const page = await ctx.newPage()
      await page.goto(BASE + route, { waitUntil: 'networkidle' })
      await page.evaluate(() => { document.body.style.zoom = '400%' })
      await page.waitForTimeout(300)
      await checkOverflow(page, route, 1280)
      await page.screenshot({ path: `${OUT}/${rs}-zoom400.png`, fullPage: true })
      await ctx.close()
    }

    // 5. Foco y teclado
    {
      const ctx = await browser.newContext({ viewport: { width: 1440, height: 900 } })
      const page = await ctx.newPage()
      await page.goto(BASE + route, { waitUntil: 'networkidle' })
      await checkFocusOrder(page, route)
      await ctx.close()
    }

    // 6. axe-core, en claro y oscuro
    for (const scheme of ['light', 'dark'] as const) {
      const ctx = await browser.newContext({ viewport: { width: 1440, height: 900 } })
      const page = await ctx.newPage()
      await page.emulateMedia({ colorScheme: scheme })
      await page.goto(BASE + route, { waitUntil: 'networkidle' })
      const { violations } = await new AxeBuilder({ page })
        .withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa'])
        .analyze()
      for (const v of violations) {
        findings.push({
          route, kind: `axe-${scheme}:${v.impact}`,
          detail: `${v.id} — ${v.help} — ${v.nodes.slice(0, 3).map(n => n.target.join(' ')).join(' | ')} — ${v.helpUrl}`,
        })
      }
      await ctx.close()
    }
  }

  await browser.close()

  // ── Reporte ────────────────────────────────────────────────────────────────
  const byRoute = new Map<string, Finding[]>()
  for (const f of findings) {
    if (!byRoute.has(f.route)) byRoute.set(f.route, [])
    byRoute.get(f.route)!.push(f)
  }

  let md = `# QA de diseño — evidencia automatizada\n\n`
  md += `**Base:** ${BASE}  ·  **Rutas:** ${ROUTES.join(', ')}  ·  **Hallazgos:** ${findings.length}\n\n`
  md += `> Esto es evidencia recogida, no un juicio. El agente \`design-qa\` la interpreta,\n`
  md += `> revisa las capturas de \`${OUT}/\` y produce el reporte final con severidades.\n\n`

  for (const [route, fs] of byRoute) {
    md += `## ${route}\n\n| Tipo | Detalle |\n|---|---|\n`
    for (const f of fs) md += `| \`${f.kind}\` | ${f.detail.replace(/\|/g, '\\|')} |\n`
    md += `\n`
  }
  if (!findings.length) md += `Sin hallazgos automáticos. **Revisa igual las capturas a mano** — lo visual no lo detecta un script.\n`

  await writeFile(`${OUT}/report.md`, md)
  console.log(`\n${findings.length} hallazgos. Reporte: ${OUT}/report.md · Capturas: ${OUT}/\n`)
}

run()
