// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import Quickshell.Io
import qs.services
Image {
    id:root
    property string requestSource:""
    property string feature:"remoteArt"
    property bool manual:false
    property string localSource:""
    property string payload:""
    source:localSource
    function refresh(){
        transfer.running=false;localSource="";
        if(requestSource.startsWith("https://")){
            if(Privacy.allowed(feature,manual)){payload=JSON.stringify({kind:feature,url:requestSource,manual:manual});transfer.running=true}
        }else if(requestSource.startsWith("file:")||requestSource.startsWith("image:")||requestSource.startsWith("qrc:")||requestSource.startsWith("/"))localSource=requestSource
    }
    onRequestSourceChanged:refresh()
    Connections{target:Privacy;function onPolicyChanged(){root.refresh()}function onReadyChanged(){root.refresh()}}
    Process{id:transfer;command:["ms-net"];stdinEnabled:true;onStarted:{write(root.payload);stdinEnabled=false}onExited:stdinEnabled=true
        stdout:StdioCollector{onStreamFinished:{try{root.localSource=JSON.parse(text).url||""}catch(e){root.localSource=""}}}}
}
