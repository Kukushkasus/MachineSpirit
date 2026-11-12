#!/usr/bin/env python3
# [ PURITY SEAL ] A pointer must point true. Leave the user's own cursor as it was found.
"""The faction cursor themes: the generator's files and hotspots, and ms-cursor's care for the user's own setup."""
import importlib.machinery, importlib.util, json, os, shutil, struct, subprocess, sys, tempfile, unittest
from pathlib import Path
# the tests run installers and ms-cursor: gsettings must not reach the real desktop (dconf over the session bus), nor hyprctl the running Hyprland
os.environ['GSETTINGS_BACKEND'] = 'memory'; os.environ.pop('HYPRLAND_INSTANCE_SIGNATURE', None)
ROOT = Path(__file__).resolve().parents[1]


def load(name, path):
    loader = importlib.machinery.SourceFileLoader(name, str(path)); spec = importlib.util.spec_from_loader(name, loader)
    m = importlib.util.module_from_spec(spec); loader.exec_module(m); return m


mc = load('make_cursors', ROOT / 'tools/make_cursors.py')


def read_xcursor(path):
    data = Path(path).read_bytes()
    magic, hsize, version, n = struct.unpack('<4sIII', data[:16])
    assert magic == b'Xcur'
    out = []
    for i in range(n):
        typ, sub, pos = struct.unpack('<III', data[16 + 12 * i:28 + 12 * i])
        _, _, nominal, _, w, h, xh, yh, delay = struct.unpack('<IIIIIIIII', data[pos:pos + 36])
        out.append((nominal, w, h, xh, yh, delay, data[pos + 36:pos + 36 + w * h * 4]))
    return out


class Generator(unittest.TestCase):
    def test_every_shape_draws_for_every_faction(self):
        for fac in mc.FACTIONS:
            for name in mc.CATALOG:
                docs = mc.shape_svgs(name, fac)
                self.assertTrue(docs and all(d.startswith('<svg') for d in docs), (fac, name))

    def test_aliases_are_unique(self):
        seen = {}
        for name, (_, aliases) in mc.CATALOG.items():
            for a in [name] + aliases:
                self.assertNotIn(a, seen, f'{a} is claimed by {seen.get(a)} and {name}')
                seen[a] = name

    def test_hotspots_lie_on_the_canvas(self):
        for name, ((x, y), _) in mc.CATALOG.items():
            self.assertTrue(0 <= x < mc.CANVAS and 0 <= y < mc.CANVAS, name)

    def test_xcursor_writer_round_trip(self):
        tmp = Path(tempfile.mkdtemp()); self.addCleanup(shutil.rmtree, tmp, True)
        px = bytes([1, 2, 3, 255]) * 4
        mc.write_xcursor(tmp / 'c', [(24, 2, 2, 1, 0, 0, px), (32, 2, 2, 1, 1, 50, px)])
        imgs = read_xcursor(tmp / 'c')
        self.assertEqual([(i[0], i[1], i[2], i[3], i[4], i[5]) for i in imgs], [(24, 2, 2, 1, 0, 0), (32, 2, 2, 1, 1, 50)])
        self.assertEqual(imgs[0][6], px)

    def test_premultiplied_argb(self):
        self.assertEqual(mc.to_xcursor_pixels(bytes([255, 128, 0, 128])), bytes([0, 64, 128, 128]))

    @unittest.skipUnless(shutil.which('rsvg-convert'), 'needs rsvg-convert')
    def test_build_one_theme(self):
        tmp = Path(tempfile.mkdtemp()); self.addCleanup(shutil.rmtree, tmp, True)
        mc.build(str(tmp), ['necrons'], (24, 32), hyprcursor=False)
        theme = tmp / 'MachineSpirit-Necrons'
        self.assertIn('Name=MachineSpirit Necrons', (theme / 'index.theme').read_text())
        imgs = read_xcursor(theme / 'cursors/default')
        self.assertEqual(sorted({i[0] for i in imgs}), [24, 32])
        # the arrow's tip is the hotspot: the pixel there (or right beside it) is drawn, not transparent
        for nominal, w, h, xh, yh, _, px in imgs:
            alpha = [px[((yh + dy) * w + (xh + dx)) * 4 + 3] for dx in (0, 1) for dy in (0, 1) if xh + dx < w and yh + dy < h]
            self.assertTrue(max(alpha) > 0, f'hotspot of size {nominal} is outside the shape')
        self.assertEqual(len([i for i in read_xcursor(theme / 'cursors/wait') if i[0] == 24]), mc.SPIN_FRAMES)
        self.assertTrue(os.path.islink(theme / 'cursors/left_ptr'))
        self.assertTrue((theme / 'preview/default.png').is_file())


class Apply(unittest.TestCase):
    """ms-cursor in a disposable HOME, with fake gsettings and no compositor."""
    def setUp(self):
        self.home = Path(tempfile.mkdtemp()); self.addCleanup(shutil.rmtree, self.home, True)
        self.bin = self.home / 'fakebin'; self.bin.mkdir()
        self.gs = self.home / 'gsettings.json'; self.gs.write_text(json.dumps({'cursor-theme': 'Adwaita', 'cursor-size': '24'}))
        (self.bin / 'gsettings').write_text(f'''#!/usr/bin/env python3
import json, sys
p = {str(self.gs)!r}; d = json.load(open(p)); a = sys.argv[1:]
if a[0] == 'get': print("'" + d.get(a[2], '') + "'")
elif a[0] == 'set': d[a[2]] = a[3]; json.dump(d, open(p, 'w'))
elif a[0] == 'reset': d.pop(a[2], None); json.dump(d, open(p, 'w'))
''')
        (self.bin / 'gsettings').chmod(0o755)
        # a fake hyprctl too: the tests must never reach the Hyprland of the machine they run on
        self.hyprctl_log = self.home / 'hyprctl.log'
        (self.bin / 'hyprctl').write_text(f'#!/bin/sh\necho "$@" >> {str(self.hyprctl_log)!r}\n'); (self.bin / 'hyprctl').chmod(0o755)
        self.env = dict(os.environ, HOME=str(self.home), XDG_CONFIG_HOME=str(self.home / '.config'),
                        XDG_DATA_HOME=str(self.home / '.local/share'), XDG_STATE_HOME=str(self.home / '.local/state'),
                        PATH=str(self.bin) + ':' + os.environ['PATH'])
        self.env.pop('HYPRLAND_INSTANCE_SIGNATURE', None)
        self.env['XDG_RUNTIME_DIR'] = str(self.home / 'run')
        icons = self.home / '.local/share/icons/MachineSpirit-Khorne'; (icons / 'cursors').mkdir(parents=True)
        (icons / 'index.theme').write_text('[Icon Theme]\nName=MachineSpirit Khorne\n')
        state = self.home / '.local/state/machinespirit'; state.mkdir(parents=True)
        (state / 'pack.json').write_text(json.dumps({'id': 'khorne', 'kit': 'khorne'}))

    def run_tool(self, *args):
        return subprocess.run([sys.executable, str(ROOT / 'bin/ms-cursor'), *args], env=self.env, capture_output=True, text=True)

    def settings(self, **kw):
        p = self.home / '.config/machinespirit/settings.json'; p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(json.dumps(dict(version=1, **kw)))

    def gsettings(self): return json.loads(self.gs.read_text())

    def test_faction_then_system_then_uninstall_restores_the_original(self):
        self.settings(cursorMode='faction', cursorSize=32)
        self.assertEqual(self.run_tool('apply').returncode, 0)
        self.assertEqual(self.gsettings()['cursor-theme'], 'MachineSpirit-Khorne')
        self.assertIn('MachineSpirit-Khorne', (self.home / '.config/machinespirit/cursor.lua').read_text())
        self.assertIn('Inherits=MachineSpirit-Khorne', (self.home / '.icons/default/index.theme').read_text())
        origin = json.loads((self.home / '.local/state/machinespirit/cursor-origin.json').read_text())
        self.assertEqual(origin['theme'], 'Adwaita')
        self.settings(cursorMode='system')
        self.run_tool('apply')
        self.assertEqual(self.gsettings()['cursor-theme'], 'Adwaita')
        self.assertFalse((self.home / '.icons/default/index.theme').exists())
        self.settings(cursorMode='faction'); self.run_tool('apply')
        self.assertEqual(self.run_tool('uninstall').returncode, 0)
        self.assertEqual(self.gsettings()['cursor-theme'], 'Adwaita')
        self.assertFalse((self.home / '.local/share/icons/MachineSpirit-Khorne').exists())

    def test_the_users_own_default_index_is_never_touched(self):
        own = self.home / '.icons/default/index.theme'; own.parent.mkdir(parents=True)
        own.write_text('[Icon Theme]\nInherits=Bibata\n')
        self.settings(cursorMode='faction'); self.run_tool('apply'); self.run_tool('uninstall')
        self.assertEqual(own.read_text(), '[Icon Theme]\nInherits=Bibata\n')

    def test_a_missing_custom_theme_keeps_the_system_cursor(self):
        self.settings(cursorMode='custom', cursorTheme='NoSuchTheme')
        r = self.run_tool('apply')
        self.assertEqual(r.returncode, 0); self.assertIn('not installed', r.stderr)
        self.assertEqual(self.gsettings()['cursor-theme'], 'Adwaita')

    def test_preview_changes_nothing_on_disk(self):
        self.settings(cursorMode='faction')
        self.run_tool('apply', '--runtime', '--pack', 'khorne')
        self.assertFalse((self.home / '.config/machinespirit/cursor.lua').exists())
        self.assertEqual(self.gsettings()['cursor-theme'], 'Adwaita')


    def bare_path(self):
        """Only the fake gsettings and python: no rsvg-convert, hyprcursor-util or hyprctl, as on a minimal system."""
        (self.bin / 'python3').symlink_to(sys.executable)
        self.env['PATH'] = str(self.bin)

    def test_no_rsvg_keeps_the_original_cursor_and_does_not_fail(self):
        self.bare_path()
        (self.home / '.local/state/machinespirit/pack.json').write_text(json.dumps({'id': 'necrons', 'kit': 'necrons'}))
        self.settings(cursorMode='faction')
        r = self.run_tool('apply')
        self.assertEqual(r.returncode, 0); self.assertIn('rsvg-convert', r.stderr)
        self.assertEqual(self.gsettings()['cursor-theme'], 'Adwaita')
        self.assertNotIn('XCURSOR_THEME', (self.home / '.config/machinespirit/cursor.lua').read_text())
        self.assertFalse((self.home / '.icons/default/index.theme').exists())

    def test_hyprcursor_theme_is_named_only_when_the_theme_has_one(self):
        self.settings(cursorMode='faction'); self.run_tool('apply')
        lua = (self.home / '.config/machinespirit/cursor.lua').read_text()
        self.assertIn('XCURSOR_THEME", "MachineSpirit-Khorne"', lua); self.assertNotIn('HYPRCURSOR_THEME', lua)
        (self.home / '.local/share/icons/MachineSpirit-Khorne/manifest.hl').write_text('name = x\n')
        self.run_tool('apply')
        self.assertIn('HYPRCURSOR_THEME", "MachineSpirit-Khorne"', (self.home / '.config/machinespirit/cursor.lua').read_text())

    def test_without_gsettings_the_session_cursor_is_remembered(self):
        (self.bin / 'gsettings').unlink(); self.bare_path()
        self.env.update(XCURSOR_THEME='Bibata-Modern-Ice', XCURSOR_SIZE='32')
        self.settings(cursorMode='faction'); self.run_tool('apply')
        origin = json.loads((self.home / '.local/state/machinespirit/cursor-origin.json').read_text())
        self.assertEqual((origin['theme'], origin['size']), ('Bibata-Modern-Ice', 32))
        self.settings(cursorMode='system'); self.run_tool('apply')
        self.assertIn('XCURSOR_THEME", "Bibata-Modern-Ice"', (self.home / '.config/machinespirit/cursor.lua').read_text())

    def test_a_cursor_the_user_chose_later_survives_uninstall(self):
        self.settings(cursorMode='faction'); self.run_tool('apply')
        data = self.gsettings(); data['cursor-theme'] = 'Breeze_Light'; self.gs.write_text(json.dumps(data))
        self.run_tool('uninstall')
        self.assertEqual(self.gsettings()['cursor-theme'], 'Breeze_Light')

    def test_custom_theme_that_exists_is_applied_and_system_returns(self):
        other = self.home / '.local/share/icons/Bibata/cursors'; other.mkdir(parents=True)
        self.settings(cursorMode='custom', cursorTheme='Bibata', cursorSize=40); self.run_tool('apply')
        self.assertEqual((self.gsettings()['cursor-theme'], self.gsettings()['cursor-size']), ('Bibata', '40'))
        self.settings(cursorMode='system'); self.run_tool('apply')
        self.assertEqual((self.gsettings()['cursor-theme'], self.gsettings()['cursor-size']), ('Adwaita', '24'))
        self.run_tool('uninstall')
        self.assertTrue(other.is_dir())   # someone else's theme is never removed

    def test_an_unchanged_setting_does_not_rewrite_files(self):
        self.settings(cursorMode='faction'); self.run_tool('apply')
        lua = self.home / '.config/machinespirit/cursor.lua'; os.utime(lua, (1, 1))
        self.run_tool('apply')
        self.assertEqual(lua.stat().st_mtime, 1)

    def test_the_faction_pointer_is_24_until_a_size_is_chosen(self):
        data = self.gsettings(); data['cursor-size'] = '32'; self.gs.write_text(json.dumps(data))
        self.settings(cursorMode='faction'); self.run_tool('apply')
        self.assertEqual(self.gsettings()['cursor-size'], '24')
        self.settings(cursorMode='system'); self.run_tool('apply')
        self.assertEqual(self.gsettings()['cursor-size'], '32')   # and System gives the user's own size back

    def test_no_compositor_is_touched_outside_a_session(self):
        self.settings(cursorMode='faction', cursorSize=48); self.run_tool('apply'); self.run_tool('uninstall')
        self.assertFalse(self.hyprctl_log.exists())

    def test_inside_a_session_the_running_compositor_follows(self):
        self.env['HYPRLAND_INSTANCE_SIGNATURE'] = 'test'
        self.settings(cursorMode='faction', cursorSize=32); self.run_tool('apply')
        self.assertEqual(self.hyprctl_log.read_text().split(), ['setcursor', 'MachineSpirit-Khorne', '32'])

    def test_cursor_lua_is_loaded_before_the_users_local_lua(self):
        conf = (ROOT / 'hypr/hyprland.lua').read_text()
        self.assertLess(conf.index('machinespirit/cursor.lua'), conf.index('pcall(require, "local")'))


if __name__ == '__main__':
    unittest.main()
