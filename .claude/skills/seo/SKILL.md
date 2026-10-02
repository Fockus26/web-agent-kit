---
name: seo
description: SEO técnico del kit. Úsala en tres momentos - al inicializar el repo de un proyecto (metadata base, robots, sitemap, favicons), al cerrar una sección que trae contenido real, y al cerrar una página completa. Cubre metadata por página, Open Graph, canonical, JSON-LD schema.org, sitemap/robots y los patrones de imagen y fuente que afectan Core Web Vitals.
---

# SEO técnico

Solo la parte de SEO que es **implementación de código**. Estrategia de keywords,
investigación de competencia y planificación de contenido están fuera de alcance: eso es
trabajo de marketing y no lo decides tú.

---

## Cuándo se activa

| Disparador | Qué se hace |
|---|---|
| **Init del repo** | Bloque 1 completo: metadata base, robots, sitemap, favicons, fuentes |
| **Cierre de sección con contenido real** | Headings, imágenes, enlaces internos, JSON-LD si la sección lo amerita (FAQ, reseñas, breadcrumb) |
| **Cierre de página** | Metadata específica de la página + JSON-LD de su tipo + entrada en el sitemap |

Corre **después** de `a11y` y **antes** de la revisión de César, dentro de la misma unidad de
trabajo. Nunca después del commit.

---

## Bloque 1 — Init del repo (una vez por proyecto)

### Metadata base — `app/layout.tsx`

```tsx
import type { Metadata } from 'next'

export const metadata: Metadata = {
  metadataBase: new URL(process.env.NEXT_PUBLIC_SITE_URL!),
  title: {
    default: '{{Nombre}} — {{propuesta de valor en ≤60 caracteres}}',
    template: '%s | {{Nombre}}',
  },
  description: '{{PENDIENTE — ver CONTENT_CHECKLIST.md}}',
  openGraph: {
    type: 'website',
    locale: '{{es_VE}}',
    siteName: '{{Nombre}}',
    url: '/',
  },
  twitter: { card: 'summary_large_image' },
  robots: { index: true, follow: true },
  alternates: { canonical: '/' },
}
```

`NEXT_PUBLIC_SITE_URL` va a `.env.example` desde el día uno. Sin `metadataBase` todas las
URLs de OG y canonical salen relativas y **no funcionan al compartir**.

### `app/robots.ts`

```ts
import type { MetadataRoute } from 'next'

export default function robots(): MetadataRoute.Robots {
  return {
    rules: { userAgent: '*', allow: '/', disallow: ['/api/', '/admin/', '/cuenta/'] },
    sitemap: `${process.env.NEXT_PUBLIC_SITE_URL}/sitemap.xml`,
  }
}
```

### `app/sitemap.ts`

```ts
import type { MetadataRoute } from 'next'

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const base = process.env.NEXT_PUBLIC_SITE_URL!
  return [
    { url: base,            lastModified: new Date(), changeFrequency: 'weekly',  priority: 1 },
    { url: `${base}/precios`, lastModified: new Date(), changeFrequency: 'monthly', priority: 0.8 },
    // rutas dinámicas: mapearlas desde la fuente de datos, no a mano
  ]
}
```

Si hay rutas dinámicas (productos, artículos), el sitemap **se genera desde los datos**. Un
sitemap escrito a mano queda desactualizado la primera semana.

### Assets de marca: favicon, touch icon, manifest y OG

Antes de crear nada, mira `PROJECT_CONTEXT.md` › Assets de marca: el arranque dejó escrito,
pieza por pieza, si **lo tiene el cliente**, si **hay que crearlo** (y si Claude Design ya lo
entregó) o si **no aplica**. Si esa sección no existe, pregúntaselo a César — no asumas que
hay que generarlo ni que el cliente lo tiene. Tamaños, archivos y reglas:
`reference/BRAND-ASSETS.md` del kit.

- `app/favicon.ico`, `app/icon.svg` (+ `icon.png` 512), `app/apple-icon.png` (180×180,
  fondo opaco), `app/manifest.ts` (192, 512 y maskable). Todo derivado de **un** icono fuente.
- `app/opengraph-image.tsx` (1200×630) con la plantilla de Claude Design, o la del cliente.
  Una página sin OG compartida en WhatsApp o LinkedIn se ve rota, y eso pesa más que casi
  cualquier otro detalle de esta lista.
- Lo que aún no llegó (icono del cliente, OG sin aprobar): placeholder generado con
  `ImageResponse` desde los tokens y el nombre del sitio — **marcado como provisional** — y
  su fila en `CONTENT_CHECKLIST.md`.

### Páginas de estado

404, 500 y mantenimiento no se indexan ni van al sitemap: la 404 ya sale con `noindex` y
estado 404; mantenimiento responde 503 con `Retry-After` (ver
`reference/STATUS-SCREENS.md`). La galería `/estados` de desarrollo, fuera del sitemap y
bloqueada en producción.

### Fuentes

`next/font` siempre — se autohospeda y elimina la petición a Google. `display: 'swap'`
obligatorio. Si la fuente es de un CDN externo que no se puede autohospedar, entonces
`<link rel="preconnect">` en el `<head>`.

---

## Bloque 2 — Cierre de sección con contenido

- [ ] Un solo `<h1>` en la página; la sección usa `<h2>`/`<h3>` sin saltar niveles.
- [ ] Los headings describen el contenido real, no son decorativos. Un `<h2>` que dice
      "Nosotros" vale menos que uno que dice "Diseño y desarrollo web para PyMEs".
- [ ] Imágenes con `next/image`, `width`/`height` o `fill` + `sizes` explícitos (evita CLS).
- [ ] La imagen principal del *above the fold* con `priority`; todo lo demás lazy por defecto.
- [ ] `alt` descriptivo en imágenes informativas. Coordina con `a11y`: es el mismo atributo,
      no lo escribas dos veces distinto.
- [ ] Enlaces internos con `next/link` y texto de ancla con significado. Nunca "click aquí".
- [ ] Enlaces externos: `rel="noopener noreferrer"`, y `rel="nofollow"` si es patrocinado.
- [ ] JSON-LD si la sección lo amerita: `FAQPage` en un FAQ, `BreadcrumbList` en breadcrumbs,
      `AggregateRating` solo si las reseñas son reales y visibles en la página.

---

## Bloque 3 — Cierre de página

### Metadata específica

```tsx
export const metadata: Metadata = {
  title: '{{≤60 caracteres, sin repetir el nombre de marca — lo pone el template}}',
  description: '{{150-160 caracteres, describe la página, incluye un verbo de acción}}',
  alternates: { canonical: '/ruta-de-esta-pagina' },
  openGraph: {
    title: '{{puede diferir del title — aquí optimizas para el click social}}',
    description: '{{...}}',
    url: '/ruta-de-esta-pagina',
    images: [{ url: '/og/esta-pagina.png', width: 1200, height: 630, alt: '{{...}}' }],
  },
}
```

Para rutas dinámicas, `generateMetadata()` con los datos reales de la entidad — y
`notFound()` si no existe, para que no se indexe una página vacía.

### JSON-LD por tipo de página

| Página | Schema |
|---|---|
| Home / corporativo | `Organization` + `WebSite` (con `SearchAction` si hay buscador) |
| Producto | `Product` + `Offer` (precio, moneda, disponibilidad) |
| Artículo / blog | `Article` o `BlogPosting` (autor, fechas, imagen) |
| Servicio | `Service` |
| Negocio local | `LocalBusiness` (dirección, horarios, teléfono, geo) |
| FAQ | `FAQPage` |
| Cualquiera con migas | `BreadcrumbList` |

```tsx
<script
  type="application/ld+json"
  dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
/>
```

Reglas duras del JSON-LD:
- Solo marca **lo que está visible en la página**. Marcar un precio o una reseña que el
  usuario no ve es una violación de las políticas de Google y puede costar una penalización
  manual — no un ranking peor, una penalización.
- Precios y disponibilidad salen de la fuente de datos real, nunca hardcodeados.
- Valida el resultado en el Rich Results Test antes de darlo por cerrado.

### Checklist de cierre

- [ ] `title` único en todo el sitio, ≤ 60 caracteres.
- [ ] `description` única, 150-160 caracteres.
- [ ] `canonical` correcta (y apuntando a sí misma salvo que sea una variante deliberada).
- [ ] OG image específica, o la default heredada a propósito.
- [ ] JSON-LD del tipo correcto, validado.
- [ ] Página agregada a `sitemap.ts`.
- [ ] Si es una página que **no** debe indexarse (gracias, cuenta, checkout):
      `robots: { index: false, follow: false }`. Es la que más se olvida.

---

## Core Web Vitals — solo el subconjunto que toca SEO

No haces optimización general de performance. Sí cuidas:

- **CLS** — dimensiones explícitas en toda imagen/iframe/embed; `font-display: swap`;
  reservar altura de banners y anuncios antes de que carguen.
- **LCP** — el elemento LCP (casi siempre la imagen del hero) con `priority`; sin lazy load
  above the fold; sin fuentes bloqueantes.
- **INP** — no lo persigues aquí, pero si ves un handler obviamente pesado en un botón
  visible, dilo.

Todo lo demás (bundle size, code splitting, caché) es de otro alcance.

### Verificación con Lighthouse

Al cerrar una página, corre Lighthouse sobre el build de producción (`bun run build && bun
run start`, no `dev`). El script está en la skill `a11y` (`scripts/lighthouse.ts`) —
imprime score por categoría y las auditorías que fallan con su descripción.

Para SEO mira estas y arréglalas: `document-title`, `meta-description`, `http-status-code`,
`link-text` (anclas tipo "click aquí"), `crawlable-anchors`, `is-crawlable` (que una página
pública no esté `noindex` sin querer), `canonical`, `structured-data` (valida el JSON-LD),
`hreflang` si hay i18n. Meta: **SEO = 100** en toda ruta pública. Una página `noindex` a
propósito (checkout, cuenta, panel) baja el score de SEO y eso es esperado — no lo cuentes.

De la categoría **Performance**, las que tocan SEO/CWV: `largest-contentful-paint-element`,
`prioritize-lcp-image` / `lcp-lazy-loaded` (la imagen del hero necesita `priority`),
`unsized-images`, `layout-shifts` (CLS), `render-blocking-resources` (fuentes/CSS). El
resto de Performance no es tu alcance.

---

## Nunca inventes copy

Títulos, descripciones, `alt`, texto de FAQ, precios, dirección, horarios y teléfono son
**contenido real del cliente**. Si no lo tienes:

1. Pon un placeholder explícito: `{{PENDIENTE: descripción de la página de precios}}`.
2. Agrega la fila en `context/CONTENT_CHECKLIST.md`.
3. Dilo en la salida.

Metadata inventada que parece final es peor que un placeholder visible: se publica, se
indexa, y nadie nota que Google está mostrando una frase que se inventó un agente.

---

## Salida

```
## SEO — <página/sección> (<init | sección | página>)

### Implementado
- <qué se agregó> (<archivo>)

### Hallazgos
- [<Crítico|Alto|Medio|Bajo>] <qué falta> — impacto: <qué se pierde>

### Contenido pendiente
- <qué copy real falta> → fila #<N> en CONTENT_CHECKLIST.md

### Verificación manual sugerida para César
- <ej. validar el JSON-LD en Rich Results Test, o subir la OG image real>
```

**Severidades:** *Crítico* = bloquea indexación o rompe el compartir (sin title/description,
sin OG image, robots bloqueando todo). *Alto* = impacto medible en CTR o rich results (sin
canonical, sin JSON-LD en producto/artículo). *Medio* = mejora recomendada. *Bajo* = menor.
