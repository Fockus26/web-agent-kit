# Plantilla — Brief para Claude Design

> **Para el orquestador:** llena cada `{{...}}` con datos reales del proyecto y entrégale a
> César el resultado dentro de un bloque de código, listo para copiar y pegar en Claude
> Design. Borra este recuadro y toda instrucción entre corchetes antes de entregarlo.
>
> Tres reglas al llenarlo:
> 1. **Autocontenido.** Claude Design no ve `context/` ni el repo. Cero referencias a
>    archivos externos.
> 2. **Cerrado donde importa, abierto donde aporta.** Paleta, tipografía, breakpoints,
>    secciones y su orden van cerrados. El tratamiento visual de cada sección va abierto.
> 3. **La sección 9 no se toca ni se resume.** Es lo que hace que vuelva un handoff
>    utilizable en vez de solo imágenes.

---

```markdown
# Brief de diseño — {{NOMBRE_DEL_PROYECTO}}

Eres un diseñador de producto senior. Vas a diseñar {{TIPO_DE_PROYECTO}} completo para el
proyecto descrito abajo, y además vas a entregar un documento de traspaso a desarrollo (la
sección 9 de este brief) que un desarrollador frontend usará para implementarlo sin volver a
consultarte.

## 1. El proyecto

**Qué es:** {{DESCRIPCIÓN_EN_2_LÍNEAS}}
**Tipo:** {{landing page | e-commerce | sitio corporativo | dashboard/app | blog | portafolio}}
**Público:** {{QUIÉN_ENTRA_Y_QUÉ_BUSCA}}
**Acción principal:** {{LA_ÚNICA_COSA_QUE_EL_VISITANTE_DEBE_HACER}}
**Idioma / mercado:** {{ej. español, Venezuela}}

## 2. Personalidad visual

**Dirección elegida:** {{ej. "Editorial sobrio"}}
**Debe transmitir:** {{3-4 adjetivos}}
**NO debe parecer:** {{2-3 cosas a evitar — esto guía tanto como lo anterior}}

**Referencias:**
- {{URL_O_MARCA}} — específicamente por {{qué exactamente: la tipografía, el ritmo vertical,
  el tratamiento de foto, la densidad}}
- {{REFERENCIA_2}} — por {{...}}

[Sé concreto en el "por qué" de cada referencia. "Me gusta Stripe" no dice nada; "me gusta
de Stripe la densidad de información sin sensación de saturación" sí.]

## 3. Restricciones de marca

**Logo:** {{disponible / en desarrollo / no hay}} — {{descripción o nota de uso}}
**Colores obligatorios:** {{hex exactos, o "ninguno — propón la paleta"}}
**Tipografía obligatoria:** {{nombre exacto, o "ninguna — propón"}}
**Icono / isotipo:** {{lo tiene el cliente (adjunto) | diséñalo derivado del logo (sección 7) | no aplica}}
**Favicon, apple touch icon e imagen Open Graph:** {{los tiene el cliente | diséñalos (sección 7)}}
**Otras:** {{ej. "el cliente odia el morado", "debe convivir con una app existente que usa X"}}

## 4. Sistema visual de partida

[Si el orquestador ya cerró paleta y tipografía, van aquí como cerradas. Si se decidió que
Claude Design proponga, escribe "PROPÓN" y da la dirección.]

### Paleta
| Rol | Light | Dark | Uso |
|---|---|---|---|
| primary | {{#______}} | {{#______}} | {{CTAs, enlaces activos}} |
| secondary | {{#______}} | {{#______}} | |
| background | {{#______}} | {{#______}} | |
| surface | {{#______}} | {{#______}} | {{cards, paneles}} |
| text primary | {{#______}} | {{#______}} | |
| text secondary | {{#______}} | {{#______}} | |
| success / warning / error | {{...}} | {{...}} | |
| border / divider | {{#______}} | {{#______}} | |
| selection (fondo / texto) | {{#______ / #______}} | {{#______ / #______}} | {{texto seleccionado; ratio anotado; distinto del foco y de los enlaces}} |

**Dark mode:** {{sí — obligatorio / no / opcional}}

### Tipografía
- **Titulares:** {{FUENTE}} — {{pesos disponibles}}
- **Cuerpo:** {{FUENTE}} — {{pesos}}
- **Mono (si aplica):** {{FUENTE}}
- **Escala:** {{ej. 1.250 (major third), base 16px}}

### Espaciado y forma
- Unidad base: {{8px}} — todo espaciado es múltiplo de esta unidad
- Radios: {{ej. 6px inputs / 10px cards / 16px modales}} · {{o "sin radios, todo recto"}}
- Sombras: {{ej. "sutiles, solo en elevación real — nada de sombras decorativas"}}

## 5. Restricciones no negociables

Estas aplican a **todo** lo que diseñes. Un diseño que las incumple no se puede implementar
y hay que rehacerlo.

- **Contraste WCAG 2.1 AA.** Texto normal ≥ 4.5:1, texto grande (≥24px o ≥19px bold) ≥ 3:1,
  bordes de inputs e íconos informativos ≥ 3:1. Verifica cada par que uses y anota el ratio.
- **Ningún estado se comunica solo con color.** Error, éxito, seleccionado, activo: siempre
  color + ícono, texto o forma.
- **Sin scroll horizontal a 320px de ancho.**
- **Estados de foco visibles y diseñados**, no el outline por defecto del navegador ni
  ausencia de él.
- **Se implementa con {{LIBRERÍA_DE_COMPONENTES}}**. [El orquestador pega aquí el párrafo
  que corresponda de `reference/UI-LIBRARIES.md` § "Qué le dice el brief a la herramienta de
  diseño" — cambia lo que es razonable diseñar, así que no lo omitas.]
- **Breakpoints objetivo:** 360 · 768 · 1024 · 1440 · 1920 {{· 2560 si aplica}}.

## 6. Páginas y secciones

[Una entrada por página, con sus secciones en el orden vertical exacto. Este orden no es
sugerencia: es la estructura que el frontend va a implementar.]

### {{PÁGINA_1 — ej. Home}}
| # | Sección | Propósito | Contenido disponible | CTA |
|---|---|---|---|---|
| 1 | {{Hero}} | {{qué debe lograr en 3 segundos}} | {{real / placeholder}} | {{cuál}} |
| 2 | {{...}} | | | |

### {{PÁGINA_2}}
{{...}}

## 7. Estados y casos que también hay que diseñar

[Lo que casi siempre se olvida y el frontend termina inventando. Marca lo que aplique.]

- [ ] Estados vacíos (lista sin resultados, carrito vacío, sin pedidos aún)
- [ ] Estados de carga (skeletons por sección, no un spinner global)
- [ ] **Pantallas de estado**, como una familia visual (cabecera mínima con el logo,
      etiqueta, título con la voz de la marca, una línea de qué pasó, acciones):
  - [ ] **404** — {{con sesión: "Ir al inicio" + "<destino principal del usuario>" ·
        invitado: "Ir al inicio" + "Entrar"}} {{— o, sin autenticación, una sola 404 con
        "Ir al inicio" + "<acción principal>"}}
  - [ ] **500 con código** (el código visible y copiable para escribir a soporte;
        "Reintentar" + "Ir al inicio") y **500 sin código**
  - [ ] **Sin conexión** (qué revisar, qué se conserva, "Reintentar")
  - [ ] **Mantenimiento con hora** ("Volvemos aproximadamente: <fecha y hora local>") y
        **sin hora**
- [ ] Error dentro de una pantalla (formulario rechazado, fallo de red al guardar): no a
      pantalla completa
- [ ] Formularios: reposo, foco, relleno, error con mensaje, éxito, deshabilitado, enviando
- [ ] Botones: reposo, hover, foco, activo, cargando, deshabilitado
- [ ] Navegación abierta en mobile
- [ ] Color de selección de texto, en claro {{y oscuro}}
- [ ] {{Icono derivado del logo: legible a 16 px, SVG para fondo claro y oscuro, apple touch
      icon 180×180 con fondo opaco, maskable — solo si el cliente no lo tiene}}
- [ ] {{Plantilla de imagen Open Graph 1200×630 — solo si el cliente no la tiene}}
- [ ] {{Autenticado vs. anónimo — solo si hay autenticación}}
- [ ] {{**Plantillas de correo** — solo si la app manda correos. Una familia con una
      plantilla base (cabecera con logo, título, texto, botón + el enlace en texto debajo,
      pie con por qué lo recibe y contacto), y estos correos: <lista cerrada, p. ej.
      "confirmar cuenta · recuperar contraseña · pedido recibido · acuse del formulario de
      contacto · aviso interno del formulario">. Cada uno con asunto y texto de vista previa
      (preheader). Restricciones del medio, no negociables: ancho máximo 600 px y una
      columna; tipografía que funcione con la pila de respaldo (`Arial, Helvetica,
      sans-serif`), porque Gmail y Outlook no cargan fuentes web; se entiende con las
      imágenes bloqueadas (nada de texto en imágenes); el logo se lee si el cliente invierte
      los colores a oscuro; botón de HTML ≥ 44 px de alto; contraste AA.}}
- [ ] Contenido extremo: título de 3 líneas, nombre de 40 caracteres, lista de 1 y de 50 ítems

## 8. Contenido

**Contenido real disponible:** {{qué textos/fotos existen ya}}
**Pendiente:** {{qué va con placeholder}}

Para lo pendiente, usa texto realista en {{español}} con la longitud que tendrá el contenido
final — **nunca lorem ipsum**. Un diseño validado con lorem se rompe al llegar el copy real,
y esa ruptura la paga el desarrollador.

---

## 9. Entregable — OBLIGATORIO

Entrega **dos cosas**. La segunda es tan importante como la primera.

### 9.1 El diseño

Todas las páginas de la sección 6 en {{desktop 1440 · mobile 390}}, con los estados de la
sección 7.

### 9.2 `HANDOFF.md` — documento de traspaso a desarrollo

Un documento en Markdown, autocontenido, escrito para un desarrollador frontend senior que
**no vio el diseño contigo y no te puede preguntar nada**. Todo lo que no esté aquí, lo va a
tener que inventar — y ahí es donde el diseño se desvía.

Estructura exacta:

**1. Tokens** — tabla completa de valores finales, con nombre de token, valor y uso:
colores (light y dark, con el ratio de contraste verificado de cada par usado), escala
tipográfica (tamaño / interlineado / peso / tracking por rol: display, h1-h6, body, small,
caption), espaciado, radios, sombras, duraciones y curvas de animación, z-index.

**2. Componentes** — uno por uno, y para cada uno:
   - Nombre, y si mapea a un componente de shadcn/ui, cuál
   - Anatomía (qué partes lo componen)
   - Variantes y tamaños
   - **Todos** los estados: reposo, hover, foco, activo, deshabilitado, cargando, error
   - Medidas concretas: padding, altura, gap, tamaño de ícono, grosor de borde
   - Comportamiento responsive
   - Notas de accesibilidad: rol, nombre accesible esperado, comportamiento de teclado

**3. Secciones** — una por una, en el orden de la sección 6, y para cada una:
   - Estructura del layout (grid o flex, columnas, gaps, ancho máximo)
   - Qué componentes usa
   - Espaciado vertical antes y después
   - **Cómo se reordena o colapsa en cada breakpoint** (esto explícito, no "es responsive")
   - Contenido: qué es texto real y qué es placeholder

**4. Grid y layout global** — ancho máximo del contenedor, número de columnas y gutters por
breakpoint, padding lateral por breakpoint, ritmo vertical entre secciones.

**5. Assets** — lista de todo lo que hay que exportar o conseguir: imágenes (con dimensiones
y formato), íconos (con el set del que salen), ilustraciones, logo en sus variantes, y los
assets de marca: icono fuente (SVG), favicon, apple touch icon 180×180, icono maskable y la
plantilla de imagen Open Graph 1200×630 (qué texto lleva y qué zona es segura al recortar).

**5b. Pantallas de estado** — por cada variante de la sección 7: layout, copy, acciones,
qué cambia entre variantes (con/sin sesión, con/sin código, con/sin hora) y cómo se ve en
mobile.

**5c. Correos** (si la sección 7 los pide) — la plantilla base (anchos, colores con su hex y
ratio, tamaños de texto, padding, el botón con sus medidas, la pila tipográfica de respaldo)
y, por cada correo: asunto, preheader, copy completo, qué datos variables lleva (nombre,
enlace, código, resumen del pedido), la acción y cómo se ve a 600 px, a 360 px, sin imágenes
y con colores invertidos.

**6. Movimiento** — qué anima, con qué duración y curva, y qué se apaga bajo
`prefers-reduced-motion`.

**7. Orden de implementación** — la secuencia recomendada para construirlo, de tokens a
componentes base a secciones a páginas, con las dependencias entre pasos señaladas.

**8. Decisiones y trampas** — las decisiones de diseño que tomaste y por qué (para que el
desarrollador no las "corrija" sin querer), más lo que es fácil implementar mal: qué debe
verse idéntico entre secciones, qué espaciado es intencional aunque parezca inconsistente,
qué no debe convertirse en un componente compartido aunque se parezca a otro.

**9. Preguntas abiertas** — lo que no pudiste decidir por falta de información, con tu
recomendación para cada una.

Formato de todo el handoff: valores concretos, nunca adjetivos. "24px" y no "un espacio
generoso". "#1E293B sobre #F8FAFC, ratio 14.8:1" y no "gris oscuro sobre gris claro".
```

---

## Verificación antes de entregarle el brief a César

- [ ] Cero `{{placeholders}}` sin llenar.
- [ ] Cero referencias a archivos que Claude Design no puede ver.
- [ ] Las secciones de cada página están en orden vertical real.
- [ ] La sección 9 está completa y sin resumir.
- [ ] Está dentro de un bloque de código, listo para copiar.
