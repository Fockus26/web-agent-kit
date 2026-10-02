# Plantillas de correo — catálogo, diseño e implementación

Los correos que manda la app (confirmar cuenta, recuperar contraseña, pedido recibido…) son
parte de la marca igual que la 404. Si no se diseñan con el resto, el backend manda la
plantilla por defecto del proveedor ("Confirm your signup", en inglés, sin logo) o inventa
una en la fase 07 sin sistema. Se diseñan con el sitio (Claude Design, brief §7) y se
implementan en la fase 07.

**Solo si la app manda correos.** Una landing sin formulario no tiene ninguno; una landing
con formulario de contacto tiene dos (acuse al visitante y aviso al cliente). El arranque
decide cuáles aplican y quedan en `context/PROJECT_CONTEXT.md` § "Correos".

---

## El catálogo

| Correo | Cuándo aplica | Lo manda | Contenido mínimo | Acción |
|---|---|---|---|---|
| **Confirmar cuenta** | Registro con verificación de correo | Proveedor de auth | Qué pidió, para qué es el enlace, cuánto dura | "Confirmar mi correo" |
| **Enlace mágico / código** | Login sin contraseña u OTP | Proveedor de auth | El código grande y copiable, o el botón; cuánto dura | "Entrar" |
| **Recuperar contraseña** | Hay contraseña | Proveedor de auth | Que alguien lo pidió; si no fuiste tú, ignóralo (no cambia nada) | "Elegir contraseña nueva" |
| **Cambio de correo** | El usuario puede cambiar su correo | Proveedor de auth | Correo viejo → nuevo; qué hacer si no fue él | "Confirmar el cambio" |
| **Invitación** | Un admin invita usuarios | Proveedor de auth | Quién invita, a qué, cuánto dura | "Aceptar invitación" |
| **Reautenticación** | Acción sensible pide confirmar | Proveedor de auth | El código; para qué acción | — |
| **Bienvenida** | Solo si aporta algo (primeros pasos) | La app | Qué hacer primero | El destino principal del usuario |
| **Transaccionales del dominio** | Pedido, pago, reserva, envío, cancelación, factura | La app | Resumen (qué, cuánto, cuándo), número de referencia copiable | "Ver mi pedido" |
| **Formulario de contacto · acuse** | Hay formulario con envío real | La app | Que llegó, qué pasa ahora y cuándo, copia de lo enviado | — |
| **Formulario de contacto · aviso interno** | Igual; lo recibe el cliente | La app | Los datos del formulario, legibles, con "Responder" al remitente | — |
| **Notificaciones** | Alertas, recordatorios, resúmenes | La app | Qué pasó, enlace al detalle | "Ver …" · y cómo dejar de recibirlas |

Lo que **no** entra: newsletters y campañas de marketing. Se diseñan en la herramienta de
envío masivo (Mailchimp, Brevo…), con otras reglas legales; si el proyecto las tiene, es una
decisión aparte.

---

## La familia visual

Todos comparten **una plantilla base**, igual que las pantallas de estado:

1. **Cabecera**: logo (imagen con `alt` = nombre de la marca), sobre el fondo del sistema.
2. **Cuerpo**: título (un `<h1>`), uno o dos párrafos cortos, la acción.
3. **Botón** de la acción, y debajo **el enlace en texto** ("Si el botón no funciona, copia
   este enlace: …"): hay clientes que bloquean o rompen botones.
4. **Pie**: por qué recibe este correo, contacto o soporte, nombre legal y dirección si el
   cliente los tiene, y en notificaciones el enlace para dejar de recibirlas.

### Restricciones del medio (van al brief tal cual)

El correo no es la web: los clientes de correo (Gmail, Outlook, Apple Mail) renderizan un
HTML de hace 15 años. Un diseño que las ignora se ve bien en el mockup y roto en la bandeja.

- **Ancho máximo 600 px**, una columna. En móvil (320–390 px) la misma columna a ancho
  completo; nada de rejillas que dependan de media queries (Gmail en algunos casos las ignora).
- **Tipografía con respaldo de sistema.** Las fuentes web no cargan en Gmail ni en Outlook:
  el diseño tiene que funcionar con la pila de respaldo (`Arial, Helvetica, sans-serif` o
  `Georgia, serif`). La fuente de marca, si se usa, es mejora, no requisito.
- **Imágenes bloqueadas por defecto** en muchos clientes. El correo se entiende sin ninguna
  imagen: nada de texto dentro de imágenes, `alt` en todas, ninguna imagen de fondo con
  contenido.
- **Modo oscuro forzado.** Gmail y Outlook invierten colores sin preguntar. El logo tiene que
  leerse sobre claro y sobre oscuro (PNG con fondo transparente y trazo que funcione en
  ambos, o versión sobre fondo propio); evita blancos y negros puros en bordes de imágenes.
  Si el sitio tiene modo oscuro, se diseña la variante; si no, al menos se comprueba que la
  inversión no rompe el logo ni el botón.
- **Botón** de ≥ 44 px de alto, texto ≥ 16 px, hecho con HTML (no imagen), con contraste AA.
- **Contraste WCAG AA** y **nada solo por color**, como en el sitio.
- **Asunto y preheader** (el texto de vista previa en la bandeja) por cada correo: el asunto
  dice qué es ("Confirma tu correo en <marca>"), el preheader completa, no repite.
- **Versión de texto plano** de cada correo (la genera la implementación, pero el copy tiene
  que funcionar sin formato).

---

## Implementación (fase 07)

Consulta Context7 antes de escribirlas: el paquete de React Email cambió de nombre
(`@react-email/components` → `react-email`) y las claves de Supabase en `config.toml` se
mueven entre versiones de la CLI.

### Correos de la app — React Email

- Un componente por correo en `emails/` (`emails/order-confirmation.tsx`…), todos sobre un
  `emails/components/EmailLayout.tsx` con la cabecera, el pie y los tokens del sistema
  (colores, tamaños) traídos de `context/COLORS.md` como constantes — en el correo no hay
  variables CSS.
- Cada componente define `PreviewProps` con datos realistas y en el idioma del sitio: es lo
  que muestra el servidor de vista previa (`email dev`), que hace de **galería de correos**
  para César, `design-qa` y las capturas del PR.
- Se renderizan con `render(<Correo …/>)` (HTML) y `render(<Correo …/>, { plainText: true })`
  (texto), y se mandan **ambos** al proveedor decidido en el arranque (Resend, Postmark,
  SES…). Envío en el servidor, nunca desde el cliente; la clave del proveedor en variable de
  entorno.
- Los datos del usuario que entran al correo (nombre, mensaje del formulario) se escapan:
  React lo hace solo; no uses `dangerouslySetInnerHTML` con nada que venga de un formulario.

### Correos de auth — Supabase

Supabase manda los de la tabla con plantillas HTML propias, con variables de Go
(`{{ .ConfirmationURL }}`, `{{ .Token }}`, `{{ .TokenHash }}`, `{{ .SiteURL }}`,
`{{ .RedirectTo }}`, `{{ .Email }}`, `{{ .NewEmail }}`, `{{ .Data }}`).

- **En el repo**: un HTML por plantilla en `supabase/templates/` (`confirmation.html`,
  `recovery.html`, `magic_link.html`, `invite.html`, `email_change.html`,
  `reauthentication.html`, solo las que aplican) y en `supabase/config.toml`:

  ```toml
  [auth.email.template.confirmation]
  subject = "Confirma tu correo en <marca>"
  content_path = "./supabase/templates/confirmation.html"
  ```

  Así la base local (`bun run qa:local`) manda los correos con el diseño real a Mailpit, y la
  QA los ve como el usuario.
- **Una sola fuente de diseño**: los HTML de `supabase/templates/` se generan desde
  componentes de React Email que reciben las variables de Go como texto
  (`url="{{ .ConfirmationURL }}"`), con un script (`bun run emails:export`). Comprueba que
  la salida conserva la variable literal en el `href`. Si el script no compensa (dos o tres
  plantillas), se escriben a mano sobre el HTML exportado de `EmailLayout`; lo que no vale es
  un diseño distinto para auth.
- **En producción** las plantillas viven en el dashboard de Supabase (Authentication → Email
  Templates) o se aplican por la Management API: `config.toml` no se sube solo. Aplicarlas
  es **acción de César** con los HTML del repo (o del agente, si César autoriza el acceso),
  y cada cambio de plantilla repite la acción — anótalo en el PR.
- **SMTP propio en producción.** El correo por defecto de Supabase es limitado y solo para
  pruebas: con correos de auth reales, se configura el SMTP del proveedor (Authentication →
  SMTP) con el dominio verificado (SPF, DKIM, DMARC). Acción de César con pasos exactos.

Con otro proveedor de auth la idea es la misma: plantillas en el repo, diseño desde el mismo
`EmailLayout`, y aplicarlas en el proveedor como acción documentada.

### Remitente y dominio

- `From` con el nombre de la marca y una dirección del dominio del cliente
  (`"<Marca>" <hola@dominio>`), no `noreply@` de un proveedor. `Reply-To` a una dirección
  que alguien lee (en el aviso interno del formulario, el correo del remitente).
- El dominio verificado en el proveedor (SPF, DKIM y DMARC) **antes** del lanzamiento: sin
  eso los correos van a spam. Es acción de César (DNS); va en `CONTENT_CHECKLIST.md` o en
  las acciones del PR.

---

## Accesibilidad

- `<html lang>` del idioma del sitio, `<title>` = asunto.
- Un `<h1>`, párrafos reales, tablas de maquetación con `role="presentation"` (React Email
  lo pone solo en sus componentes).
- El enlace de la acción dice qué hace ("Confirmar mi correo"), nunca "clic aquí".
- Códigos (OTP, número de pedido) como texto seleccionable, no imagen.

## Criterio de cierre (fase 07)

- [ ] Existen los correos que `PROJECT_CONTEXT.md` § "Correos" marca, y comparten
      `EmailLayout`.
- [ ] Cada uno con asunto, preheader, versión de texto plano y `PreviewProps` realistas.
- [ ] Los de auth en `supabase/templates/` + `config.toml`, y se ven con el diseño en
      Mailpit al registrarse en la base local.
- [ ] Se ven bien en la vista previa a 600 y a 360 px, sin imágenes y con colores invertidos.
- [ ] Acciones de César en el PR: plantillas al dashboard, SMTP, dominio verificado.
- [ ] Copy real o en `CONTENT_CHECKLIST.md`.
