pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
Singleton {
    id:root
    property var browsers:[]
    property var choices:({})
    readonly property var changedBrowsers:browsers.filter(b=>b.supported && ["telemetry","studies","crashes","suggestions","prefetch","proxy"].some(k=>!!flags(b.id)[k]!==!!(b.flags||{})[k]))
    readonly property bool dirty:changedBrowsers.length>0
    function discard(){choices={};preview="";error=""}
    property string error:""
    property string status:""
    property string operation:"status"
    property string payload:""
    property string preview:""
    property string pending:""
    property var pendingChanges:[]
    readonly property bool applying:operation==="apply-batch"
    readonly property bool busy:worker.running
    function flags(id){return choices[id]||browsers.find(b=>b.id===id)?.flags||{}}
    function set(id,key,value){const all=Object.assign({},choices);all[id]=Object.assign({},flags(id),{[key]:value});choices=all;preview=""}
    function recommend(){const all=Object.assign({},choices);for(const b of browsers){if(b.supported)all[b.id]=Object.assign({},flags(b.id),{telemetry:true,studies:b.engine==="gecko",crashes:true})}choices=all;preview=""}
    function run(op,value){if(worker.running)return;operation=op;payload=value?JSON.stringify(value):"";if(op!=="status")error="";worker.running=true}
    function failureText(code){
        if(!applying)return "The browser helper failed (code "+code+"). Press Refresh status to try again."
        // pkexec uses 126 and 127 both for a dismissed window and for a refusal, so one message has to cover both.
        if(code===126||code===127)return "Nothing was changed: the password window was cancelled or the password was refused. If you did not cancel it, make sure MachineSpirit was started from your desktop login (not over SSH), then try again."
        return "Applying browser policies failed (code "+code+"). Nothing was reported as changed; press Refresh status to see the current state."
    }
    function inspect(id) {
        if(busy)return
        preview=""
        const ids=id?[id]:changedBrowsers.map(b=>b.id)
        if(!ids.length)return
        if(ids.some(name=>flags(name).proxy)) {
            if(!Privacy.proxyAvailable) {error="The proxy program (GOST) is not installed. Browsers would lose network access, so the proxy policy cannot be applied.";return}
            if(Settings.dirty || !Settings.data.privacy?.proxy?.enabled) {error="Save the proxy settings and enable the proxy connection before reviewing browser proxy policies";return}
        }
        pendingChanges=ids.map(name=>({browser:name,flags:Object.assign({},flags(name))}))
        pending=ids.join(", ")
        run("preview-batch",{changes:pendingChanges})
    }
    function apply(){if(busy||!preview||!pendingChanges.length)return;preview="";Settings.open=false;run("apply-batch",{changes:pendingChanges})}
    Process{id:worker;command:root.applying?["pkexec","/usr/local/libexec/ms-browser-policy","apply-batch"]:["/usr/local/libexec/ms-browser-policy",root.operation];stdinEnabled:true
        onStarted:{if(root.payload)write(root.payload);stdinEnabled=false}
        onExited:(code,status)=>{stdinEnabled=true;if(root.applying){Settings.open=true;refresh.restart()};if(code!==0&&!root.error)root.error=root.failureText(code)}
        stdout:StdioCollector{onStreamFinished:{if(!text.trim())return;try{const r=JSON.parse(text);if(r.error)root.error=r.error;
            if(r.browsers)root.browsers=r.browsers;
            if(root.operation==="preview-batch"&&r.policies)root.preview=JSON.stringify(r.policies,null,2);
            if(root.applying)root.status=r.state||""
        }catch(e){root.error="Browser helper unavailable; install the shell privacy component"}}}}
    Timer{id:refresh;interval:200;onTriggered:root.run("status")}
    Component.onCompleted:refresh.start()
}
