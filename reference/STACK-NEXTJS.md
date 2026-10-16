# Stack por defecto del kit

El default de todo proyecto nuevo. El orquestador lo confirma o lo ajusta en la entrevista;
si se ajusta, queda escrito en `context/PROJECT_CONTEXT.md` y **ese archivo manda sobre este**.

---

## Base

| Pieza | Elección | Por qué |
|---|---|---|
| Framework | **Next.js** (App Router) | Server Components, metadata nativa, rutas de API en el mismo repo |
| Lenguaje | **TypeScript** estricto | — |
| Componentes | **se decide por proyecto** | shadcn/ui · Hero UI · MUI — ver `UI-LIBRARIES.md`. El orquestador lo pregunta siempre. |
| Estilos | **según la librería** | Tailwind con shadcn/ui y Hero UI; `sx`/`styled` con MUI (y ahí **no** se usa Tailwind) |
| Gestor / runner | **bun** | Nunca npm, yarn ni pnpm en el mismo proyecto |
| Linter / formato | **Biome** (`create-next-app --biome`) | Un solo binario para lint y formato; nada de ESLint + Prettier |
| Compilador | **React Compiler** (`--react-compiler`, `reactCompiler: true`) | Memoización automática; sin `useMemo`/`useCallback` a mano |
| Iconos | **lucide-react** | Un solo set, un solo grosor de trazo |
| Formularios | **react-hook-form** + **zod** | El mismo esquema valida cliente y servidor |
| Fechas | **date-fns** | — |
| Animación | **CSS/Tailwind** primero; **framer-motion** solo si hace falta de verdad |

### Cuándo desviarse

- **Astro** — sitio de contenido casi todo estático, sin interactividad más allá de un
  formulario. Menos JavaScript enviado.
- **Vite + React** — app detrás de login, sin necesidad de SEO ni SSR.
- **Next.js igual** — para todo lo demás. En la duda, Next.js.

---

## bun

```bash
bun install
bun add <paquete>
bun add -d <paquete-de-desarrollo>
bun remove <paquete>
bun dev
bun run build
bun run start
bunx shadcn@latest add button card dialog
bunx tsc --noEmit
bunx playwright install chromium
```

Reglas:

- **Un solo lockfile.** `bun.lockb` va al repo; si aparece un `package-lock.json` o un
  `pnpm-lock.yaml`, hay que borrarlo — dos lockfiles producen instalaciones distintas en
  máquinas distintas.
- Scripts de `package.json` se corren con `bun run <script>`.
- CLIs de un solo uso con `bunx`, sin instalar globalmente.
- Si una herramienta no funciona bajo bun (algún bundler o binario nativo ocasional), usa
  `npx` **solo para esa herramienta**, y déjalo anotado en el README del proyecto con la
  razón. No cambies el gestor del proyecto entero por una excepción.

---

## Context7 — documentación siempre al día

**Antes de usar la API de cualquier librería, consulta su documentación actual vía Context7.**

```
1. resolve-library-id  → obtener el id de la librería
2. get-library-docs    → traer la documentación de la parte que vas a usar
```

Aplica a: Next.js, React, Tailwind, shadcn/ui, Radix, react-hook-form, zod, Prisma o Drizzle,
el SDK de pagos, el proveedor de auth, TanStack Query, framer-motion, y cualquier dependencia
nueva.

Por qué es obligatorio y no una recomendación: estas librerías se mueven rápido. Next.js
cambió de Pages a App Router, Tailwind cambió de configuración en v4, los SDK de pagos
renombran métodos entre versiones mayores. Escribir contra una API que recuerdas de una
versión anterior produce código que **compila y falla en ejecución** — el peor tipo de error,
porque no lo atrapa ni el build ni el typecheck.

Cuesta segundos consultar. Cuesta una sesión depurar.

Si Context7 no tiene la librería o no está disponible, dilo explícitamente y marca esa parte
del código como escrita sin verificar contra documentación actual, para que se revise.

---

## Estructura de carpetas

```
app/
  (marketing)/              grupo de rutas públicas
    page.tsx
    precios/page.tsx
  (app)/                    grupo de rutas autenticadas
    dashboard/page.tsx
  api/
    webhooks/<proveedor>/route.ts
  layout.tsx
  globals.css
  sitemap.ts
  robots.ts
  opengraph-image.tsx
components/
  ui/                       primitivos (shadcn + propios)
  sections/                 secciones de página
  <dominio>/                agrupados por dominio cuando crecen
lib/
  utils.ts                  cn(), helpers
  validations/              esquemas zod
  db/                       cliente y consultas
hooks/
types/
context/                    documentación viva del proyecto (del kit)
design/                     BRIEF y HANDOFF de Claude Design
phases/                     las fases del track elegido
```

---

## Convenciones

### Server vs. Client

- Server Components por defecto.
- `'use client'` solo con estado, efectos, listeners o APIs de navegador.
- Colócalo **lo más abajo posible en el árbol**: en un layout arrastra todo el subárbol al
  bundle del cliente y desaparece el beneficio de los Server Components.
- Los datos se piden en el servidor; los Client Components los reciben por props.
- Un módulo `'use client'` solo exporta componentes: una constante importada desde él en un
  Server Component llega como referencia de cliente, no como valor (`undefined`, 500). Lo
  compartido va en `lib/`.

### Servidor de desarrollo (Turbopack)

- Con varios servidores a la vez (workers del pool), Turbopack puede agotar el tiempo de
  sus subprocesos ("Node.js subprocess crashed … deadline has elapsed") y dejar un 500 en
  la caché de `.next/dev`. Reiniciar no basta: apagar, borrar `.next/dev` y relanzar.

### TypeScript

- `strict: true`. Cero `any` — usa `unknown` y valida.
- Props tipadas explícitamente; nada de `React.FC`.
- Tipos compartidos en `types/`; los locales, junto al componente.

### Tailwind (si el proyecto lo usa)

- Todo token vive en `tailwind.config` (o en variables CSS con `@theme` en v4).
- Con MUI, esta sección no aplica: los tokens viven en `createTheme()`.

- Clases condicionales con `cn()` (`clsx` + `tailwind-merge`).
- Móvil primero: las clases base son mobile, los prefijos `md:`/`lg:` amplían.
- **Cero valores arbitrarios** (`w-[347px]`, `text-[#3a7bd5]`). Si hace falta uno, o falta un
  token o es una decisión que hay que registrar.

### Variables de entorno

- `.env.example` en el repo, con todas las variables y **sin valores reales**.
- `.env.local` en `.gitignore`.
- `NEXT_PUBLIC_` **solo** para lo que de verdad es público — ese prefijo mete el valor en el
  bundle del navegador.
- Valida las variables al arrancar, con zod. Un fallo por variable faltante debe ocurrir al
  iniciar, no en la petición del primer usuario.

### Imágenes

- `next/image` siempre.
- `width`/`height`, o `fill` + `sizes`. Sin esto hay CLS garantizado.
- La imagen del hero con `priority`; el resto lazy por defecto.
- Formatos modernos (AVIF/WebP) con fallback.

### Fuentes

- `next/font` — se autohospeda, elimina la petición externa y evita el flash.
- `display: 'swap'`.

---

## Dependencias: criterio antes de instalar

Antes de `bun add`, pregúntate:

1. ¿Lo resuelve la plataforma o algo que ya está instalado? (Muchos utilitarios de fechas y
   formato ya están en `Intl`.)
2. ¿Cuánto pesa en el bundle del cliente?
3. ¿Está mantenida? Último commit, issues abiertas.
4. ¿Tiene documentación en Context7? Si no, va a costar más mantenerla.

Una dependencia menos es una decisión que no hay que revisar dentro de un año.
