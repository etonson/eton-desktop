#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=common.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
require_user
[[ ${1:-} == "" || ${1:-} == --dry-run ]] || { printf 'Usage: %s [--dry-run]\n' "$0" >&2; exit 2; }
resolve_target
active_backup
check_target_identity
[[ -f "$BACKUP_DIR/applied.sha256" ]] || { printf 'No applied snapshot to roll back.\n' >&2; exit 1; }
current="$(hash_file "$CONFIG_TARGET")"
applied="$(cat -- "$BACKUP_DIR/applied.sha256")"
original="$(cat -- "$BACKUP_DIR/original.sha256")"
if [[ "$current" != "$original" && "$current" != "$applied" ]]; then
  printf 'Conflict: WezTerm config changed after apply. Review changes before rollback.\n' >&2
  exit 1
fi
if [[ -f "$BACKUP_DIR/wallpaper.after.picture-uri" ]]; then
  "$PROJECT_DIR/scripts/wallpaper.sh" rollback --dry-run
fi
if [[ "$current" == "$original" ]]; then
  if [[ ${1:-} != --dry-run && -f "$BACKUP_DIR/wallpaper.after.picture-uri" ]]; then
    "$PROJECT_DIR/scripts/wallpaper.sh" rollback
  fi
  printf 'WezTerm already rolled back.\n'
  exit 0
fi
printf 'Will restore %s from %s\n' "$CONFIG_TARGET" "$BACKUP_DIR/wezterm.lua.before"
diff -u -- "$CONFIG_TARGET" "$BACKUP_DIR/wezterm.lua.before" || [[ $? -eq 1 ]]
if [[ ${1:-} == --dry-run ]]; then exit 0; fi
if [[ -f "$BACKUP_DIR/wallpaper.after.picture-uri" ]]; then
  "$PROJECT_DIR/scripts/wallpaper.sh" rollback
fi
cp -p -- "$BACKUP_DIR/wezterm.lua.before" "$CONFIG_TARGET"
[[ "$(hash_file "$CONFIG_TARGET")" == "$original" ]]
printf 'Restored original WezTerm config. GNOME settings were not modified.\n'
