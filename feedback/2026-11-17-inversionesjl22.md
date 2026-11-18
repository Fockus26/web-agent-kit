# Informe de feedback — proyecto InversionesJL22 — kit 3.19.0 — 2026-11-17

Stack: WordPress 7.1.4 (adoptado) · PHP 8.3 · WooCommerce + tema hijo de Woodmart · hosting WordPress administrado con SSH · copia local en Docker · bun · Windows 10

Todas las filas tienen ×1; las piezas van ordenadas por cuántos puntos acumulan.

## reference/tech/wordpress-adopt.md (§1, §2, primer deploy, UI)
- [Hueco ×1] El repo tenía `plugins/` y `themes/` en la raíz (copia de wp-content sin la carpeta); compose, php-lint, pull-site y deploy suponen `wp-content/`, y se movió a mano con `git mv` → propuesta: que la guía §2 (o `new-project.ps1`) detecte `plugins/` + `themes/` en la raíz y proponga moverlos a `wp-content/`. `[Tech: wordpress]`
- [Hueco ×1] Hosting GoDaddy: César no sabía si había SSH o FTPS y la tabla de accesos de §1 no dice cómo averiguarlo por proveedor → propuesta: una línea por hosting común (GoDaddy cPanel / Managed WordPress, Hostinger, SiteGround) con dónde se activa SSH/SFTP. `[Tech: wordpress]`
- [Hueco ×1] Staging (un clon viejo del hosting) tenía un plugin de terceros en una versión muy anterior y sin las modificaciones vendorizadas, y datos de hace meses; producción tenía la versión nueva vendorizada. César vio el informe sin estilo, sin datos y la acción en lote rota, y lo tomó como fallo del código → propuesta: antes del primer deploy a staging, comparar versiones de plugins y archivos vendorizados staging vs producción (o refrescar staging desde producción), y que `deploy-ssh.yml` suba también los plugins vendorizados o avise de la diferencia. `[Tech: wordpress]`
- [Corrección ×1] Para el estilo de los formularios el agente sacó colores de las opciones del tema y propuso 3 opciones; César: "revisa lo del artifact". El canvas de diseño del proyecto ya tenía el sistema visual y las pantallas de admin → propuesta: que el `CLAUDE.md` del proyecto (o `DESIGN_RULES`) enlace el artifact de diseño, y que la regla "nueva decisión visual → 3 opciones" diga que primero se mira el diseño ya aprobado.

## scripts/pull-site.sh (ssh, import)
- [Hueco ×1] El hosting administrado exige llave **y** contraseña y corta las sesiones largas: el rsync de todo wp-content nunca terminaba la lista de archivos. Se resolvió con askpass, bajada por piezas con `chunks-done.txt` y reintentos → propuesta: llevar al kit la versión por piezas y el askpass. `[Tech: wordpress]`
  Evidencia: `scripts/pull-site.sh` en Fockus26/inversionesjl22
- [Hueco ×1] La verificación nunca llegaba a 0 diferencias: logs en vivo (`wc-logs`, `logs/`), caché (`litespeed`) y los mu-plugins del host siempre difieren → propuesta: excluirlos por defecto (`SKIP_PIECES`). `[Tech: wordpress]`
- [Hueco ×1] El drop-in `object-cache.php` (caché de objetos contra el Redis del host) tumbaba todo wp-cli en la copia; además el prefijo de tablas no era `wp_` → propuesta: desactivar el drop-in al importar (hecho en el proyecto) y leer `TABLE_PREFIX` del volcado. `[Tech: wordpress]`

## docker-compose.yml (WordPress)
- [Hueco ×1] En Windows la copia tardaba ~50 s por página: wp-content por bind mount y opcache limitado a 4.000 archivos. Se movió el código a un volumen (`local:sync`) y se subió opcache → propuesta: llevarlo al compose del kit; y como la imagen `wordpress:cli` antepone `wp`, usar `entrypoint: /usr/bin/env` para cuando un plugin corta wp-cli. `[Tech: wordpress]`
  Evidencia: `docker-compose.yml` en Fockus26/inversionesjl22
- [Hueco ×1] Un plugin de terceros vendorizado y modificado en el repo no se monta en la copia: solo el plugin del sitio y el tema hijo → propuesta: dejar comentada en el compose una línea para "otros plugins del repo". `[Tech: wordpress]`

## new-project.ps1 -Stack wordpress
- [Fricción ×1] `.env.example` ya existía (y el proyecto usaba `.env`, no `.env.local`): el script lo dejó tal cual y faltaban todas las claves del kit; se fusionaron a mano → propuesta: añadir al `.env.example` existente las claves del kit que falten, en vez de saltarlo.
- [Hueco ×1] El `CLAUDE.md` del kit nombra `bun run build:css` y el plugin trae `assets/scss/site.scss`, pero no hay script `build:css` ni `sass` en devDependencies → propuesta: añadir `build:css` (sass) al `package.json` de WordPress. `[Tech: wordpress]`

## git-flow (modo pr) / orchestrate
- [Hueco ×1] Una cadena de PRs encadenados se mergeó cada uno en su base: solo el primero llegó a main, las unidades 2–11 quedaron en ramas intermedias y hubo que abrir un PR de integración → propuesta: que git-flow, al abrir un PR encadenado, avise el orden de merge (del último al primero, o cambiar la base a main antes de mergear) y que al cerrar compruebe que lo mergeado llegó a main.
  Evidencia: Fockus26/inversionesjl22#5 … Fockus26/inversionesjl22#14, integración en Fockus26/inversionesjl22#15
- [Corrección ×1] César: "cuando termines una unidad no te quedes quieto, busca terminar todo lo que queda pendiente"; el agente paraba a preguntar tras cada PR → propuesta: en modo pr, tras abrir el PR seguir con la siguiente unidad del plan y juntar las preguntas para César al final.

## scripts/pr-screenshots.ts
- [Hueco ×1] `bun run shots` falla si el Chromium de Playwright no está instalado ("Executable doesn't exist"); los scripts de QA del proyecto usan el canal msedge y sí funcionan. Se tomaron con un script propio → propuesta: que `pr-screenshots.ts` acepte `PW_CHANNEL` (o pruebe msedge/chrome si falta Chromium).
  Evidencia: `.qa/shots-edge.js` en Fockus26/inversionesjl22

## Plantilla CLAUDE.md / DESIGN_RULES (correcciones visuales)
- [Repetición ×1] César pidió el botón primario con texto blanco y el agente volvió a hacerlo con texto oscuro en la pantalla siguiente: la preferencia no quedó en `decisions/` ni en `DESIGN_RULES` → propuesta: que una corrección visual de César a un componente compartido (botón, campo) se anote como decisión del proyecto en el mismo PR, no solo en el CSS de esa pantalla.
  Evidencia: Fockus26/inversionesjl22#31

## Lo que funcionó bien y no hay que tocar
- El log de `KIT_FEEDBACK.md` no registra aciertos, así que aquí no se afirma nada que no esté anotado. Sugerencia menor: una sección "Funcionó bien" en la plantilla para que este apartado tenga de dónde salir.
