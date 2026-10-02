# Fase 02 — Layout base

## Objetivo

El esqueleto sobre el que se monta todo lo demás: contenedor, grid, ritmo vertical, providers
y estilos globales.

## Alcance

- `app/layout.tsx`: html/body, idioma, fuentes, providers de tema.
- Contenedor y anchos máximos por breakpoint, según §4 del handoff.
- Grid global: columnas, gutters y padding lateral por breakpoint.
- Ritmo vertical entre secciones.
- Estilos globales mínimos: reset, `scroll-behavior`, `focus-visible` por defecto.
- **Selección de texto:** `::selection` con los tokens `selection` (fondo y texto) en claro
  y oscuro — nunca el azul del sistema sobre un sitio con identidad propia.
- **Assets de marca** del init de `seo`: favicon, `icon.svg`, `apple-icon.png`, manifest y
  OG por defecto, según lo que se decidió en el arranque (`reference/BRAND-ASSETS.md`).
- Header y footer estructurales (aunque su contenido llegue después).
- Skip link a `main`.
- Landmarks: `<header>`, `<nav>`, `<main>`, `<footer>`.

## Entradas

`design/HANDOFF.md` §4 · fase 01 cerrada

## Criterio de cierre

- [ ] El contenedor se comporta igual en todos los breakpoints del proyecto.
- [ ] Landmarks correctos y un solo `<main>`.
- [ ] Skip link funcional y visible al enfocarlo.
- [ ] Sin scroll horizontal a 320px en la página vacía.
- [ ] Texto seleccionado con el color del sistema y ratio ≥ 4.5:1, en claro y oscuro.
- [ ] Favicon visible en la pestaña; lo que falte del cliente, en `CONTENT_CHECKLIST.md`.
- [ ] Puerta `a11y` en verde.
- [ ] Skill `seo` ejecutada en modo *init*: metadata base, `robots.ts`, `sitemap.ts`,
      favicons, OG por defecto.

## Ambigüedad frecuente

Cómo se comporta el contenedor por encima de 1920px: ¿se ancla a un máximo, o sigue creciendo?
Si el handoff no lo dice, pregunta — es la causa más común de que un sitio se vea vacío en un
monitor grande.
