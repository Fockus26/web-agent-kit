# Informe de feedback — proyecto InspecChile — kit 3.15.0 — 2026-11-07

Stack: WordPress + ACF Pro + Elementor Pro (plugin propio `inspechile-site`) · MariaDB del hosting, sin auth propia · bun · Windows 10 · hosting cPanel compartido sin SSH (deploy por FTPS)

Primer proyecto WordPress sobre el kit (adoptado en 3.15.0). Casi todo el feedback es el mismo patrón: el kit es Next.js-first y para WordPress el agente tuvo que traducir o inventar.

## STACK-WORDPRESS.md

- [Corrección ×1] César fijó el flujo para todo proyecto WordPress: traer el sitio, ver si hay SSH, pasar todos los plugins de snippets a un plugin propio y subir ese plugin. §1 aún deja WPCodeBox para cosas puntuales → propuesta: que sea el flujo oficial y retirar los plugins de snippets, sin excepción "puntual".
- [Corrección ×1] §5 cae a WP Pusher sin SSH; César eligió SSH primero y luego FTPS porque se automatiza → propuesta: documentar SSH → FTPS (nunca FTP plano) y una plantilla de deploy para ambos.
- [Corrección ×1] InspecChile (cPanel, snippets existentes) es un caso; otros proyectos usan otros hosts y parten de cero, sin snippets → propuesta: dividir el flujo en una base común (acceso, plugin, acf-json, copia local, deploy) con dos entradas, "migrar snippets" y "desde cero", y una sección de acceso por tipo de host.
- [Hueco ×1] Sin guía sobre matriz de versiones de PHP, commitear el CSS compilado desde SCSS, ni fijar ACF/Elementor en `.wp-env.json` → propuesta: agregar esas tres notas.
- [Hueco ×1] No dice cómo inventariar todo lo que es código y vive en la base: grupos ACF/CPTs (acf-json), otros plugins de snippets, plugins premium que wp-env no instala; César encontró los huecos solo → propuesta: checklist de adopción: inventariar la base, acf-json en el plugin y copia local cuando el sitio necesita plugins Pro.
- [Hueco ×1] César quiere traer un sitio con un script; §3 lista pasos manuales y asume SSH o plugin de migración, y aquí una transferencia de respaldo quedó parcial → propuesta: script `pull-site` por tipo de acceso (SSH, API de cPanel/FTPS, archivo del plugin de migración), con los pasos como alternativa, reanudable y verificando la descarga.
- [Hueco ×1] wp-env no puede correr un sitio que necesita plugins premium y datos reales; el entorno útil fue una copia Docker del respaldo, armada a mano → propuesta: que la "copia Docker desde el respaldo" sea plantilla del kit (compose + script de armado; con Mailpit y phpMyAdmin opcional), y wp-env solo para sitios sin premium.
- [Hueco ×1] No hay registro por proyecto del tipo de acceso, `.env.example` ni `acf-json`, que César quiere en git → propuesta: agregarlos al checklist de adopción WordPress y a la plantilla de context.
- [Hueco ×1] Un PR de migración decía "no verificado" hasta que César preguntó; la prueba de punta a punta en la copia encontró un formulario de contacto roto → propuesta: exigir un recorrido completo de cada flujo en la copia local, con los snippets apagados, antes del primer deploy, y listar los flujos a probar.
- [Hueco ×1] Elementor clona los popups llevándose marcas `data-*` sin listeners, y su handler de envío ignora el `preventDefault` que burbujea → propuesta: nota "trampas de WordPress/Elementor" con ambas y el patrón `add_error` para acciones de formulario.
- [Hueco ×1] Los assets usan la versión fija del plugin como clave de caché, así que los navegadores que vuelven siguen con el JS viejo tras un deploy → propuesta: que la plantilla del plugin use `filemtime()` como versión de assets.
- [Hueco ×1] César pidió selects personalizados y más pulido tras QA; sin design system y con los popups clonados de Elementor hubo que resolverlo de cero → propuesta: un patrón reutilizable de select personalizado para page builders (select nativo oculto como fuente de verdad) y una plantilla de checklist de primer deploy.
- [Hueco ×1] La regla "los cambios de contenido son scripts WP-CLI en `bin/`" no corre en un host sin SSH; un arreglo de datos tuvo que ir en la activación del plugin → propuesta: documentar un camino sin SSH: migración única en la activación, con opción de guarda y registro de valores previos.
- [Hueco ×1] En un cPanel compartido sin soporte, cambiar la versión de PHP quitó la extensión `zip` (MultiPHP no la deja activar) y `uploads` quedó con dueño root; ambos daban un "error crítico" pelado → propuesta: sección de hosting compartido: no depender de `ZipArchive` (WP trae PclZip), revisar `wp_upload_dir()['error']` y permisos de escritura, y el truco de renombrar y copiar para carpetas de root.
  Evidencia: Fockus26/inspechile#11, Fockus26/inspechile#12
- [Hueco ×1] Una exportación completa de phpMyAdmin desde cPanel trajo 4 bases (2 Moodle, 2 WordPress antiguos con plugins de nombre aleatorio); el kit no tiene paso para elegir la base viva, cargarla en la copia local y reescribir URLs → propuesta: agregar al checklist de `pull-site`: separar un volcado multibase, identificar la base viva (plugin propio en `active_plugins`, prefijo), respaldar la copia, importar, `search-replace` (incluidas URLs escapadas) y avisar de instalaciones viejas en el host.

## kit-update skill
- [Hueco ×1] `/kit-update` en un proyecto WordPress sin archivos del kit no encontró nada; no hay camino para adoptar el kit sin Next.js → propuesta: camino "adoptar en WordPress": `new-project.ps1 -WordPress` o un checklist manual documentado.

## new-project.ps1
- [Hueco ×1] `-OnlyPieces` asume Next/bun: instala `@types/bun`, `@changesets/cli`, `test:related` (necesita grafo de imports TS) y `qa:local` (Supabase/Firebase) → propuesta: perfil `-Stack wordpress` que copie solo context-backup, cloud-setup, pr-screenshots y settings.json, y omita el resto.

## github-templates/ci.yml
- [Hueco ×1] La plantilla de CI es typecheck/lint/build con bun; nada para PHP → propuesta: plantilla de CI WordPress: matriz de `php -l`, chequeo del build de sass, wp-env + Playwright opcional.

## CLAUDE.md.template y plantilla de PR
- [Hueco ×1] La plantilla trae líneas de Next/Vercel/Changesets/handoff de diseño; el checklist del PR cita typecheck, tokens y changesets → propuesta: variantes WordPress de ambas (checklist de nonce/capability/escape en vez de tokens).

## Skills frontend-build, backend-build, seo
- [Hueco ×1] Las skills asumen Next.js; para WP el agente debe traducir leyendo STACK-WORDPRESS.md §4 → propuesta: una sección `wordpress` en cada skill, o una skill `wp-build` (hooks, nonces, ACF, wp-env, scripts WP-CLI en `bin/`). `[Tech: wordpress]`

## git-flow / kit-update
- [Fricción ×1] El trabajo de migración estaba sin commitear en la rama, así que un worktree limpio desde HEAD no tenía el plugin; la adopción del kit tuvo que hacerse en el árbol sucio → propuesta: que git-flow diga qué hacer cuando el repo tiene mucho trabajo sin commitear: commitearlo primero o trabajar en el lugar.

## a11y skill
- [Hueco ×1] Los popups de Elementor declaran `aria-modal` sin rol y no devuelven el foco; sus formularios no tienen `autocomplete`. axe marcó solo una parte y la skill no cubre page builders → propuesta: sección de page builders: qué se arregla desde el plugin y qué es del builder o del contenido.

## Agentes de QA
- [Hueco ×1] Sin control de escritorio, Office real funcionó por automatización COM (abrir, recalcular, exportar imagen) → propuesta: documentar Office COM como opción en Windows para revisar `.xlsx` y `.pptx` generados.

## Lo que funcionó bien y no hay que tocar
- git-flow en modo `pr` (rama → push → PR que César revisa) encajó sin cambios en WordPress.
- `context:backup` y `CURRENT_PHASE.md` como tablero corto mantuvieron el estado entre sesiones.
- `pr-screenshots` sirvió tal cual contra wp-env y la copia local.
