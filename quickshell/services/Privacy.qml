pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
Singleton {
    id: root
    signal setupFinished()
    readonly property bool busy: worker.running
    property bool loaded: false
    property bool completed: false
    property bool onboarding: false
    property bool proxyAvailable: false
    property bool hasPassword: false
    property string error: ""
    property string status: ""
    property string operation: "status"
    property string payload: ""
    readonly property var policy: Settings.data.privacy || ({})
    readonly property bool ready: loaded && completed && Settings.initialized
    function allowed(feature, manual) { return ready && policy.mode !== "local" && (policy[feature] === "auto" || (manual && policy[feature] === "manual")) }
    function run(op, value) { if (worker.running) return false; operation=op;payload=value?JSON.stringify(value):"";error="";worker.running=true; return true }
    function completeSetup() { completion.restart() }
    Timer { id:completion; interval:100; onTriggered:{if(worker.running){restart();return}root.run("complete")} }
    // Skip: safe defaults that need no input. Network lookups that need a choice from the user stay off.
    function skipSetup() {
        preset("recommended")
        const p=Settings.clone(Settings.draft.privacy||{});p.weather="off";p.weatherMode="ip";p.publicIp="off";Settings.set("privacy",p)
        Settings.finishSetup()
    }
    function restartSetup() { onboarding=true;Settings.open=true;Settings.manual=false }
    function preset(name) {
        const p=Settings.clone(Settings.draft.privacy || {});
        p.mode=name;
        for (const k of ["weather","publicIp","coverSearch","remoteArt","wallpapers"]) p[k]=name==="local"?"off":"auto";
        p.updates=name==="local"?"off":"manual";
        if(name==="recommended") {p.publicIp="manual";p.coverSearch="manual";p.weatherMode="city"}
        if(name==="normal") p.weatherMode="ip";
        Settings.set("privacy",p)
    }
    function set(key,value) { const p=Settings.clone(Settings.draft.privacy||{});p[key]=value;Settings.set("privacy",p) }
    function proxy(key,value) { const p=Settings.clone(Settings.draft.privacy||{});p.proxy=Object.assign({},p.proxy||{}, {[key]:value});Settings.set("privacy",p) }
    Process {
        id:worker;running:true;command:["ms-privacy",root.operation];stdinEnabled:true
        onStarted:{if(root.payload)write(root.payload);root.payload="";stdinEnabled=false}
        onExited:(code,status)=>{stdinEnabled=true;if(code!==0&&!root.error)root.error="Could not save setup. Please try again."}
        stdout:StdioCollector{onStreamFinished:{try{
            const r=JSON.parse(text);if(r.error){root.error=r.error;return}
            if(r.completed!==undefined)root.completed=r.completed;
            if(r.proxyAvailable!==undefined)root.proxyAvailable=r.proxyAvailable;
            if(r.hasPassword!==undefined)root.hasPassword=r.hasPassword;
            if(!root.loaded){root.loaded=true;if(!root.completed)root.restartSetup()}
            if(root.operation==="complete"){root.onboarding=false;root.status="Setup complete";root.setupFinished()}
            if(root.operation==="password"){root.hasPassword=!!JSON.parse(root.payload).password;root.status="Proxy credentials saved"}
        }catch(e){root.error="Could not read privacy status"}}}
    }
    Timer{interval:1000;running:root.loaded&&!Settings.initialized&&Settings.error==="";repeat:true;onTriggered:if(!root.completed)Settings.open=true}
}
