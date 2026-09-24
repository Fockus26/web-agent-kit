# Librería de componentes — perfiles

**No hay un default del kit.** La librería la elige César por proyecto, en la entrevista de
`project-kickoff`, y queda escrita en `context/PROJECT_CONTEXT.md`. Ese archivo manda: todos
los agentes leen de ahí, no de este documento.

Este archivo existe para dos cosas: dar el criterio de la elección, y decirle a
`frontend-build` cómo cambian las reglas según cuál se eligió.

---

## Las tres opciones

### shadcn/ui

**No es una librería instalada.** Es un CLI que **copia el código fuente** del componente
dentro de tu repo. Debajo usa Radix UI (los primitivos accesibles) y Tailwind (los estilos).

```bash
bunx shadcn@latest init
bunx shadcn@latest add button card dialog
# → aparece components/ui/button.tsx en TU repo, tuyo para editar
```

| A favor | En contra |
|---|---|
| Control total: es tu código, lo editas sin pelear con la API de nadie | Tú lo mantienes: no hay actualizaciones automáticas |
| Sin look impuesto — se ve como tus tokens digan | Empiezas con menos componentes listos |
| Accesibilidad resuelta por Radix (teclado, foco, ARIA) | Los componentes complejos (tabla de datos, date picker) hay que armarlos |
| Cero peso extra de librería | Requiere criterio de diseño para que no quede genérico |

**Cuándo:** proyectos donde el diseño es propio y específico, y quieres que el sistema de
diseño mande sobre el componente.

### Hero UI (antes NextUI)

Librería real, instalada como dependencia. Construida sobre React Aria (Adobe) para
accesibilidad, y sobre Tailwind para estilos, con su propio plugin de tema.

```bash
bun add @heroui/react framer-motion
```

| A favor | En contra |
|---|---|
| Arrancas rápido: muchos componentes pulidos desde el minuto uno | Tiene un look propio; despegarse de él cuesta |
| Accesibilidad de React Aria, muy sólida | Estás atado a su API y a su ritmo de versiones |
| Tema por tokens, encaja bien con Tailwind | Menos control sobre el interior del componente |
| Animaciones incluidas | Depende de framer-motion |

**Cuándo:** landings y sitios donde importa más la velocidad que la singularidad visual, y el
look moderno por defecto ya te sirve como punto de partida.

### MUI (Material UI)

Librería completa y madura, con **su propio motor de estilos** (Emotion) y su propio sistema
de tema.

```bash
bun add @mui/material @emotion/react @emotion/styled
```

| A favor | En contra |
|---|---|
| El catálogo más grande: DataGrid, date pickers, tablas complejas | **No se lleva bien con Tailwind** — son dos sistemas de estilos compitiendo |
| Sistema de tema muy potente | El look Material es fuerte; quitárselo es trabajo real |
| Documentación y comunidad enormes | Bundle más pesado |
| Accesibilidad cuidada | La API tiene su propia curva |

**Cuándo:** dashboards y aplicaciones internas con mucha tabla, filtro y formulario complejo,
donde el catálogo te ahorra semanas y el look Material no es un problema.

> **Regla dura si se elige MUI: se va Tailwind.** Mantener los dos es la receta para que la
> mitad de los estilos vivan en `sx` y la otra mitad en clases, y que nadie sepa cuál gana.
> Con MUI, el sistema de tokens es el `theme` de MUI y los estilos van en `sx` / `styled`.
> El orquestador debe dejar esto escrito en `PROJECT_CONTEXT.md` y en `DESIGN_RULES.md`.

---

## Cómo elegir

| Si el proyecto… | Elige |
|---|---|
| Tiene un diseño propio y específico que hay que respetar al detalle | **shadcn/ui** |
| Es una landing o sitio corporativo, y hay que entregar rápido | **Hero UI** |
| Es un dashboard con tablas, filtros y formularios complejos | **MUI** |
| Ya tiene código con una de las tres | **Esa.** Migrar a mitad de proyecto no se paga |
| El cliente tiene un design system propio en Figma | **shadcn/ui** — es la única que te deja replicarlo sin pelear |

---

## Qué cambia para `frontend-build` según la elegida

| | shadcn/ui | Hero UI | MUI |
|---|---|---|---|
| **Estilos** | Tailwind | Tailwind | `sx` / `styled` — **sin Tailwind** |
| **Tokens viven en** | `tailwind.config` / `@theme` | plugin de tema de Hero UI + Tailwind | `createTheme()` de MUI |
| **Instalar un componente** | `bunx shadcn@latest add <x>` | ya viene en el paquete | ya viene en el paquete |
| **Personalizar** | editas el archivo, es tuyo | `classNames` y variantes del tema | `sx`, `styled()`, `components` del tema |
| **Antes de crear uno propio** | mira si shadcn lo tiene | mira el catálogo de Hero UI | mira el catálogo de MUI |
| **Modo oscuro** | clase `dark` de Tailwind | `ThemeProvider` de Hero UI | `colorSchemes` de MUI |
| **Accesibilidad base** | Radix | React Aria | propia de MUI |

**Común a las tres:**

- **Nunca reimplementes a mano un primitivo que la librería ya trae** (dialog, select, tabs,
  popover, combobox). El comportamiento de teclado y foco de esos widgets es donde se cuelan
  la mayoría de los bugs de accesibilidad, y las tres ya lo tienen resuelto.
- **Cero valores mágicos.** Todo sale del sistema de tokens de la librería elegida.
- **Consulta Context7** antes de usar la API de la librería: las tres cambian entre versiones
  mayores.

---

## Qué le dice el brief a la herramienta de diseño

El brief que produce `project-kickoff` tiene que nombrar la librería, porque cambia lo que es
razonable diseñar:

- **shadcn/ui** → "se implementa con Tailwind + shadcn/ui (Radix). Usa la escala de espaciado
  de Tailwind. Puedes proponer tratamientos visuales propios: el componente se escribe a
  medida."
- **Hero UI** → "se implementa con Hero UI. Prefiere composiciones de su catálogo (Button,
  Card, Modal, Input, Dropdown, Tabs, Accordion, Table). Diseña dentro de lo que su sistema
  de tema permite: radios, colores y tamaños son tokens, no valores libres por componente."
- **MUI** → "se implementa con MUI. Prefiere componentes de su catálogo. El diseño puede
  alejarse del look Material, pero debe expresarse como un tema de MUI (paleta, tipografía,
  forma, sombras), no como estilos sueltos por pantalla."
