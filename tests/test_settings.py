"""Validate config/profile.json and the settings.py helpers against installed schemas.

Run from the project root: python3 -m unittest discover tests
"""
import json
from pathlib import Path
import shutil
import sys
import tempfile
import unittest
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / 'scripts'))
import settings  # noqa: E402

APPS = 'org.gnome.shell.extensions.blur-my-shell.applications'


def has_schema(schema_id):
    try:
        settings.settings(schema_id)
    except RuntimeError:
        return False
    return True


class ProfileFileTest(unittest.TestCase):
    def test_values_are_gvariant_text(self):
        profile = json.loads(settings.PROFILE.read_text())
        for schema_id, keys in profile.items():
            for key, text in keys.items():
                self.assertIsInstance(text, str, f'{schema_id} {key} must be a string')


@unittest.skipUnless(has_schema(APPS), 'Blur my Shell schemas are not installed')
class SchemaTest(unittest.TestCase):
    def test_profile_matches_schemas(self):
        self.assertTrue(settings.profile_values())

    def test_unknown_key_is_rejected(self):
        with self.assertRaisesRegex(RuntimeError, 'Unknown key'):
            settings.parse_value(APPS, 'no-such-key', '1')

    def test_out_of_range_is_rejected(self):
        # Blur my Shell declares no numeric ranges, so use a GNOME enum key.
        with self.assertRaisesRegex(RuntimeError, 'out of range'):
            settings.parse_value('org.gnome.desktop.interface', 'color-scheme', "'bogus'")

    def test_wrong_type_is_rejected(self):
        with self.assertRaises(settings.GLib.Error):
            settings.parse_value(APPS, 'opacity', "'high'")

    def test_set_updates_only_the_profile(self):
        with tempfile.TemporaryDirectory() as directory:
            profile = Path(directory) / 'profile.json'
            shutil.copy(settings.PROFILE, profile)
            with mock.patch.object(settings, 'PROFILE', profile), \
                 mock.patch.object(settings, 'PROJECT', Path(directory)):
                settings.set_profile(APPS, 'opacity', '200')
            self.assertEqual(json.loads(profile.read_text())[APPS]['opacity'], '200')
            self.assertFalse(profile.with_suffix('.tmp').exists())


if __name__ == '__main__':
    unittest.main()
