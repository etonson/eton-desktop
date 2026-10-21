#!/usr/bin/python3
"""Read a GNOME profile, preserve explicit/unset values, and manage activation."""
import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys

from gi.repository import Gio, GLib

PROJECT = Path(__file__).resolve().parent.parent
SOURCES = json.loads((PROJECT / 'config/sources.json').read_text())
UUID = SOURCES['blur_my_shell']['uuid']
DATA = Path(os.environ.get('XDG_DATA_HOME', str(Path.home() / '.local/share')))
STATE = Path(os.environ.get('XDG_STATE_HOME', str(Path.home() / '.local/state'))) / 'eton-desktop'
BACKUP = STATE / 'previous-settings.json'
SCHEMAS = DATA / 'gnome-shell/extensions' / UUID / 'schemas'


def settings(schema_id):
    source = Gio.SettingsSchemaSource.get_default()
    if (SCHEMAS / 'gschemas.compiled').exists():
        source = Gio.SettingsSchemaSource.new_from_directory(str(SCHEMAS), source, False)
    schema = source.lookup(schema_id, True)
    if schema is None:
        raise RuntimeError(f'Missing schema {schema_id}. Run ./scripts/install.sh first.')
    return Gio.Settings.new_full(schema, None, None)


PROFILE = PROJECT / 'config/profile.json'


def parse_value(schema_id, key, text):
    """Parse a GVariant text value and check it against the schema."""
    obj = settings(schema_id)
    schema = obj.props.settings_schema
    if not schema.has_key(key):
        raise RuntimeError(f'Unknown key: {schema_id} {key}')
    value = GLib.Variant.parse(schema.get_key(key).get_value_type(), text, None, None)
    if not schema.get_key(key).range_check(value):
        raise RuntimeError(f'Value out of range: {schema_id} {key}')
    if not obj.is_writable(key):
        raise RuntimeError(f'Setting is locked: {schema_id} {key}')
    return value


def profile_values():
    """Validate every key/value before changing any settings."""
    profile = json.loads(PROFILE.read_text())
    return [(schema_id, key, parse_value(schema_id, key, text))
            for schema_id, keys in profile.items() for key, text in keys.items()]


def set_profile(schema_id, key, text):
    """Change one value in config/profile.json; run apply to activate it."""
    parse_value(schema_id, key, text)
    profile = json.loads(PROFILE.read_text())
    profile.setdefault(schema_id, {})[key] = text
    temporary = PROFILE.with_suffix('.tmp')
    temporary.write_text(json.dumps(profile, indent=2, ensure_ascii=False) + '\n')
    temporary.replace(PROFILE)
    print(f'{schema_id} {key} = {text} (saved to {PROFILE.relative_to(PROJECT)}; run apply to activate)')


def snapshot(values):
    entries = []
    for schema_id, key, _ in values:
        value = settings(schema_id).get_user_value(key)
        entries.append([schema_id, key, value.print_(True) if value is not None else None])
    shell = settings('org.gnome.shell')
    return {
        'format': 1,
        'settings': entries,
        'extension_enabled': UUID in shell.get_strv('enabled-extensions'),
        'extension_disabled': UUID in shell.get_strv('disabled-extensions'),
    }


def save_backup(values):
    if BACKUP.exists():
        saved = json.loads(BACKUP.read_text())
        if saved.get('format') != 1:
            raise RuntimeError(f'Unsupported backup format: {BACKUP}')
        known = {(schema, key) for schema, key, _ in saved['settings']}
        new_entries = [entry for entry in snapshot(values)['settings'] if tuple(entry[:2]) not in known]
        if not new_entries:
            return
        saved['settings'].extend(new_entries)
    else:
        saved = snapshot(values)
    STATE.mkdir(parents=True, exist_ok=True)
    temporary = BACKUP.with_suffix('.tmp')
    with temporary.open('w') as stream:
        os.chmod(temporary, 0o600)
        json.dump(saved, stream, indent=2)
        stream.write('\n')
    temporary.replace(BACKUP)


def set_membership(shell, key, present):
    members = list(shell.get_strv(key))
    if present and UUID not in members:
        members.append(UUID)
    elif not present:
        members = [item for item in members if item != UUID]
    if not shell.set_strv(key, members):
        raise RuntimeError(f'Could not update {key}')


def check():
    if os.getuid() == 0:
        raise RuntimeError('Run as your desktop user, without sudo.')
    required = ['git', 'curl', 'sha256sum', 'gnome-shell', 'gnome-extensions', 'gtk-update-icon-cache']
    missing = [name for name in required if shutil.which(name) is None]
    if missing:
        raise RuntimeError('Missing commands: ' + ', '.join(missing))
    version = subprocess.check_output(['gnome-shell', '--version'], text=True).strip()
    match = re.search(r'(\d+)\.', version)
    if not match or int(match.group(1)) not in SOURCES['blur_my_shell']['shell_versions']:
        raise RuntimeError(f'Unsupported GNOME version for the pinned extension: {version}')
    if not os.environ.get('DBUS_SESSION_BUS_ADDRESS'):
        raise RuntimeError('Run from a terminal inside your GNOME desktop session.')
    # A session-bus connection is necessary for dconf to persist settings.
    Gio.bus_get_sync(Gio.BusType.SESSION, None)
    shell = settings('org.gnome.shell')
    for key in ['enabled-extensions', 'disabled-extensions']:
        if not shell.is_writable(key):
            raise RuntimeError(f'Extension management is locked: {key}')
    if shell.get_boolean('disable-user-extensions'):
        raise RuntimeError('User extensions are globally disabled. Enable them in the Extensions app first.')
    print(f'Prerequisites OK: {version}; user-scoped installation.')


def apply(dry_run=False):
    values = profile_values()
    if dry_run:
        for schema_id, key, value in values:
            print(f'{schema_id} {key} = {value.print_(True)}')
        print(f'Enable extension: {UUID}')
        return
    if not (DATA / 'icons/Tela-dark/index.theme').exists():
        raise RuntimeError('Tela-dark is missing. Run ./scripts/install.sh first.')
    check()
    shell = settings('org.gnome.shell')
    if (all(settings(schema_id).get_value(key).equal(value) for schema_id, key, value in values)
            and UUID in shell.get_strv('enabled-extensions')
            and UUID not in shell.get_strv('disabled-extensions')):
        print('Already up to date.')
        return
    save_backup(values)
    for schema_id, key, value in values:
        if not settings(schema_id).set_value(key, value):
            raise RuntimeError(f'Could not write {schema_id} {key}')
    set_membership(shell, 'enabled-extensions', True)
    set_membership(shell, 'disabled-extensions', False)
    Gio.Settings.sync()
    # GNOME may not discover newly installed extensions until the next login.
    subprocess.run(['gnome-extensions', 'enable', UUID], check=False)
    print(f'Profile saved. Original values: {BACKUP}')
    print('Save your work, then log out and log in if the extension is not active.')


def restore():
    saved = json.loads(BACKUP.read_text())
    if saved.get('format') != 1:
        raise RuntimeError('Unsupported backup format.')
    for schema_id, key, text in saved['settings']:
        obj = settings(schema_id)
        if text is None:
            obj.reset(key)
        else:
            value = GLib.Variant.parse(obj.get_value(key).get_type(), text, None, None)
            if not obj.set_value(key, value):
                raise RuntimeError(f'Could not restore {schema_id} {key}')
    shell = settings('org.gnome.shell')
    set_membership(shell, 'enabled-extensions', saved['extension_enabled'])
    set_membership(shell, 'disabled-extensions', saved['extension_disabled'])
    Gio.Settings.sync()
    command = 'enable' if saved['extension_enabled'] and not saved['extension_disabled'] else 'disable'
    subprocess.run(['gnome-extensions', command, UUID], check=False)
    print('Previous settings restored. Downloaded themes remain installed.')


def status():
    for schema_id, key, _ in profile_values():
        print(f'{schema_id} {key}: {settings(schema_id).get_value(key).print_(True)}')
    print(f'Backup: {BACKUP} ({"exists" if BACKUP.exists() else "not created"})')
    subprocess.run(['gnome-extensions', 'info', UUID], check=False)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command', choices=['check', 'apply', 'restore', 'status', 'set'])
    parser.add_argument('args', nargs='*', metavar='SCHEMA KEY VALUE',
                        help='For set: schema id, key and GVariant text value')
    parser.add_argument('--dry-run', action='store_true', help='Preview apply without writing settings')
    args = parser.parse_args()
    if args.dry_run and args.command != 'apply':
        parser.error('--dry-run is only valid with apply')
    if (args.command == 'set') != bool(args.args) or (args.args and len(args.args) != 3):
        parser.error('set takes exactly SCHEMA KEY VALUE; other commands take no arguments')
    try:
        if args.command == 'apply':
            apply(args.dry_run)
        elif args.command == 'set':
            set_profile(*args.args)
        else:
            {'check': check, 'restore': restore, 'status': status}[args.command]()
    except (OSError, RuntimeError, GLib.Error, ValueError, subprocess.SubprocessError) as exc:
        print(f'Error: {exc}', file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
