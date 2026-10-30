# [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
"""Run with python3 -m unittest discover -s tools -p test_desktop_state.py."""
import json
from pathlib import Path
import subprocess
import tempfile
import unittest

HELPER = Path(__file__).resolve().parents[1] / 'quickshell/scripts/desktop-state.py'

class DesktopStateTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.path = Path(self.temp.name) / 'state.json'
        self.data = {'version': 1, 'seconds': False,
                     'widgets': {'notes': {'enabled': True, 'screen': 'Virtual-1', 'x': 24, 'y': 70, 'scale': 1}},
                     'note': {'title': 'Заметка «тест»', 'text': 'Привет\n\'" $HOME $(touch /tmp/not-a-command) `id`'}}

    def call(self, mode, data=None):
        return subprocess.run(['python3', str(HELPER), mode, str(self.path)],
                              input=json.dumps(data) + '\n' if data is not None else None,
                              text=True, capture_output=True)

    def test_roundtrip_and_permissions(self):
        self.assertTrue(json.loads(self.call('read').stdout)['missing'])
        self.assertEqual(self.call('write', self.data).returncode, 0)
        self.assertEqual(json.loads(self.call('read').stdout)['data'], self.data)
        self.assertEqual(self.path.stat().st_mode & 0o777, 0o600)
        self.assertEqual(list(self.path.parent.glob('.desktop-*')), [])

    def test_damaged_or_newer_file_is_preserved(self):
        for text in ['{bad', json.dumps(dict(self.data, version=2))]:
            self.path.write_text(text)
            self.assertNotEqual(self.call('write', self.data).returncode, 0)
            self.assertEqual(self.path.read_text(), text)

    def test_invalid_write_preserves_existing_note(self):
        self.call('write', self.data)
        original = self.path.read_bytes()
        bad = json.loads(json.dumps(self.data))
        bad['widgets']['notes']['scale'] = float('nan')
        self.assertNotEqual(self.call('write', bad).returncode, 0)
        self.assertEqual(self.path.read_bytes(), original)

if __name__ == '__main__':
    unittest.main()
