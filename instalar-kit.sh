#!/usr/bin/env bash
# Instala (o reinstala) las skills y los agentes del kit en ~/.claude/.
# Igual que instalar-kit.ps1: cada skill se reemplaza entera (sin archivos viejos colgados),
# los agentes se sobrescriben, y no se toca nada que no sea del kit.
#
#   bash instalar-kit.sh          # desde la carpeta del kit, o con su ruta
#   bash instalar-kit.sh --pull   # git pull antes
#
# Al final escribe ~/.claude/web-agent-kit.json (ruta del clon y versión instalada) para la
# skill kit-update.
#
# Después: sesión nueva de Claude Code (skills y agentes se cargan al arrancar).
set -euo pipefail

kit="$(cd "$(dirname "$0")" && pwd)"
destino="$HOME/.claude"

if [[ "${1:-}" == "--pull" ]]; then
  echo "… git pull en $kit"
  git -C "$kit" pull --ff-only
fi

version="$(tr -d '[:space:]' < "$kit/VERSION")"
echo "Kit $version → $destino"
mkdir -p "$destino/skills" "$destino/agents"

for skill in "$kit"/.claude/skills/*/; do
  nombre="$(basename "$skill")"
  rm -rf "${destino:?}/skills/$nombre"
  cp -r "$skill" "$destino/skills/$nombre"
  echo "  + skill  $nombre"
done

for agente in "$kit"/.claude/agents/*.md; do
  cp "$agente" "$destino/agents/"
  echo "  + agente $(basename "$agente" .md)"
done

# Para kit-update: dónde está el clon y qué versión de las skills quedó instalada.
printf '{\n  "ruta": "%s",\n  "version": "%s",\n  "instalado": "%s"\n}\n' \
  "$kit" "$version" "$(date +%F)" > "$destino/web-agent-kit.json"
echo "  + web-agent-kit.json (ruta y versión, para kit-update)"

echo
echo "Listo. Abre una sesión nueva de Claude Code y comprueba con /skills y /agents."
