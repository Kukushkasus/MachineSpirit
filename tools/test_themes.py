#!/usr/bin/env python3
# [ PURITY SEAL ] A pack is data. Prove it stays data, and that a preview leaves no trace.
"""Theme packs, colour modes, the preview and the settings added with them."""
import colorsys, importlib.machinery, importlib.util, json, os, shutil, subprocess, sys, tempfile, time, unittest
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'bin'))
import ms_packs

def load(name, path):
    loader = importlib.machinery.SourceFileLoader(name, str(path)); spec = importlib.util.spec_from_loader(name, loader)
    m = importlib.util.module_from_spec(spec); loader.exec_module(m); return m
theme = load('ms_theme', ROOT / 'scripts/ms-theme')
settings = load('ms_settings', ROOT / 'bin/ms-settings')
BUILTIN = ('mechanicus', 'ultramarines', 'necrons', 'khorne')
PNG = b'\x89PNG\r\n\x1a\n' + b'\0' * 64

class PackCase(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp()); self.addCleanup(shutil.rmtree, self.tmp, True)
        self.base = json.loads((ROOT / 'quickshell/themes/mechanicus/theme.json').read_text())
        self.base.pop('preview', None); self.base['wallpapers'] = []      # the copies under test carry no pictures of their own
    def pack(self, pid='mine', files=None, **changes):
        d = self.tmp / pid; d.mkdir(parents=True, exist_ok=True)
        (d / 'theme.json').write_text(json.dumps(dict(self.base, id=pid, **changes)))
        for name, body in (files or {}).items():
            f = d / name; f.parent.mkdir(parents=True, exist_ok=True); f.write_bytes(body if isinstance(body, bytes) else body.encode())
        return d
    def bad(self, d, word):
        with self.assertRaises(ms_packs.PackError) as e: ms_packs.load(d)
        self.assertIn(word, str(e.exception))

class BuiltInPacks(PackCase):
    def test_all_four_are_valid_and_complete(self):
        for pid in BUILTIN:
            with self.subTest(pack=pid):
                p = ms_packs.load(ROOT / 'quickshell/themes' / pid)
                self.assertEqual(p['kit'], pid); self.assertEqual(p['schema'], ms_packs.SCHEMA)
                self.assertTrue(p['lexicon']['panelTitle']); self.assertTrue(p['litanies'])
    def test_mechanicus_is_the_default_and_matches_the_fallback(self):
        self.assertEqual(ms_packs.DEFAULT_ID, 'mechanicus')
        p = ms_packs.load(ROOT / 'quickshell/themes/mechanicus')
        self.assertEqual(p['palette']['anchors'], theme.FALLBACK_PACK['palette']['anchors'])
        self.assertEqual(p['palette']['seed'], theme.FIXED_SEED)
    def test_factions_differ_in_more_than_colour(self):
        packs = [ms_packs.load(ROOT / 'quickshell/themes' / pid) for pid in BUILTIN]
        for key in ('kit', 'motion', 'lexicon', 'effects'):
            self.assertEqual(len({json.dumps(p[key], sort_keys=True) for p in packs}), 4, key)
    def test_every_pack_ships_a_4k_wallpaper_and_a_preview(self):
        def jpeg_size(path):
            b = Path(path).read_bytes(); i = 2
            while i < len(b):
                if b[i] != 0xFF: i += 1; continue
                m = b[i + 1]
                if m in (0xC0, 0xC1, 0xC2): return int.from_bytes(b[i + 7:i + 9], 'big'), int.from_bytes(b[i + 5:i + 7], 'big')
                i += 2 + int.from_bytes(b[i + 2:i + 4], 'big')
        for pid in BUILTIN:
            with self.subTest(pack=pid):
                p = ms_packs.load(ROOT / 'quickshell/themes' / pid)
                self.assertTrue(p['wallpapers'], 'no wallpaper')
                for w in p['wallpapers']:
                    self.assertEqual(jpeg_size(w['file']), (3840, 2160)); self.assertLess(Path(w['file']).stat().st_size, 12 * 1024 * 1024)
                self.assertTrue(p['preview'] and Path(p['preview']).is_file())

class PackSafety(PackCase):
    def test_a_plain_copy_is_accepted(self): self.assertEqual(ms_packs.load(self.pack())['id'], 'mine')
    def test_newer_schema_is_refused_with_a_reason(self): self.bad(self.pack(schema=3), 'schema 3')
    def test_missing_schema(self):
        d = self.pack(); j = json.loads((d / 'theme.json').read_text()); del j['schema']; (d / 'theme.json').write_text(json.dumps(j)); self.bad(d, 'schema')
    def test_id_must_match_folder(self):
        d = self.pack(); j = json.loads((d / 'theme.json').read_text()); j['id'] = 'other'; (d / 'theme.json').write_text(json.dumps(j)); self.bad(d, 'folder')
    def test_unknown_kit(self): self.bad(self.pack(kit='orks'), 'kit')
    def test_bad_colour(self): self.bad(self.pack(materials={'glow': 'red; rm -rf'}), 'colour')
    def test_paths_cannot_leave_the_pack(self):
        for path in ('../../etc/passwd', '/etc/passwd', 'a/../../x.png', '.hidden/x.png', 'x\\y.png'):
            with self.subTest(path=path): self.bad(self.pack(wallpapers=[{'file': path}]), 'wallpaper')
    def test_links_are_refused(self):
        d = self.pack(files={'real.png': PNG}); (d / 'w.png').symlink_to('/etc/hostname')
        (d / 'theme.json').write_text(json.dumps(dict(self.base, id='mine', wallpapers=[{'file': 'w.png'}]))); self.bad(d, 'links')
        d2 = self.pack('two'); (d2 / 'stray').symlink_to('/etc'); self.bad(d2, 'links')
    def test_only_pictures_and_only_real_ones(self):
        self.bad(self.pack(files={'w.sh': '#!/bin/sh'}, wallpapers=[{'file': 'w.sh'}]), 'png, jpg')
        self.bad(self.pack('fake', files={'w.png': 'not a picture'}, wallpapers=[{'file': 'w.png'}]), 'not the picture')
        self.bad(self.pack('void', files={'w.png': b''}, wallpapers=[{'file': 'w.png'}]), 'empty')
    def test_code_cannot_ride_along(self):
        for name in ('Evil.qml', 'run.js', 'hook.sh', 'x.py'):
            with self.subTest(name=name): self.bad(self.pack(name.split('.')[0].lower() + 'p', files={name: 'x'}), 'only pictures')
    def test_svg_with_scripts_or_outside_references(self):
        for i, body in enumerate(['<svg><script>x</script></svg>', '<svg onload="x()"></svg>', '<svg><image href="http://x/y.png"/></svg>',
                                  '<svg><foreignObject/></svg>', '<svg><a href="javascript:x"/></svg>', '<svg><image xlink:href="file:///etc/passwd"/></svg>']):
            with self.subTest(body=body): self.bad(self.pack('s%d' % i, files={'p.svg': body}, preview='p.svg'), 'scripts')
        ok = self.pack('good', files={'p.svg': '<svg xmlns="http://www.w3.org/2000/svg"><rect fill="url(#g)"/></svg>'}, preview='p.svg')
        self.assertTrue(ms_packs.load(ok)['preview'].endswith('p.svg'))
    def test_limits(self):
        self.bad(self.pack(files={'%d.png' % i: PNG for i in range(ms_packs.MAX_FILES + 1)}), 'files')
        self.bad(self.pack('many', wallpapers=[{'file': 'a.png'}] * (ms_packs.MAX_WALLPAPERS + 1)), 'at most')
        d = self.pack('big'); (d / 'theme.json').write_text(' ' * (ms_packs.MAX_JSON + 1)); self.bad(d, 'too large')
        self.bad(self.pack('lit', litanies=['x'] * 13), 'litanies')
    def test_unknown_keys_and_reserved_words_are_dropped(self):
        p = ms_packs.load(self.pack(command='rm -rf ~', onLoad='x', lexicon=dict(self.base['lexicon'], shutdown='Purge', error='Heresy', lock='Seal', network='Noosphere')))
        self.assertNotIn('command', p); self.assertNotIn('onLoad', p)
        for word in ('shutdown', 'error', 'lock', 'network'): self.assertNotIn(word, p['lexicon'])
        self.assertEqual(set(p), {'schema', 'id', 'name', 'tagline', 'author', 'version', 'kit', 'skin', 'palette', 'materials', 'lexicon', 'litanies', 'motion', 'effects', 'wallpapers', 'preview'})
    def test_text_is_plain_and_short(self):
        self.bad(self.pack(name='x' * 200), 'name'); self.bad(self.pack('multi', lexicon={'panelTitle': 'a\nb'}), 'lexicon')
    def test_catalogue_reports_bad_packs_and_protects_builtin_ids(self):
        builtin = self.tmp / 'builtin'; user = self.tmp / 'user'
        shutil.copytree(ROOT / 'quickshell/themes/mechanicus', builtin / 'mechanicus')
        (user / 'mechanicus').mkdir(parents=True); (user / 'mechanicus/theme.json').write_text(json.dumps(dict(self.base, name='Impostor')))
        (user / 'broken').mkdir(); (user / 'broken/theme.json').write_text('{nope')
        old = ms_packs.BUILTIN, ms_packs.USER; ms_packs.BUILTIN, ms_packs.USER = builtin, user
        try:
            rows = ms_packs.catalogue()
            self.assertEqual(ms_packs.find('mechanicus')['name'], 'Adeptus Mechanicus')
        finally: ms_packs.BUILTIN, ms_packs.USER = old
        self.assertEqual([(r['id'], r['builtin'], r['ok']) for r in rows], [('mechanicus', True, True), ('broken', False, False), ('mechanicus', False, False)])
        self.assertIn('built-in', rows[2]['error'])

class Skins(PackCase):
    """Schema 2: a pack picks a built-in livery per slot. Nothing but names from the whitelist gets through."""
    SLOTS = ms_packs.SKIN_SLOTS
    def test_schema_1_pack_migrates_to_its_kit_everywhere(self):
        b = dict(self.base); b.pop('skin', None)
        d = self.tmp / 'old'; d.mkdir(); (d / 'theme.json').write_text(json.dumps(dict(b, id='old', schema=1, kit='necrons')))
        p = ms_packs.load(d)
        self.assertEqual(p['schema'], 2); self.assertEqual(p['skin'], {k: 'necrons' for k in self.SLOTS})
    def test_slots_can_be_mixed_and_missing_slots_follow_the_kit(self):
        p = ms_packs.load(self.pack(skin={'bar': 'khorne', 'type': 'ultramarines'}))
        self.assertEqual(p['skin']['bar'], 'khorne'); self.assertEqual(p['skin']['type'], 'ultramarines'); self.assertEqual(p['skin']['frame'], p['kit'])
    def test_unknown_livery_is_refused(self): self.bad(self.pack(skin={'bar': '../../evil'}), 'unknown livery')
    def test_unknown_slot_is_refused(self): self.bad(self.pack(skin={'shell.qml': 'khorne'}), 'unknown slot')
    def test_skin_must_be_names_not_objects(self): self.bad(self.pack(skin={'bar': {'source': 'x.qml'}}), 'unknown livery')
    def test_every_livery_ships_every_part(self):
        parts = {f.name for f in (ROOT / 'quickshell/skins/mechanicus').glob('*.qml')}
        self.assertGreaterEqual(len(parts), 9)
        for style in BUILTIN:
            with self.subTest(style=style): self.assertEqual({f.name for f in (ROOT / 'quickshell/skins' / style).glob('*.qml')}, parts)
    def test_qml_whitelist_matches_the_validator(self):
        qml = (ROOT / 'quickshell/common/Skin.qml').read_text()
        for s in BUILTIN: self.assertIn(f'"{s}"', qml)
        for slot in self.SLOTS: self.assertIn(f'of("{slot}")', qml)
    def test_faction_faces_ship_with_their_licences(self):
        fonts = ROOT / 'quickshell/assets/fonts'
        for f in ('Cinzel', 'Michroma', 'GrenzeGotisch'):
            self.assertTrue((fonts / f'{f}.ttf').read_bytes()[:4] in (b'\x00\x01\x00\x00', b'true'), f)
            self.assertIn('SIL Open Font License', (fonts / f'OFL-{f}.txt').read_text())
    def test_built_in_packs_name_their_own_livery(self):
        for pid in BUILTIN:
            self.assertEqual(set(ms_packs.load(ROOT / 'quickshell/themes' / pid)['skin'].values()), {pid})

class ColourModes(unittest.TestCase):
    def test_old_names_keep_their_meaning(self):
        self.assertEqual(theme.MODES, {'follow': 'follow', 'strict': 'guarded', 'guarded': 'guarded', 'fixed': 'faction', 'faction': 'faction'})
        self.assertEqual({theme.LEGACY[v] for v in theme.MODES.values()}, {'follow', 'strict', 'fixed'})
    def test_guarded_mechanicus_is_exactly_the_old_strict(self):
        def old(seed):   # clamp_hue as shipped in 0.2.0
            h, l, s = colorsys.rgb_to_hls(*theme.hex_to_rgb(seed)); deg = h * 360
            if not (deg >= 350 or deg <= 52): deg = 6.0 + (deg / 360) * 40.0
            return theme.rgb_to_hex(*colorsys.hls_to_rgb((deg % 360) / 360, min(max(l, 0.38), 0.62), max(s, 0.45)))
        pal = ms_packs.load(ROOT / 'quickshell/themes/mechanicus')['palette']
        for seed in ('#121c18', '#2f5fb3', '#b0702a', '#ff0000', '#808080', '#00ff88', '#f1e05a', '#7b2fbe', '#000000', '#ffffff'):
            self.assertEqual(theme.clamp_hue(seed, pal), old(seed), seed)
    def test_guarded_keeps_every_faction_inside_its_own_band(self):
        for pid in BUILTIN:
            pal = ms_packs.load(ROOT / 'quickshell/themes' / pid)['palette']
            for seed in ('#ff0000', '#00ff00', '#0000ff', '#ffff00', '#ff00ff', '#00ffff', '#777777', '#3b1f0a'):
                h = colorsys.rgb_to_hls(*theme.hex_to_rgb(theme.clamp_hue(seed, pal)))[0] * 360
                self.assertTrue(theme.in_arc(round(h), pal['accept'][0] - 1, pal['accept'][1] + 1), (pid, seed, h))
    def test_anchors_always_come_from_the_pack_and_readings_stay_legible(self):
        pack = ms_packs.load(ROOT / 'quickshell/themes/khorne')
        for mode in ('follow', 'guarded', 'faction'):
            c = theme.dress({'glass': '#080404', 'glow': '#301010', 'glow_dim': '#201010', 'metal': '#123456'}, pack, mode)
            self.assertEqual(c['spark'], pack['palette']['anchors']['energy']); self.assertEqual(c['rust'], pack['palette']['anchors']['danger'])
            self.assertGreaterEqual(theme.contrast(c['glow'], c['glass']), 7); self.assertGreaterEqual(theme.contrast(c['glow_dim'], c['glass']), 4.5)
        self.assertEqual(theme.dress({'metal': '#123456'}, pack, 'follow')['metal'], '#123456')          # the wallpaper leads
        self.assertEqual(theme.dress({'brass': '#123456'}, pack, 'follow')['brass'], pack['materials']['brass'])     # but the trim stays
        self.assertEqual(theme.dress({'metal': '#123456'}, pack, 'faction')['metal'], pack['materials']['metal'])
    def test_theme_conf_keeps_the_users_lines_and_old_names(self):
        with tempfile.TemporaryDirectory() as d:
            conf = Path(d) / 'theme.conf'; conf.write_text('# mine\nmode = strict\ndarkness = -0.1\ntype = auto\n')
            old = theme.CONF; theme.CONF = conf
            try:
                theme.save_conf('mechanicus', 'guarded'); a = conf.read_text()
                theme.save_conf('necrons', 'faction'); b = conf.read_text()
            finally: theme.CONF = old
            self.assertEqual(a, '# mine\nmode = strict\ndarkness = -0.1\ntype = auto\npack = mechanicus\n')     # same meaning: left as written
            self.assertEqual(b, '# mine\nmode = faction\ndarkness = -0.1\ntype = auto\npack = necrons\n')

class Preview(unittest.TestCase):
    """The real ms-theme in a throwaway home, without matugen: a preview may write under XDG_RUNTIME_DIR only."""
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp()); self.addCleanup(shutil.rmtree, self.tmp, True)
        d = self.tmp
        shutil.copytree(ROOT / 'quickshell/themes', d / 'c/quickshell/machinespirit/themes')
        shutil.copytree(ROOT / 'matugen', d / 's/machinespirit/matugen'); (d / 's/machinespirit/tools').mkdir(parents=True)
        shutil.copy(ROOT / 'tools/managed.py', d / 's/machinespirit/tools/managed.py')
        (d / 'c/machinespirit').mkdir(parents=True); (d / 'c/machinespirit/theme.conf').write_text('mode = strict\n')
        (d / 'c/machinespirit/settings.json').write_text('{"version": 1}')
        (d / 's/machinespirit/wallpapers').mkdir(); (d / 's/machinespirit/wallpapers/forge.png').write_bytes(PNG)
        (d / 'st/machinespirit').mkdir(parents=True); (d / 'run').mkdir(); (d / 'bin').mkdir()
        os.symlink(sys.executable, d / 'bin/python3')
        self.env = dict(HOME=str(d), XDG_CONFIG_HOME=str(d / 'c'), XDG_DATA_HOME=str(d / 's'), XDG_STATE_HOME=str(d / 'st'), XDG_RUNTIME_DIR=str(d / 'run'), PATH=str(d / 'bin'))
        self.preview = d / 'run/machinespirit/preview'
    def run_theme(self, *args):
        r = subprocess.run([sys.executable, str(ROOT / 'scripts/ms-theme'), *args], env=self.env, capture_output=True, text=True); return r
    def permanent(self):
        return {str(p.relative_to(self.tmp)): p.read_bytes() for base in ('c', 's', 'st') for p in sorted((self.tmp / base).rglob('*')) if p.is_file() and '__pycache__' not in p.parts}
    def test_preview_touches_nothing_permanent_and_ends_clean(self):
        before = self.permanent()
        r = self.run_theme('preview', 'necrons', '--mode', 'faction', '--seconds', '60'); out = json.loads(r.stdout)
        self.assertEqual(r.returncode, 0, r.stderr); self.assertEqual(out['preview'], 'necrons')
        self.assertEqual(self.permanent(), before)
        self.assertEqual(sorted(p.name for p in self.preview.iterdir()), ['colors.json', 'meta.json', 'pack.json'])
        colors = json.loads((self.preview / 'colors.json').read_text()); pack = json.loads((self.preview / 'pack.json').read_text())
        self.assertEqual(pack['kit'], 'necrons'); self.assertEqual(colors['spark'], '#39ff9c'); self.assertEqual(colors['metal'], pack['materials']['metal'])
        self.assertEqual(json.loads((self.preview / 'meta.json').read_text())['token'], out['token'])
        self.assertEqual(self.run_theme('preview-end').returncode, 0)
        self.assertEqual(list(self.preview.iterdir()), []); self.assertEqual(self.permanent(), before)
    def test_preview_times_out_by_itself_when_nobody_ends_it(self):
        self.assertEqual(self.run_theme('preview', 'khorne', '--seconds', '5').returncode, 0)
        self.assertTrue((self.preview / 'meta.json').exists())
        deadline = time.time() + 15
        while (self.preview / 'meta.json').exists() and time.time() < deadline: time.sleep(0.5)
        self.assertEqual(list(self.preview.iterdir()), [])
    def test_an_old_watchdog_does_not_end_a_newer_preview(self):
        self.run_theme('preview', 'khorne', '--seconds', '60'); first = json.loads((self.preview / 'meta.json').read_text())['token']
        self.run_theme('preview', 'necrons', '--seconds', '60')
        self.run_theme('preview-watchdog', first, '0')
        self.assertEqual(json.loads((self.preview / 'pack.json').read_text())['kit'], 'necrons')
        self.run_theme('preview-end')
    def test_a_bad_pack_cannot_be_previewed_or_applied(self):
        bad = self.tmp / 's/machinespirit/themes/future'; bad.mkdir(parents=True)
        (bad / 'theme.json').write_text(json.dumps(dict(json.loads((ROOT / 'quickshell/themes/mechanicus/theme.json').read_text()), id='future', schema=9, preview='')))
        before = self.permanent()
        r = self.run_theme('preview', 'future'); self.assertNotEqual(r.returncode, 0); self.assertIn('schema 9', r.stdout)
        self.assertFalse((self.preview / 'meta.json').exists())
        r = self.run_theme('apply', '--pack', 'future', '--save'); self.assertNotEqual(r.returncode, 0)
        after = self.permanent(); after = {k: v for k, v in after.items() if '/install/' not in k and not k.endswith(('.lock', 'matugen-runtime.toml'))}
        self.assertEqual(after, before)                    # rolled back: conf, colours and state as they were
    def test_apply_saves_the_choice_and_revert_returns(self):
        r = self.run_theme('apply', '--pack', 'ultramarines', '--mode', 'faction', '--save'); self.assertEqual(r.returncode, 0, r.stderr)
        st = self.tmp / 'st/machinespirit'; conf = self.tmp / 'c/machinespirit/theme.conf'
        state = json.loads((st / 'theme.json').read_text())
        self.assertEqual((state['pack'], state['colors'], state['mode']), ('ultramarines', 'faction', 'fixed'))
        self.assertEqual(json.loads((st / 'pack.json').read_text())['kit'], 'ultramarines')
        self.assertEqual(conf.read_text(), 'mode = faction\npack = ultramarines\n')
        self.assertEqual(state['source_wallpaper'], str(self.tmp / 's/machinespirit/wallpapers/forge.png'))     # the wallpaper is not the pack's to change
        self.assertEqual(self.run_theme('revert').returncode, 0)
        state = json.loads((st / 'theme.json').read_text()); self.assertEqual(state['pack'], 'mechanicus')
    def test_a_0_2_0_install_without_a_pack_setting_stays_mechanicus_in_its_old_mode(self):
        r = self.run_theme('apply'); self.assertEqual(r.returncode, 0, r.stderr)
        state = json.loads((self.tmp / 'st/machinespirit/theme.json').read_text())
        self.assertEqual((state['pack'], state['mode'], state['colors']), ('mechanicus', 'strict', 'guarded'))
        self.assertEqual((self.tmp / 'c/machinespirit/theme.conf').read_text(), 'mode = strict\n')          # not rewritten behind the user's back
    def test_a_missing_pack_in_the_conf_falls_back_instead_of_breaking(self):
        (self.tmp / 'c/machinespirit/theme.conf').write_text('pack = deleted-pack\nmode = follow\n')
        r = self.run_theme('apply'); self.assertEqual(r.returncode, 0, r.stderr)
        self.assertEqual(json.loads((self.tmp / 'st/machinespirit/theme.json').read_text())['pack'], 'mechanicus')
        self.assertEqual((self.tmp / 'c/machinespirit/theme.conf').read_text(), 'pack = deleted-pack\nmode = follow\n')
    def test_packs_listing(self):
        out = json.loads(self.run_theme('packs').stdout)
        self.assertEqual(sorted(p['id'] for p in out['packs']), sorted(BUILTIN)); self.assertTrue(all(p['ok'] for p in out['packs']))
        self.assertEqual((out['active'], out['mode']), ('mechanicus', 'guarded'))

NEW = dict(panelOpacity=1.0, glowStrength=1.0, density='comfortable', ornaments='full', barAllScreens=True, barLeft=['clock', 'instruments', 'caption'],
           barRight=['media', 'tray'], barWeather=True, barNetRate=True, widgetScan=True, fxLevel=2, fxFrequency=1.0, animSpeed=1.0, fxDischarge=True,
           fxScreens=True, fxParticles=True, fxMessages=True, toastSeconds=6, toastMax=4, urgentThroughQuiet=True, historyLimit=100, holdMs=800, superTap=True)

class NewSettings(unittest.TestCase):
    def test_a_0_2_0_file_migrates_untouched_and_gains_defaults(self):
        old = json.loads(subprocess.check_output(['git', '-C', str(ROOT), 'show', 'HEAD:config/settings.json']))
        old.update(layouts=['us', 'ru'], rounding=8, lowPower=True)
        new = settings.validate(old)
        for k, v in old.items():
            if k != 'privacy': self.assertEqual(new[k], v, k)
        for k, v in NEW.items(): self.assertEqual(new[k], v, k)
    def test_every_new_key_has_a_default_a_shipped_value_and_a_consumer(self):
        shipped = json.loads((ROOT / 'config/settings.json').read_text())
        qml = '\n'.join(p.read_text() for p in (ROOT / 'quickshell').rglob('*.qml') if 'modules/settings' not in str(p))
        pages = '\n'.join(p.read_text() for p in (ROOT / 'quickshell/modules/settings').glob('*.qml'))
        for k, v in NEW.items():
            self.assertEqual(settings.DEFAULT[k], v, k); self.assertEqual(shipped[k], v, k)
            # read as Settings.data.<key>, or by name through Theme.fxOn's table
            self.assertTrue('Settings.data.' + k in qml or '"' + k + '"' in qml, k + ' has no consumer outside the settings pages')
            self.assertTrue('"' + k + '"' in pages, k + ' cannot be set or reset in Settings')
    def test_unsafe_values_are_rejected(self):
        for patch in [{'fxLevel': 4}, {'fxLevel': 1.5}, {'fxLevel': True}, {'panelOpacity': 0.2}, {'panelOpacity': float('nan')}, {'glowStrength': 9}, {'density': 'tiny'},
                      {'ornaments': 'none'}, {'barLeft': ['clock', 'rm -rf']}, {'barLeft': ['clock', 'clock']}, {'barLeft': 'clock'}, {'barRight': ['clock']},
                      {'barAllScreens': 1}, {'toastSeconds': 0}, {'toastMax': 99}, {'historyLimit': 5}, {'holdMs': 0}, {'animSpeed': 0}, {'fxFrequency': 5}, {'superTap': 'yes'}]:
            with self.subTest(patch=patch), self.assertRaises(ValueError): settings.validate(dict(version=1, **patch))
    def test_values_persist_and_reset(self):
        with tempfile.TemporaryDirectory() as d:
            env = dict(os.environ, HOME=d, XDG_CONFIG_HOME=d + '/c', XDG_STATE_HOME=d + '/st'); env.pop('HYPRLAND_INSTANCE_SIGNATURE', None)
            patch = dict(version=1, fxLevel=0, barLeft=['caption', 'clock'], barRight=[], panelOpacity=0.7, ornaments='reduced', holdMs=1500, density='compact', toastMax=2)
            r = subprocess.run([sys.executable, str(ROOT / 'bin/ms-settings'), 'write'], input=json.dumps(patch), text=True, env=env, capture_output=True)
            self.assertEqual(r.returncode, 0, r.stdout)
            saved = json.loads(Path(d, 'c/machinespirit/settings.json').read_text())
            for k, v in patch.items(): self.assertEqual(saved[k], v, k)
            back = json.loads(subprocess.run([sys.executable, str(ROOT / 'bin/ms-settings'), 'read'], env=env, capture_output=True, text=True).stdout)
            for k, v in NEW.items(): self.assertEqual(back['defaults'][k], v, k)      # what "Reset page" restores

OLD = ROOT / '.dist/MachineSpirit-0.2.0.tar.gz'

@unittest.skipUnless(OLD.is_file(), 'needs the 0.2.0 release archive in .dist')
class ReleaseLifecycle(unittest.TestCase):
    """From the built archives only: install 0.2.0, live in it, update to this tree, uninstall. The user's things survive each step."""
    def test_update_from_0_2_0_then_uninstall(self):
        import tarfile
        with tempfile.TemporaryDirectory(prefix='ms life ') as d:
            d = Path(d)
            new = load('rb', ROOT / 'tools/build-release.py').build(ROOT, d / 'out')[0]
            # the archive stays within the 60 MiB budget and carries no README media (showcase, screenshots)
            self.assertLess(Path(new).stat().st_size, 60 * 1024 * 1024)
            with tarfile.open(new) as t: names = t.getnames()
            self.assertFalse([n for n in names if '/docs/media/' in n and not n.endswith('.svg')], 'README media must stay out of the archive')
            for pid in BUILTIN: self.assertTrue(any(n.startswith(f'MachineSpirit/quickshell/themes/{pid}/wallpapers/') for n in names), pid)
            for name, archive in (('old', OLD), ('new', new)):
                (d / name).mkdir()
                with tarfile.open(archive) as t: t.extractall(d / name, filter='data')
            env = dict(os.environ, HOME=str(d / 'h'), XDG_CONFIG_HOME=str(d / 'c'), XDG_DATA_HOME=str(d / 'd'), XDG_STATE_HOME=str(d / 's'), XDG_RUNTIME_DIR=str(d / 'r'), PATH='/usr/bin:/bin')
            env.pop('HYPRLAND_INSTANCE_SIGNATURE', None); (d / 'h').mkdir(); (d / 'r').mkdir()
            def run(tree, *args):
                r = subprocess.run(['bash', str(d / tree / 'MachineSpirit/install.sh'), *args, '--no-packages', '--no-system', '--yes'], env=env, capture_output=True, text=True, stdin=subprocess.DEVNULL)
                self.assertEqual(r.returncode, 0, r.stdout[-600:] + r.stderr[-600:]); return r
            run('old', '--components', 'shell,hyprland,terminal,apps,lock,wallpapers')
            conf = d / 'c/machinespirit'; shell = d / 'c/quickshell/machinespirit'
            self.assertFalse((shell / 'themes').exists()); self.assertTrue((shell / 'common/LevelColumn.qml').exists())
            # the user lives in 0.2.0: own settings, the old strict mode, and (later) a pack of their own
            mine = dict(json.loads((conf / 'settings.json').read_text()), rounding=3, layouts=['us', 'ru'], lowPower=True)
            (conf / 'settings.json').write_text(json.dumps(mine, indent=2)); (conf / 'theme.conf').write_text('# mine\nmode = strict\ndarkness = -0.1\n')
            run('new', 'update')
            self.assertEqual((d / 'd/machinespirit/VERSION').read_text().strip(), (ROOT / 'VERSION').read_text().strip())
            for rel in ('themes/mechanicus/theme.json', 'themes/khorne/wallpapers/forge.jpg', 'kits/BarSpan.qml', 'services/ThemePacks.qml', 'modules/settings/ThemesPage.qml'):
                self.assertTrue((shell / rel).is_file(), rel)
            self.assertTrue((d / 'h/.local/bin/ms_packs.py').is_file() or any((d / 'h').rglob('ms_packs.py')))
            self.assertFalse((shell / 'common/LevelColumn.qml').exists(), 'a file the new version dropped should be gone')
            self.assertIn('target: "theme"', (shell / 'shell.qml').read_text(), 'an untouched 0.2.0 shell.qml must be replaced')
            # the liveries and the faction faces travel with the shell, not as system fonts
            for style in BUILTIN: self.assertTrue((shell / 'skins' / style / 'Housing.qml').is_file(), style)
            for f in ('Cinzel.ttf', 'Michroma.ttf', 'GrenzeGotisch.ttf', 'OFL-Cinzel.txt'): self.assertTrue((shell / 'assets/fonts' / f).is_file(), f)
            kept = json.loads((conf / 'settings.json').read_text())
            for k in ('rounding', 'layouts', 'lowPower'): self.assertEqual(kept[k], mine[k], k)
            self.assertEqual((conf / 'theme.conf').read_text(), '# mine\nmode = strict\ndarkness = -0.1\n')
            binary = next((d / 'h').rglob('ms-settings'))
            read = json.loads(subprocess.run([sys.executable, str(binary), 'read'], env=env, capture_output=True, text=True).stdout)
            self.assertEqual(read['data']['fxLevel'], 2); self.assertEqual(read['data']['rounding'], 3)          # the old file reads with the new defaults
            themes = next((d / 'h').rglob('ms-theme'))
            listing = json.loads(subprocess.run([sys.executable, str(themes), 'packs'], env=env, capture_output=True, text=True).stdout)
            self.assertEqual(sorted(p['id'] for p in listing['packs'] if p['ok']), sorted(BUILTIN)); self.assertEqual(listing['mode'], 'guarded')
            # a pack of the user's own, then one more update and an uninstall: it is theirs and stays
            own = d / 'd/machinespirit/themes/mine'; own.mkdir(parents=True)
            (own / 'theme.json').write_text(json.dumps(dict(json.loads((shell / 'themes/necrons/theme.json').read_text()), id='mine', name='Mine', wallpapers=[], preview='')))
            run('new', 'update')
            self.assertTrue((own / 'theme.json').is_file())
            listing = json.loads(subprocess.run([sys.executable, str(themes), 'packs'], env=env, capture_output=True, text=True).stdout)
            self.assertIn('mine', [p['id'] for p in listing['packs'] if p['ok']])
            run('new', 'uninstall')
            self.assertTrue((own / 'theme.json').is_file(), 'uninstall removed the user\'s own pack')
            self.assertFalse((shell / 'kits/BarSpan.qml').exists()); self.assertFalse((shell / 'themes/khorne/theme.json').exists())
            doc = subprocess.run([sys.executable, str(d / 'new/MachineSpirit/installer/install.py'), 'doctor'], env=env, capture_output=True, text=True)
            self.assertNotIn('did not finish', doc.stdout)

if __name__ == '__main__': unittest.main()
