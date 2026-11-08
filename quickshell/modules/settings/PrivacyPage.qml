import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io
import qs.common
import qs.services
ColumnLayout {
    id:root;spacing:14;Layout.minimumWidth:0
    property int stage:-1
    readonly property var p:Settings.draft.privacy||({})
    readonly property var proxy:p.proxy||({})
    property string probePayload:""
    property string result:""
    function probe(kind){if(probeProc.running)return;probePayload=JSON.stringify({kind:kind,manual:true});result="Checking…";probeProc.running=true}
    Process{id:probeProc;command:["ms-net"];stdinEnabled:true;onStarted:{write(root.probePayload);stdinEnabled=false}onExited:stdinEnabled=true
        stdout:StdioCollector{onStreamFinished:{try{const r=JSON.parse(text);root.result=r.error||(r.ip?"Exit IP: "+r.ip:"Request completed")}catch(e){root.result="Request failed"}}}}
    DeckCard{visible:root.stage===-1||root.stage===0;title:"Your machine. Your choice.";subtitle:Privacy.completed?"Nothing changes until you apply. Recommended and Local only also pre-select browser protections; they are applied only after your review in the Browsers section.":"First launch: background network requests are paused until you finish setup. Local instruments already work."
        RowLayout{Layout.fillWidth:true
            DeckButton{text:"Normal";Layout.fillWidth:true;onClicked:Privacy.preset("normal")}
            DeckButton{text:"Recommended";Layout.fillWidth:true;accent:true;onClicked:{Privacy.preset("recommended");BrowserPrivacy.recommend()}}
            DeckButton{text:"Local only";Layout.fillWidth:true;onClicked:{Privacy.preset("local");BrowserPrivacy.recommend()}}
        }
        DeckText{text:"Recommended keeps weather and wallpapers, asks for your city, and makes public-IP and cover searches manual. Local only blocks the shell’s network access, not other applications.";Layout.fillWidth:true;font.pixelSize:12;color:Theme.surfaceVariantOn}
        DeckText{text:"Saved mode: "+(Privacy.policy.mode||"custom")+" · Network: "+(!Privacy.ready?"paused until setup is complete":Privacy.policy.mode==="local"?"blocked":Privacy.policy.proxy?.enabled&&Privacy.policy.proxy?.shell?"through proxy":"direct");Layout.fillWidth:true;color:Theme.glowDim;font.pixelSize:12}
    }
    DeckCard{visible:root.stage===-1||root.stage===1;title:"Network permissions";subtitle:"Each request checks the saved permission, including images and wallpaper thumbnails."
        Repeater{model:[{key:"weather",title:"Weather · wttr.in"},{key:"publicIp",title:"Public IP · ipify"},{key:"coverSearch",title:"Cover search · sends track and artist to iTunes"},{key:"remoteArt",title:"Remote images · player covers and notifications"},{key:"wallpapers",title:"Online wallpaper providers and thumbnails"},{key:"updates",title:"Update checks · GitHub"}]
            RowLayout{required property var modelData;Layout.fillWidth:true
                DeckText{text:modelData.title;Layout.fillWidth:true}
                DeckChoice{model:["Automatic / allowed","On request","Blocked"];currentIndex:Math.max(0,["auto","manual","off"].indexOf(root.p[modelData.key]));onActivated:Privacy.set(modelData.key,["auto","manual","off"][currentIndex])}
            }
        }
        DeckText{visible:root.p.mode==="local";text:"Local mode overrides every network permission above. Select another preset to allow network access.";Layout.fillWidth:true;color:Theme.hazard;font.pixelSize:12}
    }
    DeckCard{visible:root.stage===-1||root.stage===1;title:"Weather location";subtitle:"A city avoids IP-based location. The provider still sees the connection’s exit IP."
        DeckChoice{model:["Choose a city","Locate by exit IP"];currentIndex:root.p.weatherMode==="city"?0:1;onActivated:Privacy.set("weatherMode",currentIndex?"ip":"city")}
        DeckField{visible:root.p.weatherMode==="city";Layout.fillWidth:true;text:root.p.city||"";placeholderText:"City, country · e.g. London, United Kingdom";onTextEdited:Privacy.set("city",text)}
        DeckText{text:"With a proxy, IP location refers to the proxy’s city. City entry performs no background search.";Layout.fillWidth:true;font.pixelSize:12;color:Theme.surfaceVariantOn}
        RowLayout{DeckButton{text:"Refresh weather";enabled:!Settings.dirty&&Privacy.allowed("weather",true);onClicked:Weather.refresh(true)} DeckText{text:Weather.error||(Weather.ready?"Updated: "+new Date(Weather.updatedAt).toLocaleTimeString():"No weather loaded");Layout.fillWidth:true;font.pixelSize:12}}
    }
    DeckCard{visible:root.stage===-1||root.stage===1;title:"Proxy connection";subtitle:"Optional: leave this off unless you already use a proxy or VPN service. If the proxy fails, the shell stays offline instead of silently connecting directly."
        DeckToggle{title:"Enable proxy connection";checked:!!root.proxy.enabled;onChanged:v=>Privacy.proxy("enabled",v)}
        RowLayout{Layout.fillWidth:true
            DeckChoice{Layout.preferredWidth:130;model:["SOCKS5","HTTP","HTTPS"];currentIndex:Math.max(0,["socks5","http","https"].indexOf(root.proxy.scheme));onActivated:Privacy.proxy("scheme",["socks5","http","https"][currentIndex])}
            DeckField{Layout.fillWidth:true;placeholderText:"Proxy hostname or IP";text:root.proxy.host||"";onTextEdited:Privacy.proxy("host",text)}
            DeckField{id:portField;Layout.preferredWidth:90;placeholderText:"Port";text:String(root.proxy.port||1080);validator:IntValidator{bottom:1;top:65535}onTextEdited:if(acceptableInput)Privacy.proxy("port",Number(text))}
        }
        DeckText{visible:!portField.acceptableInput;text:"Port must be a number from 1 to 65535. The previous port is kept until this is fixed.";Layout.fillWidth:true;font.pixelSize:12;color:Theme.hazard}
        DeckField{Layout.fillWidth:true;placeholderText:"Username (optional)";text:root.proxy.username||"";onTextEdited:Privacy.proxy("username",text)}
        RowLayout{Layout.fillWidth:true
            DeckField{id:password;Layout.fillWidth:true;placeholderText:Privacy.hasPassword?"Password saved · enter to replace":"Password (optional)";echoMode:TextInput.Password}
            DeckButton{text:"Save password";onClicked:{if(Privacy.run("password",{password:password.text}))password.clear();else Privacy.error="Another privacy operation is still running. Try again in a moment."}}
            DeckButton{text:"Clear";onClicked:{if(Privacy.run("password",{password:""}))password.clear();else Privacy.error="Another privacy operation is still running. Try again in a moment."}}
        }
        DeckText{text:"Password is saved right away (not with Apply), separately on this device with owner-only permissions. It is not included in the settings export.";font.pixelSize:12;Layout.fillWidth:true;color:Theme.surfaceVariantOn}
        DeckToggle{title:"Route shell requests through proxy";checked:!!root.proxy.shell;onChanged:v=>Privacy.proxy("shell",v)}
        DeckText{text:Privacy.proxyAvailable?"Browser routing is selected separately. Disabling this connection leaves routed browsers offline until their proxy policy is restored. A proxy is not a guarantee of anonymity.":"GOST is missing. Install the shell dependencies before enabling proxy routing.";Layout.fillWidth:true;font.pixelSize:12;color:Privacy.proxyAvailable?Theme.surfaceVariantOn:Theme.hazard}
        RowLayout{DeckButton{text:"Test saved proxy";enabled:!Settings.dirty&&root.p.mode!=="local"&&!!root.proxy.enabled&&Privacy.proxyAvailable;onClicked:root.probe("proxyTest")} DeckText{text:root.result;Layout.fillWidth:true;font.pixelSize:12}}
    }
    DeckCard{visible:root.stage===5;title:"Ready for your desktop";subtitle:"Save your choices and start using MachineSpirit. You can change everything later in Settings."
        DeckText{text:root.p.mode==="local"?"Online features are turned off.":"Only the online features you allowed will connect.";Layout.fillWidth:true;font.pixelSize:17;color:Theme.glow}
        DeckDivider{}
        DeckText{text:"Weather: "+(root.p.mode==="local"||root.p.weather==="off"?"Off":root.p.weatherMode==="city"?(root.p.city||"Choose a city in Network & weather"):"Use network location");Layout.fillWidth:true}
        DeckText{text:"Keyboard: "+(Settings.draft.layouts||[]).join(", ");Layout.fillWidth:true}
        DeckText{text:BrowserPrivacy.dirty?"Some browser changes are not applied yet. You can finish setup now and apply them later in Browsers.":"No unapplied browser changes. Restart open browsers if you changed their policies.";Layout.fillWidth:true;color:BrowserPrivacy.dirty?Theme.hazard:Theme.surfaceVariantOn}
        DeckText{text:"Click Start using MachineSpirit below to finish.";Layout.fillWidth:true;color:Theme.surfaceVariantOn}
    }
    DeckCard{visible:root.stage===-1;title:"On-demand tools"
        RowLayout{Layout.fillWidth:true
            DeckButton{text:"Check public IP";enabled:!Settings.dirty&&Privacy.allowed("publicIp",true);onClicked:Net.refreshPublic()}
            DeckButton{text:"Find track cover";enabled:!Settings.dirty&&Privacy.allowed("coverSearch",true);onClicked:Media.refreshCover()}
        }
        DeckText{text:Net.publicError||(Net.publicIp?"Public IP: "+Net.publicIp:"No external IP lookup requested");Layout.fillWidth:true;font.pixelSize:12;color:Theme.surfaceVariantOn}
        DeckText{text:Privacy.error||Privacy.status;visible:text!=="";Layout.fillWidth:true;color:Privacy.error?Theme.hazard:Theme.glowDim}
        DeckButton{text:"Run setup again";visible:Privacy.completed&&!Privacy.onboarding;onClicked:Privacy.restartSetup()}
    }
}
