# SPDX-License-Identifier: GPL-3.0-only
"""Shared privacy settings. No network activity on import."""
import copy, ctypes, hashlib, json, os, re, shutil, signal, subprocess, tempfile, time, urllib.parse
from pathlib import Path
CONF=Path(os.environ.get('XDG_CONFIG_HOME',Path.home()/'.config'))/'machinespirit'
STATE=Path(os.environ.get('XDG_STATE_HOME',Path.home()/'.local/state'))/'machinespirit'
CACHE=Path(os.environ.get('XDG_CACHE_HOME',Path.home()/'.cache'))/'machinespirit/private-network'
RUNTIME=Path(os.environ.get('XDG_RUNTIME_DIR',f'/run/user/{os.getuid()}'))/'machinespirit-privacy'
FEATURES=('weather','publicIp','coverSearch','remoteArt','wallpapers','updates')
DEFAULT={'mode':'custom','weather':'auto','publicIp':'auto','coverSearch':'auto','remoteArt':'auto','wallpapers':'auto','updates':'manual',
         'weatherMode':'ip','city':'','proxy':{'enabled':False,'scheme':'socks5','host':'','port':1080,'username':'','shell':False}}

if os.environ.get('MS_WEATHER_LOCATION'):
    DEFAULT['city']=os.environ['MS_WEATHER_LOCATION']
    DEFAULT['weatherMode']='city'

def atomic(path,value,mode=0o600):
    path.parent.mkdir(parents=True,exist_ok=True)
    fd,tmp=tempfile.mkstemp(dir=path.parent)
    try:
        with os.fdopen(fd,'w') as f: f.write(value);f.flush();os.fsync(f.fileno())
        os.chmod(tmp,mode);os.replace(tmp,path)
    finally:
        if os.path.exists(tmp): os.unlink(tmp)

def validate(value):
    if not isinstance(value,dict): raise ValueError('privacy must be an object')
    p=copy.deepcopy(DEFAULT);p.update(value)
    if p['mode'] not in ('custom','normal','recommended','local'): raise ValueError('Invalid privacy preset')
    for k in FEATURES:
        if p[k] not in ('auto','manual','off'): raise ValueError('Invalid network permission: '+k)
    if p['weatherMode'] not in ('city','ip'): raise ValueError('Invalid weather mode')
    if not isinstance(p['city'],str) or len(p['city'])>120 or any(ord(c)<32 for c in p['city']): raise ValueError('Invalid city')
    if not isinstance(p['proxy'],dict): raise ValueError('Invalid proxy')
    x={**DEFAULT['proxy'],**p['proxy']};p['proxy']=x
    if any(type(x[k]) is not bool for k in ('enabled','shell')): raise ValueError('Invalid proxy switches')
    if x['scheme'] not in ('http','https','socks5'): raise ValueError('Choose HTTP, HTTPS or SOCKS5')
    if not isinstance(x['host'],str) or len(x['host'])>253 or (x['host'] and not re.fullmatch(r'[A-Za-z0-9.:-]+',x['host'])): raise ValueError('Enter a proxy hostname or IP, without a URL')
    if type(x['port']) is not int or not 1<=x['port']<=65535: raise ValueError('Invalid proxy port')
    if not isinstance(x['username'],str) or len(x['username'])>256 or any(ord(c)<32 for c in x['username']): raise ValueError('Invalid proxy username')
    if x['enabled'] and not x['host']: raise ValueError('Proxy host is required')
    return p

def read():
    try: return validate(json.loads((CONF/'settings.json').read_text()).get('privacy',{}))
    except FileNotFoundError: return copy.deepcopy(DEFAULT)

def completed():
    try: return json.loads((STATE/'onboarding.json').read_text()).get('version')==1
    except (FileNotFoundError,ValueError): return False

def allowed(feature,manual=False):
    if feature=='proxyTest': return manual and read()['mode']!='local'
    if feature not in FEATURES: raise ValueError('Unknown network feature')
    p=read()
    return completed() and p['mode']!='local' and (p[feature]=='auto' or (manual and p[feature]=='manual'))

def proxy_endpoint():
    # Fixed loopback listener: no PAC/DIRECT fallback, no proxy credentials in browser policies.
    return 'http://127.0.0.1:17879'

def prune_cache(limit=200,max_age=7*86400):
    """Remove old remote images and leftovers of interrupted downloads from the private cache."""
    now=time.time();files=[]
    for f in CACHE.glob('*'):
        try: st=f.stat()
        except OSError: continue
        if f.suffix!='.img' and now-st.st_mtime>3600 or f.suffix=='.img' and now-st.st_mtime>max_age: f.unlink(missing_ok=True)
        elif f.suffix=='.img': files.append((st.st_mtime,f))
    for _,f in sorted(files,reverse=True)[limit:]: f.unlink(missing_ok=True)

def fetch(feature,url,manual=False,headers=None,image=False,force_proxy=False):
    if not allowed(feature,manual): raise ValueError('Network access disabled in Privacy settings')
    u=urllib.parse.urlsplit(url)
    if u.scheme!='https' or not u.hostname or u.username or u.password: raise ValueError('Only HTTPS network resources are allowed')
    p=read();via=force_proxy or (p['proxy']['enabled'] and p['proxy']['shell'])
    if force_proxy and not p['proxy']['enabled']: raise ValueError('Enable and apply a proxy first')
    # curl config travels over stdin, never argv; no environment proxy/bypass inheritance.
    env={k:v for k,v in os.environ.items() if k.lower() not in ('http_proxy','https_proxy','all_proxy','no_proxy')}
    opts={'url':url,'proxy':proxy_endpoint() if via else '', 'noproxy':''}
    config=''.join(k+' = '+json.dumps(v)+'\n' for k,v in opts.items())
    for k,v in (headers or {}).items():
        if '\n' in k+v or '\r' in k+v: raise ValueError('Invalid request header')
        config+='header = '+json.dumps(k+': '+v)+'\n'
    CACHE.mkdir(parents=True,exist_ok=True)
    fd,tmp=tempfile.mkstemp(dir=CACHE);os.close(fd)
    proc=None
    try:
        # curl must die with us (settings change, panel closed, process killed). `setpriv` sets that up before exec, which keeps
        # fetch() safe to call from several threads; `preexec_fn` is not, so it is only the fallback.
        guard=['setpriv','--pdeathsig','TERM'] if shutil.which('setpriv') else []
        extra={} if guard else {'preexec_fn':lambda:ctypes.CDLL(None).prctl(1,signal.SIGTERM)}
        proc=subprocess.Popen([*guard,'curl','--disable','--config','-','--silent','--show-error','--fail','--location','--proto','=https','--proto-redir','=https',
            '--connect-timeout','8','--max-time','45','--max-filesize','20971520','--output',tmp],stdin=subprocess.PIPE,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,env=env,**extra)
        proc.stdin.write(config.encode());proc.stdin.close()
        while proc.poll() is None:
            time.sleep(.1)
            if not allowed(feature,manual) or read()!=p:
                proc.terminate();proc.wait();raise ValueError('Request cancelled: privacy settings changed')
        if proc.returncode: raise ValueError('Proxy or service unavailable' if via else 'Service unavailable')
        if not allowed(feature,manual) or read()!=p: raise ValueError('Request cancelled')
        if image:
            data=Path(tmp).read_bytes()[:16]
            if not (data.startswith(b'\x89PNG\r\n') or data.startswith(b'\xff\xd8\xff') or data.startswith(b'GIF8') or (data[:4]==b'RIFF' and data[8:12]==b'WEBP')):
                raise ValueError('Unsupported remote image; expected PNG, JPEG, GIF or WebP')
            dest=CACHE/(hashlib.sha256(url.encode()).hexdigest()+'.img');os.replace(tmp,dest);prune_cache();return dest.as_uri()
        return Path(tmp).read_text()
    finally:
        if proc is not None and proc.poll() is None: proc.terminate();proc.wait()
        Path(tmp).unlink(missing_ok=True)
