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
    function inspect(id) {
        if(busy)return
        preview=""
        const ids=id?[id]:changedBrowsers.map(b=>b.id)
        if(!ids.length)return
        if(ids.some(name=>flags(name).proxy) && (Settings.dirty || !Settings.data.privacy?.proxy?.enabled)) {
            error="Save and enable the shell proxy before reviewing browser proxy policies";return
        }
        pendingChanges=ids.map(name=>({browser:name,flags:Object.assign({},flags(name))}))
        pending=ids.join(", ")
        run("preview-batch",{changes:pendingChanges})
    }
    function apply(){if(busy||!preview||!pendingChanges.length)return;preview="";Settings.open=false;run("apply-batch",{changes:pendingChanges})}
    Process{id:worker;command:root.applying?["pkexec","/usr/local/libexec/ms-browser-policy","apply-batch"]:["/usr/local/libexec/ms-browser-policy",root.operation];stdinEnabled:true
        onStarted:{if(root.payload)write(root.payload);stdinEnabled=false}
        onExited:(code,status)=>{stdinEnabled=true;if(root.applying){Settings.open=true;refresh.restart()};if(code!==0&&!root.error)root.error="Browser operation failed or authorization was cancelled"}
        stdout:StdioCollector{onStreamFinished:{if(!text.trim())return;try{const r=JSON.parse(text);if(r.error)root.error=r.error;
            if(r.browsers)root.browsers=r.browsers;
            if(root.operation==="preview-batch"&&r.policies)root.preview=JSON.stringify(r.policies,null,2);
            if(root.applying)root.status=r.state||""
        }catch(e){root.error="Browser helper unavailable; install the shell privacy component"}}}}
    Timer{id:refresh;interval:200;onTriggered:root.run("status")}
    Component.onCompleted:refresh.start()
}
