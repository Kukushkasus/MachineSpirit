#!/usr/bin/env python3
# [ PURITY SEAL ] Keep a return path before changing the dawn.
import json, os, re, shutil, subprocess, sys, time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
BACKUP=Path('/var/lib/machinespirit/boot')
def check():
    if not Path('/etc/default/grub').exists() or not Path('/boot/grub/grub.cfg').exists(): raise ValueError('Boot component currently supports GRUB + mkinitcpio only; omit boot on this system.')
    p=Path('/etc/mkinitcpio.conf')
    if not p.exists() or not re.search(r'^HOOKS=\([^)]*\b(?:systemd|udev)\b',p.read_text(),re.M): raise ValueError('Unsupported mkinitcpio HOOKS syntax; omit boot on this system.')
    if Path('/etc/systemd/system/display-manager.service').exists(): raise ValueError('Existing display manager is preserved. Omit boot; installing a login theme is not supported with a display manager.')
    print('Boot: GRUB + mkinitcpio + existing Plymouth supported')
def main():
    cmd=sys.argv[1]
    if cmd=='check': check(); return
    if os.geteuid()!=0: raise ValueError('System boot installation needs sudo')
    if cmd=='restore':
        tx=BACKUP/sys.argv[2]
        if tx.parent != BACKUP: raise ValueError('Invalid backup ID')
        current=BACKUP/('before-restore-'+time.strftime('%Y%m%d-%H%M%S'));current.mkdir(parents=True,mode=0o700)
        saved={}
        try:
            for index,(name,original) in enumerate(json.loads((tx/'files.json').read_text()).items()):
                p=Path(name)
                if p.exists(): shutil.copy2(p,current/str(index)); saved[name]=index
                else: saved[name]=None
                if original is None: p.unlink(missing_ok=True)
                else: shutil.copy2(tx/original,p)
        except BaseException:
            # Undo a half-finished restore so GRUB, initramfs and Plymouth stay consistent.
            for name,index in saved.items():
                if index is None: Path(name).unlink(missing_ok=True)
                else: shutil.copy2(current/str(index),name)
            raise
    elif cmd=='install':
        check(); tx=BACKUP/time.strftime('%Y%m%d-%H%M%S'); tx.mkdir(parents=True,mode=0o700)
        files={}
        def write(path,text):
            p=Path(path); p.parent.mkdir(parents=True,exist_ok=True)
            n=str(len(files))
            if p.exists(): shutil.copy2(p,tx/n); files[str(p)]=n
            else: files[str(p)]=None
            (tx/'files.json').write_text(json.dumps(files,indent=2)); p.write_text(text)
        try:
            # Keep generated boot artifacts too, so a failed regeneration can be undone.
            for artifact in [Path('/boot/grub/grub.cfg'), *Path('/boot').glob('initramfs-*.img')]:
                name='artifact-'+str(len(files)); shutil.copy2(artifact,tx/name); files[str(artifact)]=name
            (tx/'files.json').write_text(json.dumps(files,indent=2))
            for p in (ROOT/'assets/plymouth').iterdir(): write('/usr/share/plymouth/themes/machinespirit/'+p.name,p.read_text())
            hooks=Path('/etc/mkinitcpio.conf').read_text()
            match=re.search(r'^HOOKS=\(([^)]*)\)',hooks,re.M)
            if 'plymouth' not in match[1].split():
                entries=match[1].split(); anchor='kms' if 'kms' in entries else ('systemd' if 'systemd' in entries else 'udev')
                entries.insert(entries.index(anchor)+1,'plymouth')
                hooks=hooks[:match.start()]+'HOOKS=('+' '.join(entries)+')'+hooks[match.end():]
                write('/etc/mkinitcpio.conf',hooks)
            write('/etc/plymouth/plymouthd.conf','[Daemon]\nTheme=machinespirit\nShowDelay=0\n')
            p=Path('/etc/default/grub'); s=p.read_text()
            match=re.search(r'^GRUB_CMDLINE_LINUX_DEFAULT=([\'"])(.*?)\1',s,re.M)
            if not match: raise ValueError('Cannot parse GRUB command line; original preserved')
            args=match[2].split()
            for arg in ['quiet','splash','vt.global_cursor_default=0']:
                if arg not in args: args.append(arg)
            s=s[:match.start()]+"GRUB_CMDLINE_LINUX_DEFAULT='"+' '.join(args)+"'"+s[match.end():]
            write(p,s)
            p=Path('/etc/systemd/system/getty@tty1.service.d/autologin.conf')
            if p.exists() and '--autologin' in p.read_text():
                s=p.read_text()
                if '--noissue' not in s: s=s.replace('--autologin','--noissue --nohostname --skip-login --autologin')
                write(p,s)
            subprocess.run(['mkinitcpio','-P'],check=True)
            subprocess.run(['grub-mkconfig','-o','/boot/grub/grub.cfg'],check=True)
            subprocess.run(['systemctl','daemon-reload'],check=True)
            print('Boot backup:',tx.name)
            return
        except BaseException:
            for name,original in files.items():
                if original is None: Path(name).unlink(missing_ok=True)
                else: shutil.copy2(tx/original,name)
            raise
    else: raise ValueError('Use check, install or restore ID')
    subprocess.run(['mkinitcpio','-P'],check=True)
    subprocess.run(['grub-mkconfig','-o','/boot/grub/grub.cfg'],check=True)
    subprocess.run(['systemctl','daemon-reload'],check=True)
if __name__=='__main__':
    try: main()
    except (ValueError,OSError,subprocess.CalledProcessError) as e: sys.exit(str(e))
