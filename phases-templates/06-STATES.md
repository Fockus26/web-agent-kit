# Fase 06 — Estados

## Objetivo

Lo que pasa cuando las cosas no salen como en el mockup. Es la fase que más se salta y la que
más se nota que falta.

## Alcance

- **Pantallas de estado** (guía completa: `reference/STATUS-SCREENS.md` del kit):
  - 404 — con sesión e invitado **solo si hay autenticación**; si no, una sola.
  - 500 con código (`error.digest`) y sin código.
  - Sin conexión, elegida en el mismo `error.tsx` **según la red** (`navigator.onLine`).
  - Mantenimiento con hora (en la zona del visitante) y sin hora, por variable de entorno,
    con 503 + `Retry-After`.
  - `global-error.tsx` con su propio html/body.
  - Galería `/estados?screen=…` en desarrollo (bloqueada en producción) para revisarlas y
    capturarlas.
- **Vacío:** lista sin resultados, búsqueda sin coincidencias, carrito vacío, sin datos aún.
  Cada uno con su explicación y su acción de salida.
- **Carga:** skeletons por sección (no un spinner global), con `loading.tsx` de Next.
- **Error dentro de una pantalla:** fallo de envío de formulario, fallo de red al guardar.
- **Formularios:** validación en vivo, error por campo, error general, envío en curso, éxito.
- Anuncio de cambios de estado a lectores de pantalla (`aria-live`, `role="alert"`).

Unidades típicas: `feat/pantallas-404`, `feat/pantallas-error-offline`,
`feat/mantenimiento`, y una por familia de vacíos/carga.

## Entradas

`design/HANDOFF.md` §5b y §7 (estados diseñados) · fases 01-05 cerradas

## Criterio de cierre

- [ ] Toda lista tiene estado vacío diseñado, no una pantalla en blanco.
- [ ] Toda carga tiene skeleton o indicador; nada salta de vacío a lleno.
- [ ] Todo error dice **qué pasó y qué hacer**, no solo un código.
- [ ] Los cambios de estado se anuncian de forma no visual.
- [ ] 404, 500, sin conexión y mantenimiento usan el diseño del sitio, no la página por
      defecto del framework, y responden con su estado HTTP (404 / 500 / 503).
- [ ] Criterio de cierre de `reference/STATUS-SCREENS.md` cumplido.
- [ ] Puerta `a11y` en verde.

## Nota

Si el handoff no diseñó estos estados, no los inventes en silencio: son decisiones visuales.
Pídelos a Claude Design con `prompts/CLAUDE-DESIGN-ADENDA.template.md` del kit; si César
prefiere no esperar, presenta 3 opciones para el patrón general y aplícalo consistentemente
una vez elegido.
