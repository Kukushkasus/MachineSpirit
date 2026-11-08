// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.common
import qs.services

ColumnLayout {
    id:page
    Layout.minimumWidth:0
    spacing:14
    function when(ts){return ts>0?"Checked "+new Date(ts*1000).toLocaleString(Qt.locale(),"d MMM, HH:mm"):"Not checked yet"}

    DeckCard{title:"MachineSpirit";subtitle:"The shell itself: panels, settings and themes. An update downloads a published release, checks it against the release's checksums (this catches damaged downloads; releases are not signed), shows what is new and asks before it installs. Your files are backed up first."
        RowLayout{Layout.fillWidth:true;spacing:14
            // The cog is the machine's pulse: it ticks while a new version waits and rests when you are current.
            Rectangle{
                implicitWidth:64;implicitHeight:64;radius:10;clip:true
                color:Qt.alpha(Theme.glass,0.7);border.color:Qt.alpha(Updates.newer?Theme.glow:Theme.outlineVariant,0.9)
                Gear{anchors.centerIn:parent;width:40;height:40;outline:true;filled:false;teeth:10;spin:Updates.newer;opacity:Updates.newer?1:0.55
                    hole:Qt.alpha(Theme.glass,0.7)}
                Lamp{anchors.right:parent.right;anchors.top:parent.top;anchors.margins:1;size:6;lit:Updates.newer}
            }
            ColumnLayout{Layout.fillWidth:true;spacing:2
                DeckText{Layout.fillWidth:true;font.pixelSize:20;font.weight:Font.DemiBold
                    text:Updates.newer?"Version "+Updates.latest+" is available":Updates.latest!==""?"You have the latest version":"Ready to check for updates"}
                DeckText{Layout.fillWidth:true;font.pixelSize:12;color:Theme.surfaceVariantOn
                    text:"Installed "+(Updates.installed||"version unknown")+" · "+page.when(Updates.checkedAt)}
            }
            DeckButton{text:"↻";implicitWidth:44;enabled:!Updates.busy&&Updates.allowed;onClicked:Updates.check()
                ToolTip.visible:hovered;ToolTip.text:"Check for a new release"}
        }
        DeckText{visible:Updates.newer&&Updates.notes!=="";Layout.fillWidth:true;font.pixelSize:12;color:Theme.surfaceVariantOn;text:Updates.notes.split("\n").slice(0,6).join("\n")}
        DeckButton{text:"Update dots";accent:Updates.newer;enabled:!Updates.busy&&Updates.terminal!==""&&Updates.newer;onClicked:Updates.update()}
        DeckText{visible:Updates.terminal===""&&Updates.newer;Layout.fillWidth:true;font.pixelSize:12;color:Theme.hazard
            text:"No terminal program was found (kitty, foot, alacritty, konsole or xterm). Install one, or run ms-update install in any console."}
        DeckText{Layout.fillWidth:true;font.pixelSize:12;color:Theme.surfaceVariantOn
            text:"No internet or no access to GitHub? Download a release archive and its SHA256SUMS file, then run: ms-update install --from-file MachineSpirit-<version>.tar.gz"}
    }

    DeckText{Layout.fillWidth:true;font.pixelSize:12;color:Updates.error?Theme.hazard:Theme.surfaceVariantOn
        text:Updates.error||Updates.status||(Updates.allowed?"Nothing is checked by itself: a request is sent only when you press the refresh button.":"Update checks are off. Allow them under Privacy, Network permissions.")}
}
