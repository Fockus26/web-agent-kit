# Plantilla — Adenda para Claude Design (piezas que faltan en un diseño ya hecho)

> **Para el agente:** úsala cuando el proyecto ya tiene diseño y handoff, pero faltan piezas
> (pantallas de estado, color de selección, icono, imagen OG, correos…) — típicamente después de
> actualizar el kit. Incluye **solo** los bloques de lo que falta, llena los `{{...}}` y
> entrégasela a César en un bloque de código, porque la pega a mano en el mismo proyecto de
> Claude Design (que ya conoce el sistema visual). Borra este recuadro.

---

```markdown
# Adenda de diseño — {{NOMBRE_DEL_PROYECTO}}

Sobre el diseño que ya hiciste para este proyecto, faltan estas piezas. Usa el mismo sistema
(tokens, tipografía, componentes) — nada de estilos nuevos salvo que lo justifiques en el
handoff. Mismas restricciones: WCAG 2.1 AA, ningún estado solo por color, sin scroll
horizontal a 320px, claro {{y oscuro}}.

## Pantallas de estado

Una familia visual: cabecera mínima con el logo, etiqueta, título con la voz de la marca,
una línea que explique qué pasó, y acciones. Desktop 1440 y mobile 390.

- **404**{{ · con sesión: acciones "Ir al inicio" + "{{DESTINO_PRINCIPAL_DEL_USUARIO}}" · invitado: "Ir al inicio" + "Entrar"}}{{ · sin auth: "Ir al inicio" + "{{ACCIÓN_PRINCIPAL}}"}}
- **500 con código**: "Reintentar" + "Ir al inicio", y el código de error visible y copiable
  para escribir a soporte. **500 sin código**: igual, sin el código.
- **Sin conexión**: qué revisar y qué se conserva; "Reintentar".
- **Mantenimiento con hora** ("Volvemos aproximadamente: <fecha y hora local>") y **sin hora**.
  Sin acciones.

Copy: {{real: ... | propón uno en {{IDIOMA}} con la voz de la marca, que se entienda sin el juego de palabras}}.

## Selección de texto

Color de fondo y de texto de `::selection` en claro y oscuro, con su ratio (≥ 4.5:1 del texto
seleccionado sobre el fondo de selección) y que se distinga del foco y de los enlaces.

## Barra de scroll

Colores del thumb y del track en claro y oscuro, del sistema de color del sitio (no el gris
del navegador sobre un fondo de marca). El thumb ≥ 3:1 contra el track, también al pasar
el ratón. Grosor: {{fino | normal}}. Vale para la página y para las zonas con scroll propio
(modales, listas, tablas).

## Icono y favicon

{{El cliente tiene logo pero no icono | no hay logo | el cliente tiene logo pero aún no lo
ha entregado: diseña uno provisional (monograma o nombre en la tipografía del sitio) que se
pueda cambiar por el real sin rehacer el icono ni la OG}}. Diseña un icono cuadrado derivado de
{{la marca / el logo adjunto}}, legible a 16 px, en SVG, con versión para fondo claro y oscuro,
y su variante para apple touch icon (180×180, fondo opaco) y maskable (símbolo dentro del
80 % central).

## Imagen Open Graph

Plantilla de 1200×630 para compartir: logo, título de la página (≥ 60 px), fondo del sistema,
margen de seguridad para recortes. Una por defecto del sitio {{y variante para <tipo de página>}}.

## Plantillas de correo

La app manda estos correos: {{lista, p. ej. "confirmar cuenta · recuperar contraseña ·
pedido recibido"}}. Una familia con una plantilla base: cabecera con el logo, título, uno o
dos párrafos, botón y debajo el enlace en texto, pie con por qué lo recibe y contacto. Cada
correo con asunto y texto de vista previa (preheader), copy {{real: ... | propuesto en
{{IDIOMA}} con la voz de la marca}}.

Restricciones del medio: ancho máximo 600 px, una columna; tipografía que funcione con
`Arial, Helvetica, sans-serif` (Gmail y Outlook no cargan fuentes web); se entiende con las
imágenes bloqueadas; el logo se lee si el cliente invierte a oscuro; botón de HTML ≥ 44 px
de alto; contraste AA. Muéstralos a 600 px y a 360 px.

## Entregable

Las piezas en el diseño y una **sección nueva del HANDOFF.md** con, para cada una: tokens que
usa (o nuevos, con valor y ratio), medidas, comportamiento responsive, estados, notas de
accesibilidad y, para icono y OG, los archivos exportados con sus tamaños.
```
