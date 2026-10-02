# Pantallas de estado — 404, error, sin conexión y mantenimiento

Las pantallas que se ven cuando algo no sale como en el mockup. Se diseñan con el resto del
sitio (Claude Design, brief §7) y se implementan en la fase 06. Una 404 por defecto de
Next.js en un sitio con identidad propia se nota tanto como un logo pixelado.

Referencia visual de cómo quedan bien resueltas (proyecto `melao`):
`https://melao-two.vercel.app/layouts/status?screen=<variante>` con `not-found`,
`not-found-guest`, `error`, `error-no-code`, `offline`, `live`, `maintenance` y
`maintenance-no-time`.

---

## El catálogo

| Variante | Cuándo se ve | Contenido | Acciones |
|---|---|---|---|
| **404 · con sesión** | Ruta inexistente, usuario autenticado | Etiqueta "Error 404", título con la voz de la marca, una línea de qué pasó | "Ir al inicio" + el destino principal del usuario (p. ej. "Ver mi curso", "Mi cuenta") |
| **404 · invitado** | Ruta inexistente, sin sesión | Igual | "Ir al inicio" + "Entrar" |
| **500 · con código** | Error del servidor con `error.digest` | Etiqueta "Error 500", título, "inténtalo de nuevo; si sigue pasando, escríbenos con este código" + el código visible y copiable | "Reintentar" + "Ir al inicio" |
| **500 · sin código** | Error sin `digest` (típicamente del cliente) | Igual, sin la frase del código ni el código | "Reintentar" + "Ir al inicio" |
| **Sin conexión** | El error ocurrió y `navigator.onLine === false` | "Sin conexión", qué revisar (wifi, datos), y qué se conserva si aplica ("al volver retomas desde la lección") | "Reintentar" (y reintento automático al volver el evento `online`) |
| **Error según la red** | No es una pantalla: es la **regla** que elige entre "Sin conexión" y "500" en el mismo `error.tsx` | — | — |
| **Mantenimiento · con hora** | Modo mantenimiento activo con hora de vuelta conocida | Título, qué está pasando, qué se conserva ("tu progreso queda guardado"), "Volvemos aproximadamente: <fecha y hora>" **en la zona horaria del visitante** | Ninguna (o un enlace a redes/estado si el cliente lo tiene) |
| **Mantenimiento · sin hora** | Modo mantenimiento sin hora conocida | Igual, sin la línea de la hora | Ninguna |

**Sesión vs. invitado solo existe si el sitio tiene autenticación de usuarios.** Sin auth hay
una sola 404, con "Ir al inicio" y, si tiene sentido, la acción principal del sitio
("Agendar cita", "Ver productos").

Reglas de contenido (valen para todas):

- **Qué pasó + qué hacer.** Nunca solo un código. El código del 500 es un dato para soporte,
  no la explicación.
- **Con la voz de la marca**, pero el título y la línea de explicación se entienden sin el
  juego de palabras ("Este paso no está en la coreografía" + "La página que buscas no existe
  o cambió de lugar").
- **El copy es contenido del cliente.** Si no lo dio, placeholder realista + fila en
  `CONTENT_CHECKLIST.md`, como cualquier texto.
- Misma estructura visual en todas (cabecera mínima con el logo, etiqueta, título, texto,
  acciones): se reconocen como una familia.

---

## Implementación (Next.js App Router)

Consulta Context7 antes de escribirlas: los props de `error.tsx` y el nombre de `proxy.ts`
cambiaron entre versiones.

### 404 — `app/not-found.tsx`

- Server Component. Lee la sesión en el servidor para elegir la variante (con sesión /
  invitado) — sin parpadeo de una a otra en el cliente.
- Next responde con estado **404** y añade `noindex` solo. No pongas `robots` a mano.
- Las rutas dinámicas llaman a `notFound()` cuando la entidad no existe: así reciben esta
  misma pantalla y no una página vacía indexable.
- Si hay grupos de rutas con layouts distintos, un `not-found.tsx` por grupo solo si el
  diseño lo pide; si no, uno en la raíz.

### Error — `app/error.tsx` y `app/global-error.tsx`

- Client Components (`'use client'`). Reciben `error` (con `digest?: string`) y la función
  para reintentar (`retry` en Next 16; `reset` en versiones anteriores — verifícalo).
- **"Con código"** = `error.digest` existe: es el identificador que Next pone a los errores
  del servidor y que aparece en los logs de Vercel junto al error real. Es lo que el usuario
  manda a soporte y lo que tú buscas en los logs. **Nunca** muestres `error.message`: en
  producción Next lo oculta en errores de servidor y en los del cliente puede filtrar
  detalles internos.
- **"Error según la red"** — en el mismo `error.tsx`:

  ```tsx
  const online = useSyncExternalStore(
    (cb) => {
      window.addEventListener('online', cb)
      window.addEventListener('offline', cb)
      return () => {
        window.removeEventListener('online', cb)
        window.removeEventListener('offline', cb)
      }
    },
    () => navigator.onLine,
    () => true, // en el servidor se asume conexión
  )
  // !online → <OfflineScreen onRetry={retry} />  ·  online → <ErrorScreen code={error.digest} onRetry={retry} />
  ```

  Al volver el evento `online`, reintenta solo (una vez) y anuncia el cambio.
- `global-error.tsx` cubre los errores del layout raíz: reemplaza el layout, así que trae su
  propio `<html lang>` y `<body>`, importa los estilos globales y las fuentes, y reutiliza el
  mismo componente de pantalla. Sin él, un error en el layout muestra la pantalla por defecto.
- Las pantallas son componentes (`components/status/StatusScreen.tsx` y sus variantes) que
  `not-found.tsx`, `error.tsx`, `global-error.tsx` y la página de mantenimiento comparten.

### Sin conexión fuera de un error

La variante "Sin conexión" también sirve:

- como **fallback del service worker** si el sitio es PWA (página precacheada `/offline`);
- como **aviso no bloqueante** (banner con `role="status"`) si el producto debe seguir usable
  sin red. Eso es decisión de diseño: se pregunta, no se asume.

### Mantenimiento

- Se activa con variables de entorno, no con un deploy de código:
  `MAINTENANCE_MODE=on` y, opcional, `MAINTENANCE_UNTIL=<ISO 8601 en UTC>`
  (`2026-10-01T23:30:00Z`). Ambas en `.env.example`.
- `proxy.ts` (Next 16; `middleware.ts` antes) reescribe todas las rutas — salvo
  `/_next`, assets, `robots.txt` y, si aplica, una ruta de salud — a `/mantenimiento`, con
  estado **503** y cabecera `Retry-After` (segundos hasta `MAINTENANCE_UNTIL`, o 3600 si no
  hay hora). Cómo fijar estado y cabeceras en la reescritura: Context7, y compruébalo con
  `curl -I` contra el build de producción. El 503 le dice a Google "vuelve luego" sin desindexar; un 200 con la página de
  mantenimiento sí puede indexarse.
- La hora se formatea **en el cliente**, con la zona del visitante:
  `new Intl.DateTimeFormat(locale, { dateStyle: 'long', timeStyle: 'short', timeZoneName: 'short' })`.
  Formatearla en el servidor muestra la hora de la región del servidor (UTC en Vercel).
  Sin `MAINTENANCE_UNTIL`, o si ya pasó, se muestra la variante sin hora.
- En Vercel, cambiar una variable de entorno exige un redeploy para que aplique. Si el
  cliente necesita activarlo al instante y sin redeploy, Edge Config — es una decisión, se
  pregunta.
- `/mantenimiento` con `robots: { index: false }` y fuera del sitemap.

### Galería de estados (para revisar y capturar)

Una ruta de desarrollo que renderiza cada variante sin tener que provocarla:
`app/(dev)/estados/page.tsx` con `?screen=not-found | not-found-guest | error |
error-no-code | offline | live | maintenance | maintenance-no-time`.

- En producción devuelve `notFound()` (`process.env.NODE_ENV === 'production'` o una
  variable propia) y no entra al sitemap.
- Es la ruta que usan `design-qa`, las capturas del PR (`.pr-shots.json`) y César para
  revisar. Sin ella, la 500 y el mantenimiento no se revisan nunca.

---

## Accesibilidad y SEO

- Un solo `<h1>` (el título), la etiqueta "Error 404" como texto, no como imagen.
- El foco va al `<h1>` al montar `error.tsx` (el usuario venía de otra pantalla).
- Cambio a "Sin conexión" o vuelta de la red: anunciado (`role="status"` / `aria-live`).
- El código del 500 es texto seleccionable, con botón de copiar con nombre accesible.
- Ilustraciones decorativas (los números de la 404 de melao) con `aria-hidden`.
- Estados HTTP correctos: 404, 500, 503 — no 200 con una pantalla de error.

## Criterio de cierre (fase 06)

- [ ] Las variantes que aplican existen y comparten un componente base.
- [ ] Sesión/invitado solo si hay auth; si no, una sola 404.
- [ ] `error.tsx` elige entre "Sin conexión" y "500" según la red, y entre con/sin código
      según `digest`.
- [ ] `global-error.tsx` con html/body, estilos y fuentes.
- [ ] Mantenimiento por variable de entorno, 503 + `Retry-After`, hora en la zona del
      visitante, variante sin hora.
- [ ] Galería `/estados` en desarrollo, bloqueada en producción.
- [ ] Copy real o en `CONTENT_CHECKLIST.md`.
- [ ] Puerta `a11y` en verde en todas las variantes, claro y oscuro.
