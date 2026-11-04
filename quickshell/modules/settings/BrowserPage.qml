import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.common
import qs.services
ColumnLayout {
    id:page
    property string selectedBrowser:"firefox"
    Layout.minimumWidth:0
    spacing:14
    DeckCard{title:"Browser privacy";subtitle:"Policies affect all profiles of the selected native browser. Updates, certificates and malicious-site protection are preserved."
        RowLayout{DeckButton{text:"Refresh status";enabled:!BrowserPrivacy.busy;onClicked:BrowserPrivacy.run("status")} DeckButton{text:"Recommended choices";onClicked:BrowserPrivacy.recommend()}}
        DeckText{text:BrowserPrivacy.error||BrowserPrivacy.status||"Written policies require a browser restart and verification in about:policies or chrome://policy. Profiles and passwords are never removed.";Layout.fillWidth:true;font.pixelSize:12;color:BrowserPrivacy.error?Theme.hazard:Theme.surfaceVariantOn}
    }
    Repeater{model:BrowserPrivacy.browsers
        DeckCard{
            id:browser;required property var modelData
            title:modelData.id;subtitle:modelData.state
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
                RowLayout{DeckButton{text:"Preview changes";enabled:!BrowserPrivacy.busy&&(!browser.flags.proxy||(!Settings.dirty&&Settings.data.privacy?.proxy?.enabled));onClicked:BrowserPrivacy.inspect(browser.modelData.id)}
                    DeckButton{text:"Restore previous";enabled:!BrowserPrivacy.busy;onClicked:{for(const k of ["telemetry","studies","crashes","suggestions","prefetch","proxy"])BrowserPrivacy.set(browser.modelData.id,k,false);BrowserPrivacy.inspect(browser.modelData.id)}}}
            }
        }
    }
    DeckCard{visible:BrowserPrivacy.preview!=="";title:"Review · "+BrowserPrivacy.pending;subtitle:"Only the following policies will be managed. Existing conflicting policies are preserved. Apply authorizes this selection together. Authorization is remembered briefly."
        DeckText{text:BrowserPrivacy.preview;Layout.fillWidth:true;font.family:Theme.fontMono;font.pixelSize:11}
        RowLayout{DeckButton{text:"Apply browser policies";accent:true;enabled:!BrowserPrivacy.busy;onClicked:BrowserPrivacy.apply()} DeckButton{text:"Cancel";onClicked:BrowserPrivacy.preview=""}}
    }
}
