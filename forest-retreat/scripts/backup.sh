#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
require_user
[[ ${1:-} == "" || ${1:-} == --dry-run ]] || { printf 'Usage: %s [--dry-run]\n' "$0" >&2; exit 2; }
resolve_target
printf 'Will record WezTerm config and GNOME values in %s\n' "$BACKUP_ROOT"
printf 'WezTerm target: %s\n' "$CONFIG_TARGET"
if [[ ${1:-} == --dry-run ]]; then exit 0; fi
if [[ -f "$ACTIVE_FILE" ]]; then
  active_backup
  check_target_identity
  printf 'Active backup already exists: %s\n' "$BACKUP_DIR"
  exit 0
fi
umask 077
mkdir -p -- "$BACKUP_ROOT"
BACKUP_DIR="$(mktemp -d "$BACKUP_ROOT/$(date +%Y%m%d-%H%M%S)-XXXXXX")"
cp -p -- "$CONFIG_TARGET" "$BACKUP_DIR/wezterm.lua.before"
printf '%s\n' "$CONFIG_TARGET" > "$BACKUP_DIR/target-path.txt"
hash_file "$CONFIG_TARGET" > "$BACKUP_DIR/original.sha256"
{
  for key in gtk-theme icon-theme color-scheme font-name monospace-font-name; do
    printf 'org.gnome.desktop.interface %s = ' "$key"
    gsettings get org.gnome.desktop.interface "$key"
  done
  for key in picture-uri picture-uri-dark; do
    printf 'org.gnome.desktop.background %s = ' "$key"
    gsettings get org.gnome.desktop.background "$key"
  done
} > "$BACKUP_DIR/gnome.before.txt"
printf '%s\n' "$BACKUP_DIR" > "$ACTIVE_FILE"
printf 'Backup created: %s\n' "$BACKUP_DIR"
