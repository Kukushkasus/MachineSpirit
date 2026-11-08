import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.common
import qs.services
ColumnLayout {
    id:page
    property string selectedBrowser:"firefox"
    readonly property var names:({firefox:"Firefox",chrome:"Google Chrome",chromium:"Chromium",librewolf:"LibreWolf",zen:"Zen Browser"})
    function label(id){return names[id]||id}
    readonly property var missing:BrowserPrivacy.browsers.filter(b=>!b.installed).map(b=>label(b.id))
    Layout.minimumWidth:0
    spacing:14
    DeckCard{title:"Browser privacy";subtitle:"Turn off tracking features inside your browsers. It works in three steps: 1. choose protections, 2. review exactly what will be written, 3. confirm with your password. Changes take effect after the browser restarts, and your profiles, passwords and updates are never touched."
        RowLayout{DeckButton{text:"Refresh status";enabled:!BrowserPrivacy.busy;onClicked:BrowserPrivacy.run("status")} DeckButton{text:"Select recommended protections";onClicked:BrowserPrivacy.recommend()}}
        DeckText{text:BrowserPrivacy.error||BrowserPrivacy.status||(BrowserPrivacy.dirty?"Step 1 done. Press \"Review browser changes\" at the bottom to continue.":"Nothing selected yet. Open a browser below and switch on the protections you want, or use the recommended set. To check a result afterwards, open about:policies (Firefox) or chrome://policy.");Layout.fillWidth:true;font.pixelSize:12;color:BrowserPrivacy.error?Theme.hazard:Theme.surfaceVariantOn}
    }
    DeckText{visible:BrowserPrivacy.browsers.length>0&&BrowserPrivacy.browsers.every(b=>!b.installed);text:"No supported browser was found. Install Firefox, Chromium, Chrome, LibreWolf or Zen and press Refresh status.";Layout.fillWidth:true;color:Theme.hazard;font.pixelSize:13}
    Repeater{model:BrowserPrivacy.browsers.filter(b=>b.installed)
        DeckCard{
            id:browser;required property var modelData
            title:page.label(modelData.id);subtitle:modelData.state
            readonly property var flags:BrowserPrivacy.flags(modelData.id)
            DeckText{visible:!!browser.modelData.note;text:browser.modelData.note||"";Layout.fillWidth:true;font.pixelSize:12;color:Theme.surfaceVariantOn}
            DeckButton{visible:browser.modelData.supported;text:page.selectedBrowser===browser.modelData.id?"Collapse":"Configure";onClicked:page.selectedBrowser=page.selectedBrowser===browser.modelData.id?"":browser.modelData.id}
            ColumnLayout{visible:browser.modelData.supported&&page.selectedBrowser===browser.modelData.id;
                onVisibleChanged:if(visible) reveal.restart()
                NumberAnimation { id:reveal;target:parent;property:"opacity";from:0;to:1;duration:Theme.dMedium }
Layout.fillWidth:true;spacing:10
                Repeater{model:[{key:"telemetry",name:"Block usage telemetry"},{key:"studies",name:"Block Firefox studies"},{key:"crashes",name:"Block automatic crash uploads"},{key:"suggestions",name:"Disable online search suggestions"},{key:"prefetch",name:"Disable speculative loading"},{key:"proxy",name:"Use the configured proxy"}]
                    DeckToggle{required property var modelData;visible:modelData.key!=="studies"||browser.modelData.engine==="gecko";property bool nativeBlock:(browser.modelData.id==="zen"||browser.modelData.id==="librewolf")&&["telemetry","studies"].includes(modelData.key)&&!!browser.modelData.observed?.[modelData.key]
                    enabled:!nativeBlock;title:modelData.name;hint:nativeBlock?"Already blocked by this browser's policy":browser.modelData.observed?.[modelData.key]?"Blocking policy found; runtime verification after restart":"";checked:nativeBlock||!!browser.flags[modelData.key];onChanged:v=>BrowserPrivacy.set(browser.modelData.id,modelData.key,v)}
                }
                DeckText{visible:!!browser.flags.proxy;text:"Proxy mode also restricts direct DNS, QUIC and WebRTC paths. Calls may be affected. Apply the shell proxy settings first; a stopped proxy blocks browser access.";Layout.fillWidth:true;font.pixelSize:12;color:Theme.hazard}
                DeckText{visible:browser.modelData.engine==="chromium";text:"Chrome/Chromium share one metrics policy for usage and crashes. Either blocking switch disables both.";Layout.fillWidth:true;font.pixelSize:12;color:Theme.surfaceVariantOn}
                RowLayout{DeckButton{text:"Preview changes";enabled:!BrowserPrivacy.busy&&(!browser.flags.proxy||(!Settings.dirty&&Settings.data.privacy?.proxy?.enabled&&Privacy.proxyAvailable));onClicked:BrowserPrivacy.inspect(browser.modelData.id)}
                    DeckButton{text:"Restore previous";enabled:!BrowserPrivacy.busy;onClicked:{for(const k of ["telemetry","studies","crashes","suggestions","prefetch","proxy"])BrowserPrivacy.set(browser.modelData.id,k,false);BrowserPrivacy.inspect(browser.modelData.id)}}}
            }
        }
    }
    DeckText{visible:page.missing.length>0&&BrowserPrivacy.browsers.some(b=>b.installed);text:"Not installed, so nothing to configure: "+page.missing.join(", ")+".";Layout.fillWidth:true;font.pixelSize:12;color:Theme.surfaceVariantOn}
    DeckCard{visible:BrowserPrivacy.preview!=="";title:"Step 2 of 3 · Review "+BrowserPrivacy.pending.split(", ").map(page.label).join(", ");subtitle:"Only the policies listed below will be written. Policies set by someone else are left alone. Next, a system window asks for your password; if it does not appear, sign in to the desktop again and retry."
        DeckText{text:BrowserPrivacy.preview;Layout.fillWidth:true;font.family:Theme.fontMono;font.pixelSize:11}
        RowLayout{DeckButton{text:"Step 3 · Apply with my password";accent:true;enabled:!BrowserPrivacy.busy;onClicked:BrowserPrivacy.apply()} DeckButton{text:"Cancel";onClicked:BrowserPrivacy.preview=""}}
    }
}
