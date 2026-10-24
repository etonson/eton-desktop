#!/usr/bin/env bash
set -euo pipefail

CONFIG_LINK="${XDG_CONFIG_HOME:-$HOME/.config}/wezterm/wezterm.lua"
BACKUP_ROOT="${XDG_DATA_HOME:-$HOME/.local/share}/forest-retreat/backups"
ACTIVE_FILE="$BACKUP_ROOT/active"

require_user() {
  if [[ $EUID -eq 0 ]]; then
    printf 'Run as your desktop user, without sudo.\n' >&2
    exit 1
  fi
}

resolve_target() {
  [[ -f "$CONFIG_LINK" ]] || { printf 'Missing WezTerm config: %s\n' "$CONFIG_LINK" >&2; exit 1; }
  CONFIG_TARGET="$(readlink -f -- "$CONFIG_LINK")"
  [[ -n "$CONFIG_TARGET" && -f "$CONFIG_TARGET" ]] || exit 1
}

active_backup() {
  [[ -f "$ACTIVE_FILE" ]] || { printf 'No active backup; run backup.sh first.\n' >&2; exit 1; }
  BACKUP_DIR="$(cat -- "$ACTIVE_FILE")"
  [[ "$BACKUP_DIR" == "$BACKUP_ROOT"/* && -d "$BACKUP_DIR" && -f "$BACKUP_DIR/wezterm.lua.before" ]] || {
    printf 'Invalid active backup.\n' >&2; exit 1;
  }
}

hash_file() { sha256sum -- "$1" | cut -d ' ' -f 1; }

check_target_identity() {
  local expected
  expected="$(cat -- "$BACKUP_DIR/target-path.txt")"
  [[ "$CONFIG_TARGET" == "$expected" ]] || {
    printf 'Conflict: WezTerm config now resolves to %s, backed up %s.\n' "$CONFIG_TARGET" "$expected" >&2
    exit 1
  }
}
