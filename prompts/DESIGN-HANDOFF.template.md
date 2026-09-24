# Handoff de diseño — estructura esperada y verificación

Este archivo tiene dos usos:

1. **El orquestador** lo usa para verificar el `HANDOFF.md` que vuelve de Claude Design,
   antes de dejar que se escriba una sola línea de código.
2. **`frontend-build`** lo usa como mapa: sabe dónde buscar cada dato mientras implementa.

El handoff real vive en `design/HANDOFF.md` dentro del proyecto.

---

## Verificación de completitud

Recorre esta lista contra el `HANDOFF.md` recibido. Cada ❌ es una pregunta que hay que
devolverle a Claude Design **ahora**, no en la fase 5.

### 1. Tokens
- [ ] Colores light **y** dark, todos los roles, con hex
- [ ] Ratio de contraste anotado en cada par texto/fondo que se usa
- [ ] Escala tipográfica con tamaño, interlineado, peso y tracking por rol
- [ ] Escala de espaciado
- [ ] Radios de borde
- [ ] Sombras con valor CSS real
- [ ] Duraciones y curvas de animación
- [ ] Escala de z-index

### 2. Componentes
Por cada componente:
- [ ] Nombre + mapeo a shadcn/ui (o "componente nuevo")
- [ ] Anatomía
- [ ] Variantes y tamaños
- [ ] Estados: reposo · hover · **foco** · activo · deshabilitado · cargando · error
- [ ] Medidas concretas (padding, altura, gap, ícono, borde)
- [ ] Comportamiento responsive
- [ ] Notas de accesibilidad (rol, nombre accesible, teclado)

> El estado de **foco** es el que más falta. Sin él, el frontend improvisa un anillo que no
> encaja con el sistema y `a11y` lo rebota después.

### 3. Secciones
Por cada sección, en el orden vertical de la página:
- [ ] Layout (grid/flex, columnas, gaps, ancho máximo)
- [ ] Componentes que usa
- [ ] Espaciado vertical antes y después
- [ ] **Comportamiento en cada breakpoint**, explícito
- [ ] Qué contenido es real y qué es placeholder

### 4. Grid global
- [ ] Ancho máximo del contenedor
- [ ] Columnas y gutters por breakpoint
- [ ] Padding lateral por breakpoint
- [ ] Ritmo vertical entre secciones

### 5. Assets
- [ ] Lista completa con dimensiones y formato
- [ ] Set de íconos identificado
- [ ] Variantes del logo

### 6. Movimiento
- [ ] Qué anima, duración y curva
- [ ] Qué se apaga bajo `prefers-reduced-motion`

### 7. Orden de implementación
- [ ] Secuencia de pasos con dependencias señaladas

### 8. Decisiones y trampas
- [ ] Decisiones con su razón
- [ ] Qué es fácil implementar mal

### 9. Preguntas abiertas
- [ ] Listadas, con recomendación de Claude Design para cada una

---

## Qué hacer cuando falta algo

| Situación | Acción |
|---|---|
| Falta un token o una medida concreta | Devolver la pregunta exacta a Claude Design. **No lo estimes del mockup** — un valor inventado se propaga a todo el sistema. |
| Falta un estado de un componente | Devolver la pregunta. Es barata de responder y cara de adivinar. |
| Falta el comportamiento en un breakpoint | Devolver la pregunta. Es el hallazgo #1 del QA de diseño. |
| Falta un asset | Registrar en `CONTENT_CHECKLIST.md` e implementar con placeholder marcado. **Esto sí no bloquea.** |
| Una decisión contradice `context/DESIGN_RULES.md` (ej. un par de colores que no llega a AA) | El handoff **no** manda sobre las reglas de accesibilidad. Escalar a César con la corrección propuesta. |
| Una decisión contradice `COLORS.md` o `TYPOGRAPHY.md` sin romper ninguna regla | El handoff manda. Actualizar `context/` y registrar la decisión con su razón. |

Regla general: **falta un dato de sistema → se pregunta; falta contenido → se pone
placeholder y se registra.** Confundir las dos es lo que produce reimplementaciones.

---

## Reconciliación con `context/`

Antes de arrancar el frontend, el orquestador sincroniza:

- `COLORS.md` ← tokens de color finales del handoff, con sus ratios
- `TYPOGRAPHY.md` ← escala tipográfica final
- `DESIGN_TOKENS.md` ← espaciado, radios, sombras, movimiento, z-index
- `COMPONENTS_INVENTORY.md` ← una fila por componente del handoff, estado `pendiente`
- `SECTION_INVENTORY.md` ← una fila por sección, estado `pendiente`
- `CONTENT_CHECKLIST.md` ← todo placeholder y asset faltante
- `decisions/` ← una fila por decisión relevante que el handoff traiga o cambie

A partir de aquí, `context/` y `HANDOFF.md` deben decir lo mismo. Si divergen, el frontend
va a seguir uno de los dos al azar según cuál leyó de último.
