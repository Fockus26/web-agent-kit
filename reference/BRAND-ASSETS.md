# Assets de marca — favicon, touch icon, Open Graph e icono

Lo que se ve fuera del sitio: la pestaña del navegador, el icono al guardar en la pantalla
de inicio, la tarjeta al compartir en WhatsApp o LinkedIn. Se decide en el arranque
(`project-kickoff`, Bloque C) y se implementa en el init de `seo` (fase 02).

---

## Primero se pregunta: ¿qué tiene ya el cliente?

Nunca se asume. En la entrevista, una pregunta por pieza, con estas respuestas posibles:
**lo tiene (y lo manda)** · **hay que crearlo** · **no aplica**.

| Pieza | Para qué | Si el cliente la tiene, pídele | Si hay que crearla |
|---|---|---|---|
| **Logo** | Cabecera, pie, OG | SVG (vector), versión clara y oscura, y la versión horizontal / apilada si existen | Fuera del alcance del kit salvo que César lo acuerde: es trabajo de marca. Si se acuerda, se pide a Claude Design como pieza aparte |
| **Icono / isotipo** | Base de favicon, touch icon y manifest | SVG cuadrado, legible a 16 px. Si solo hay logo horizontal, **falta el icono** | Claude Design lo deriva del logo (inicial, monograma o símbolo) — brief §3 |
| **Favicon** | Pestaña | `.ico` o SVG si ya existe | Se genera desde el icono |
| **Apple touch icon** | Pantalla de inicio en iOS | PNG 180×180 | Se genera desde el icono |
| **Imagen Open Graph** | Tarjeta al compartir | PNG/JPG 1200×630 | Plantilla diseñada por Claude Design (brief §7) e implementada con `ImageResponse` |
| **Color de tema** | Barra del navegador móvil, manifest | Hex | Sale de la paleta |

Lo que falte va a `CONTENT_CHECKLIST.md` con su fila. Lo que hay que crear, va al brief.

> El caso que más se escapa: el cliente tiene logo pero **no icono**. Un logo horizontal
> reducido a 16 px es una mancha. Pregunta explícitamente por el icono.

### El cliente tiene logo pero todavía no lo ha entregado

No se espera ni se inventa una marca. Se monta un **logo provisional** que se cambia por el
real sin rehacer nada (pasó en un proyecto: el logo llegó con el sitio ya en marcha):

- Un solo archivo fuente provisional (`public/brand/logo.svg`, `icon.svg`): un monograma o
  el nombre en la tipografía del sitio, con los colores de los tokens. Marcado como
  provisional en el código y con su fila en `CONTENT_CHECKLIST.md`.
- Todo lo demás **se deriva** de ese archivo, como con el real: favicon, touch icon,
  manifest y la OG (`ImageResponse` lee el SVG). Nada copia el provisional a mano.
- Cuando llega el real: se sustituye el archivo fuente, se regeneran los derivados y la
  fila del checklist se cierra. Si el real no encaja en el hueco (proporción, versión
  oscura), es una decisión nueva, no un retoque en cada sitio.

---

## Qué se implementa (Next.js App Router, convenciones de archivo)

| Archivo en `app/` | Tamaño | Notas |
|---|---|---|
| `favicon.ico` | 16, 32 y 48 px dentro del `.ico` | Solo en la raíz de `app/`. Para navegadores viejos y lectores de feeds |
| `icon.svg` | vector | El favicon moderno. Puede adaptarse al tema con `@media (prefers-color-scheme: dark)` dentro del SVG |
| `icon.png` | 512×512 | Respaldo raster |
| `apple-icon.png` | 180×180 | **Fondo opaco** (iOS pinta de negro la transparencia) y ~10 % de margen |
| `manifest.ts` | — | `name`, `short_name`, `theme_color`, `background_color`, iconos 192 y 512, y uno `purpose: 'maskable'` con el símbolo dentro del 80 % central |
| `opengraph-image.tsx` (o `.png`) | 1200×630 | Por defecto del sitio; las páginas importantes pueden tener la suya. `alt` con `opengraph-image.alt.txt` o `export const alt` |
| `twitter-image` | 1200×630 | Solo si difiere de la OG; si no, la OG basta |

Reglas:

- **Un icono fuente, el resto se deriva.** Del SVG del icono salen el `.ico`, los PNG y el
  maskable. Si cambia la marca, se regenera todo desde ahí.
- La OG lleva texto legible en miniatura (título ≥ 60 px en el lienzo de 1200), el logo, y
  respeta un margen de seguridad: WhatsApp y LinkedIn recortan distinto.
- La OG generada con `ImageResponse` usa las fuentes del sitio (cárgalas como
  `ArrayBuffer`) y los colores de los tokens, no hex sueltos.
- Sin `metadataBase` (ver skill `seo`) las URLs de OG salen relativas y la tarjeta no carga.

## Verificación

- [ ] Pestaña con el favicon en claro y en oscuro.
- [ ] `apple-icon.png` sin transparencia; "Añadir a pantalla de inicio" en iOS se ve bien
      (o dilo en "no verificado" del PR si no hay dispositivo).
- [ ] Manifest válido (Lighthouse › PWA/installability si aplica).
- [ ] Tarjeta OG comprobada con el depurador de compartir de la plataforma (Facebook
      Sharing Debugger, LinkedIn Post Inspector) **sobre la URL desplegada**, no localhost.
- [ ] Lo provisional (icono derivado sin aprobar, OG sin copy final) con su fila en
      `CONTENT_CHECKLIST.md`.
