// SPDX-License-Identifier: GPL-3.0-only
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Update state for the Updates page. Nothing is fetched until a button is pressed.
Singleton {
    id:root
    property string installed:""
    property string latest:""
    property string notes:""
    property bool newer:false
    property double checkedAt:0
    property string terminal:""
    property string error:""
    property string status:""
    property var args:["status"]
    readonly property bool busy:worker.running
    readonly property bool allowed:Privacy.allowed("updates",true)
    function run(a){if(worker.running)return false;error="";status="";args=a;worker.running=true;return true}
    function refresh(){return run(["status"])}
    function check(){return run(["check"])}
    // The installer talks to you in a terminal, which would open under the settings panel: close the panel first.
    function update(){Settings.open=false;return run(["launch"])}
    Process{
        id:worker;command:["ms-update",...root.args]
        onExited:(code,s)=>{if(code!==0&&!root.error)root.error="The update helper failed. Open a terminal and run ms-update status."}
        stdout:StdioCollector{onStreamFinished:{
            if(!text.trim())return
            try{
                const r=JSON.parse(text)
                if(r.error){root.error=r.error;return}
                if(r.launched){root.status="Update window opened. Follow the steps there.";return}
                root.installed=r.installed||"";root.latest=r.latest||"";root.notes=r.notes||"";root.newer=!!r.newer;root.checkedAt=r.checked||0;root.terminal=r.terminal||""
            }catch(e){root.error="Could not read the update helper's answer"}
        }}
    }
    Component.onCompleted:refresh()
}
