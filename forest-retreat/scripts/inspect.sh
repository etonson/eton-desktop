#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
[[ ${1:-} == "" || ${1:-} == --dry-run ]] || { printf 'Usage: %s [--dry-run]\n' "$0" >&2; exit 2; }
printf 'OS: '
# shellcheck source=/etc/os-release
. /etc/os-release
printf '%s\n' "$PRETTY_NAME"
gnome-shell --version
printf 'Session: %s / %s\n' "${XDG_SESSION_TYPE:-unknown}" "${XDG_CURRENT_DESKTOP:-unknown}"
printf 'WezTerm: '; wezterm --version
resolve_target
printf 'WezTerm config: %s -> %s\n' "$CONFIG_LINK" "$CONFIG_TARGET"
printf 'WezTerm SHA256: %s\n' "$(hash_file "$CONFIG_TARGET")"
for key in gtk-theme icon-theme color-scheme font-name monospace-font-name; do
  printf '%s: ' "$key"
  gsettings get org.gnome.desktop.interface "$key"
done
for key in picture-uri picture-uri-dark; do
  printf '%s: ' "$key"
  gsettings get org.gnome.desktop.background "$key"
done
printf 'Enabled extensions: '
gsettings get org.gnome.shell enabled-extensions
