#!/usr/bin/env bash
# Old name of install-kit.sh (kit < 3.8.0). Kept because the kit-update skill installed from
# those versions calls it by this name. Forwards to install-kit.sh.
exec bash "$(cd "$(dirname "$0")" && pwd)/install-kit.sh" "$@"
