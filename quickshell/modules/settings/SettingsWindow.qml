// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.common
import qs.services

Variants {
    model: Quickshell.screens
    PanelWindow {
        id: win
        required property var modelData
        screen: modelData
        readonly property bool mine: Settings.open && (Settings.primary()?.name ?? "") === modelData.name
        readonly property var d: Settings.draft
        property int page: 0
        property int setupStep: 0
        property bool setupDone: false
        readonly property bool finalStep: Privacy.onboarding && setupStep === 5
        readonly property var setupPages: [6,6,7,0,2,6]
        readonly property var setupTitles: ["Welcome & privacy", "Network & weather", "Browsers", "Appearance & devices", "Keyboard & controls", "Review & finish"]
        property string query: ""
        property string shortcutQuery: ""
        property string captureOriginal: ""
        property string captureLabel: ""
        property string captured: ""
        property bool recording: false
        readonly property var pages: [
            {name:"Appearance", icon:"tune", tag:"FORM & FINISH", detail:"Shape your workspace. Keep the machinery yours."},
            {name:"Displays", icon:"desktop_windows", tag:"DISPLAY ARRAY", detail:"Arrange outputs and preview changes before keeping them."},
            {name:"Keyboard", icon:"keyboard", tag:"INPUT / KEYS", detail:"Your languages, your rhythm."},
            {name:"Pointer", icon:"mouse", tag:"INPUT / MOTION", detail:"Fine control for your mouse and touchpad."},
            {name:"Session", icon:"shield", tag:"WATCH & REST", detail:"A quieter machine. A secure workspace."},
            {name:"Shortcuts", icon:"keyboard_command_key", tag:"INSTRUMENT MANUAL", detail:"Find an action. Give it a combination you remember."},
            {name:"Privacy",icon:"shield_lock",tag:"YOUR DATA / YOUR CHOICE",detail:"Choose what connects, what is shared, and how requests travel."},
            {name:"Browsers",icon:"language",tag:"BROWSER POLICIES",detail:"Review supported controls before applying changes."},
            {name:"Updates",icon:"update",tag:"UPKEEP / RITES",detail:"Keep MachineSpirit current. Nothing is checked until you ask."}
        ]
        readonly property var searchItems: [
            {title:"Privacy, proxy & setup",hint:"telemetry offline city weather network",page:6},
            {title:"Browser privacy",hint:"firefox chrome chromium librewolf zen telemetry",page:7},
            {title:"Updates",hint:"update upgrade dots release version check",page:8},
            {title:"Window shape & spacing", hint:"rounding corners gaps borders", page:0},
            {title:"Effects & shadows", hint:"blur dim transparency", page:0},
            {title:"Wallpaper & desktop instruments", hint:"background widgets colors", page:0},
            {title:"Display arrangement", hint:"monitor resolution scale rotation primary", page:1},
            {title:"Keyboard languages", hint:"layout English Russian switching", page:2},
            {title:"Key repeat", hint:"keyboard speed delay typing", page:2},
            {title:"Pointer speed", hint:"mouse sensitivity acceleration left handed focus", page:3},
            {title:"Touchpad gestures", hint:"natural scrolling tap click", page:3},
            {title:"Idle & locking", hint:"sleep timeout minutes screen off", page:4},
            {title:"Motion & power", hint:"animations low power reduce effects", page:4},
            {title:"Keyboard shortcuts", hint:"bindings remap keys hotkeys", page:5}
        ]
        visible: mine || frame.opacity > 0.01
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.namespace: "machinespirit-settings"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: mine ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        ShortcutInhibitor { window: win; enabled: win.mine && win.captureOriginal !== "" }
        onMineChanged: if (mine) { page = Settings.manual ? 5 : page; query = ""; focus.forceActiveFocus() }
        Connections {target:Privacy;function onSetupFinished(){win.setupDone=true;successIn.restart()} function onOnboardingChanged(){if(Privacy.onboarding){win.setupDone=false;win.setupStep=0;win.go(6);Settings.open=true}}}
        Connections{target:BrowserPrivacy;function onPreviewChanged(){if(BrowserPrivacy.preview!==""&&win.page===7)reviewScroll.restart()}}
        Timer { id: reviewScroll; interval: 100; onTriggered: scroll.contentItem.contentY = Math.max(0, scroll.contentItem.contentHeight - scroll.contentItem.height) }
        Component.onCompleted:if(Privacy.onboarding){page=6;Settings.open=true}
        Connections { target: Settings; function onManualChanged() { if (Settings.manual) win.page = 5 } }
        function go(index) { if(index===6)Privacy.run("status"); if(index===8)Updates.refresh(); if (index === 1) Settings.refreshDevices(); page = index; pageFade.restart(); query = ""; search.text = ""; scroll.contentItem.contentY = 0 }
        function applyChanges() {
            if (Settings.countdown > 0) Settings.run("confirm")
            else if (Settings.dirty) Settings.run("write", Settings.draft)
            else if (BrowserPrivacy.preview !== "") BrowserPrivacy.apply()
            else if (BrowserPrivacy.dirty) { go(7); BrowserPrivacy.inspect() }
        }
        ParallelAnimation { id: pageFade
            NumberAnimation { target: scroll; property: "opacity"; from: 0; to: 1; duration: Theme.dMedium; easing.type: Easing.OutCubic }
            NumberAnimation { target: scroll; property: "scale"; from: 0.985; to: 1; duration: Theme.dLong; easing.type: Easing.OutCubic }
        }
        ParallelAnimation { id: successIn
            NumberAnimation { target: success; property: "opacity"; from: 0; to: 1; duration: Theme.dLong }
            NumberAnimation { target: success; property: "scale"; from: 0.96; to: 1; duration: Theme.dLong; easing.type: Easing.OutCubic }
        }
        function resetPage() {
            const groups = [["rounding","gapsIn","gapsOut","borderSize","blur","shadows","dimInactive","dimStrength"],[],["layouts","layoutSwitch","repeatRate","repeatDelay"],["sensitivity","accelProfile","leftHanded","followMouse","naturalScroll","tapToClick"],["lockSeconds","screenOffSeconds","lowPower","reducedMotion"],[]]
            const patch = {}; groups[page].forEach(k => patch[k] = Settings.defaults[k]); Settings.patch(patch)
        }
        function remap(original, value) {
            const b = Object.assign({}, d.bindings || {});
            if (value === null) delete b[original]; else b[original] = value;
            Settings.set("bindings", b)
        }
        function combo(event) {
            const mods = []; if (event.modifiers & Qt.MetaModifier) mods.push("SUPER"); if (event.modifiers & Qt.ControlModifier) mods.push("CONTROL"); if (event.modifiers & Qt.AltModifier) mods.push("ALT"); if (event.modifiers & Qt.ShiftModifier) mods.push("SHIFT");
            if ([Qt.Key_Meta,Qt.Key_Control,Qt.Key_Alt,Qt.Key_Shift,Qt.Key_AltGr].includes(event.key)) return ""
            const names = {}; names[Qt.Key_Return]="Return"; names[Qt.Key_Enter]="Return"; names[Qt.Key_Space]="Space"; names[Qt.Key_Tab]="Tab"; names[Qt.Key_Backtab]="Tab"; names[Qt.Key_Backspace]="BackSpace"; names[Qt.Key_Delete]="Delete";
            names[Qt.Key_Left]="Left";names[Qt.Key_Right]="Right";names[Qt.Key_Up]="Up";names[Qt.Key_Down]="Down";names[Qt.Key_Home]="Home";names[Qt.Key_End]="End";names[Qt.Key_PageUp]="Page_Up";names[Qt.Key_PageDown]="Page_Down";
            names[Qt.Key_Slash]="Slash";names[Qt.Key_Comma]="comma";names[Qt.Key_Period]="period";names[Qt.Key_Minus]="minus";names[Qt.Key_Equal]="equal";names[Qt.Key_Print]="Print";
            let key = names[event.key] || ""
            if (!key && event.key >= Qt.Key_A && event.key <= Qt.Key_Z) key = String.fromCharCode(event.key)
            if (!key && event.key >= Qt.Key_0 && event.key <= Qt.Key_9) key = "code:" + (event.key === Qt.Key_0 ? 19 : event.key - Qt.Key_1 + 10)
            if (!key && event.key >= Qt.Key_F1 && event.key <= Qt.Key_F35) key = "F" + (event.key - Qt.Key_F1 + 1)
            return key ? mods.concat([key]).join(" + ") : ""
        }

        MouseArea {anchors.fill:parent;onClicked:Settings.requestClose()}
        FocusScope {
            id:focus;anchors.fill:parent;enabled:win.mine
            // A light veil keeps the panel readable over bright wallpapers without hiding the desktop.
            // Keep it below the layer rule's ignore_alpha (0.1) in hypr/rules.lua, or the whole screen gets blurred.
            Rectangle {
                anchors.fill:parent;color:"black";opacity:win.mine?0.08:0
                Behavior on opacity { NumberAnimation { duration:win.mine?Theme.dLong:Theme.dClose;easing.type:Easing.OutCubic } }
            }
            Keys.onEscapePressed: { if(win.captureOriginal){win.captureOriginal="";win.recording=false} else if(Settings.closeRequested) Settings.closeRequested=false;else Settings.requestClose() }
            Rectangle {
                id:frame
                opacity:win.mine?1:0;scale:win.mine?1:0.98
                Behavior on opacity { NumberAnimation { duration:win.mine?Theme.dLong:Theme.dClose;easing.type:Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration:win.mine?Theme.dLong:Theme.dClose;easing.type:Easing.OutCubic } }
                // Small screens (for example 1280x720 at scale 2 is 640x360): keep the panel usable instead of clipping it.
                readonly property bool compact:height<520
                readonly property bool narrow:width<700
                anchors.centerIn:parent;width:Math.min(1120,parent.width-(parent.width<720?16:40));height:Math.min(790,parent.height-(parent.height<520?16:48))
                radius:14;color:Qt.alpha(Theme.glass,0.44);border.color:Qt.alpha(Theme.metalHi,0.65)
                MouseArea {anchors.fill:parent}
                RowLayout {
                    anchors.fill:parent;spacing:0
                    Rectangle {
                        Layout.preferredWidth:frame.narrow?64:frame.width>950?220:174;Layout.fillHeight:true;color:Qt.alpha(Theme.surfaceContainerLowest,0.26);radius:10;clip:true
                        ColumnLayout {
                            anchors.fill:parent;anchors.margins:frame.narrow?8:18;spacing:8
                            RowLayout { spacing:10; Layout.topMargin:frame.compact?0:12;Layout.alignment:frame.narrow?Qt.AlignHCenter:Qt.AlignLeft
                                Icon {name:"settings";size:26;color:Theme.glow}
                                ColumnLayout {spacing:1;visible:!frame.narrow
                                    DeckText {text:"MACHINE";font.family:Theme.fontMono;font.pixelSize:12;font.letterSpacing:2;color:Theme.glow}
                                    DeckText {text:"SPIRIT";font.family:Theme.fontMono;font.pixelSize:12;font.letterSpacing:4;color:Theme.glow}
                                }
                            }
                            DeckText {visible:!frame.compact&&!frame.narrow;text:"CONFIGURATION DECK";color:Theme.outline;font.family:Theme.fontMono;font.pixelSize:9;font.letterSpacing:1;Layout.topMargin:10;Layout.bottomMargin:18}
                            Flickable {   // the page list scrolls when the panel is short
                                Layout.fillWidth:true;Layout.fillHeight:true;clip:true;contentHeight:navColumn.implicitHeight;interactive:contentHeight>height;boundsBehavior:Flickable.StopAtBounds
                                ColumnLayout {
                                    id:navColumn;width:parent.width;spacing:frame.compact?4:8
                                Repeater { model:win.pages
                                    Basic.Button {
                                        id:nav;required property var modelData;required property int index
                                        Layout.fillWidth:true;implicitHeight:frame.compact?38:46;hoverEnabled:true;ToolTip.visible:frame.narrow&&hovered;ToolTip.text:modelData.name;onClicked:win.go(index)
                                        contentItem:RowLayout {spacing:11;Icon{name:nav.modelData.icon;size:20;color:win.page===nav.index?Theme.glow:Theme.outline} DeckText{visible:!frame.narrow;text:nav.modelData.name;color:win.page===nav.index?Theme.glow:Theme.surfaceVariantOn;Layout.fillWidth:true;font.weight:win.page===nav.index?Font.DemiBold:Font.Normal}}
                                        background:Rectangle {radius:7;color:win.page===nav.index?Qt.alpha(Theme.glow,0.09):nav.hovered?Theme.surfaceContainerLow:"transparent";border.color:nav.activeFocus?Theme.glow:"transparent"
                                            Rectangle{anchors.left:parent.left;anchors.verticalCenter:parent.verticalCenter;width:3;height:18;radius:1;color:Theme.glow;visible:win.page===nav.index}
                                        }
                                        leftPadding:frame.narrow?14:14
                                    }
                                }

                                }
                            }
                            Rectangle {visible:!frame.compact&&!frame.narrow;Layout.fillWidth:true;implicitHeight:65;radius:7;color:Theme.surfaceContainerLow;border.color:Theme.outlineVariant
                                Column {anchors.centerIn:parent;spacing:6
                                    DeckText{text:Settings.unsaved?"●  UNSAVED CHANGES":"●  SYSTEM IN SYNC";color:Settings.unsaved?Theme.hazard:Theme.glowDim;font.family:Theme.fontMono;font.pixelSize:9}
                                    DeckText{text:"Super+,  settings";color:Theme.outline;font.pixelSize:11}
                                }
                            }
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth:true;Layout.fillHeight:true;Layout.margins:frame.compact?14:26;spacing:frame.compact?8:16
                        ColumnLayout{visible:Privacy.onboarding;Layout.fillWidth:true;spacing:6
                            DeckText{text:"FIRST LAUNCH · "+(win.setupStep+1)+" / 6 · "+win.setupTitles[win.setupStep];color:Theme.glow;font.pixelSize:13;Layout.fillWidth:true}
                            Rectangle { Layout.fillWidth:true;implicitHeight:3;radius:2;color:Theme.surfaceContainerHigh
                                Rectangle { height:parent.height;width:parent.width*(win.setupStep+1)/6;radius:2;color:Theme.glow
                                    Behavior on width { NumberAnimation { duration:Theme.dLong;easing.type:Easing.OutCubic } }
                                }
                            }
                            RowLayout{Layout.fillWidth:true
                                DeckButton{text:"Back";enabled:win.setupStep>0;onClicked:{win.setupStep--;win.go(win.setupPages[win.setupStep])}}
                                DeckText{visible:!frame.compact;text:win.setupStep===5?"One last look, then you’re ready.":"Choose what works for you, or skip: lookups that send data online stay off until you decide.";Layout.fillWidth:true;font.pixelSize:12;color:Theme.surfaceVariantOn}
                                DeckButton{visible:!win.finalStep;text:"Skip setup";enabled:!Settings.busy&&!Privacy.busy;onClicked:Privacy.skipSetup()}
                                DeckButton{visible:!win.finalStep;text:"Next";accent:true;onClicked:{if(win.setupStep<5){win.setupStep++;win.go(win.setupPages[win.setupStep])}else Settings.finishSetup()}}
                            }
                        }
                        RowLayout {Layout.fillWidth:true;spacing:12
                            DeckField {id:search;Layout.fillWidth:true;placeholderText:"Search settings…";onTextEdited:win.query=text}
                            DeckButton {text:"Close";implicitWidth:70;onClicked:Settings.requestClose()}
                        }
                        RowLayout {Layout.fillWidth:true
                            ColumnLayout {Layout.fillWidth:true;spacing:5
                                DeckText{text:win.query?"SEARCH / CONFIGURATION":win.pages[win.page].tag;color:Theme.glowDim;font.family:Theme.fontMono;font.pixelSize:10;font.letterSpacing:1.5;Layout.fillWidth:true}
                                DeckText{text:win.query?"Find your controls":win.pages[win.page].name;font.pixelSize:frame.compact?22:30;font.weight:Font.DemiBold;Layout.fillWidth:true}
                                DeckText{visible:!frame.compact;text:win.query?"Jump straight to the setting you need.":win.pages[win.page].detail;color:Theme.surfaceVariantOn;font.pixelSize:13;Layout.fillWidth:true}
                            }
                            DeckButton {visible:!win.query&&win.page!==1&&win.page!==5&&win.page<6;text:"Reset page";onClicked:win.resetPage()}
                        }
                        ScrollView {
                            id:scroll;Layout.fillWidth:true;Layout.fillHeight:true;Layout.minimumHeight:120;clip:true;contentWidth:availableWidth
                            ColumnLayout {
                                width:scroll.availableWidth;spacing:14
                                PrivacyPage{stage:Privacy.onboarding?win.setupStep:-1;visible:!win.query&&win.page===6;Layout.fillWidth:true}
                                BrowserPage{visible:!win.query&&win.page===7;Layout.fillWidth:true}
                                UpdatesPage{visible:!win.query&&win.page===8;Layout.fillWidth:true}
                                ColumnLayout {
                                    visible:win.query!=="";Layout.fillWidth:true;spacing:8
                                    Repeater {model:win.searchItems.filter(x=>(x.title+" "+x.hint).toLowerCase().includes(win.query.toLowerCase()))
                                        DeckButton {required property var modelData;Layout.fillWidth:true;implicitHeight:52;text:modelData.title+"   ›";onClicked:win.go(modelData.page)}
                                    }
                                    DeckText {visible:win.searchItems.filter(x=>(x.title+" "+x.hint).toLowerCase().includes(win.query.toLowerCase())).length===0;text:"No settings found. Try “mouse”, “blur” or “lock”.";color:Theme.outline;Layout.fillWidth:true}
                                }
                                ColumnLayout {
                                    visible:!win.query&&win.page===0;Layout.fillWidth:true;spacing:14
                                    Rectangle {
                                        Layout.fillWidth:true;implicitHeight:180;radius:10;color:Theme.surfaceContainerLowest;border.color:Theme.outlineVariant
                                        Image{anchors.fill:parent;anchors.margins:1;source:Theme.wallpaper?"file://"+Theme.wallpaper:"";fillMode:Image.PreserveAspectCrop;opacity:0.18}
                                        Rectangle{anchors.fill:parent;color:Qt.alpha(Theme.glass,0.35);radius:10}
                                        Item {
                                            anchors{fill:parent;margins:20}
                                            Rectangle{id:mini;anchors.left:parent.left;anchors.verticalCenter:parent.verticalCenter;width:parent.width*0.55;height:108;radius:6;color:Theme.surfaceContainerLowest;border.color:Theme.metalHi
                                                Rectangle{x:5;y:5;width:parent.width-10;height:9;radius:2;color:Theme.metal;Row{anchors.centerIn:parent;spacing:5;Repeater{model:5;Rectangle{width:5;height:3;radius:1;color:index===0?Theme.glow:Theme.outline}}}}
                                                Row{ x:8+(win.d.gapsOut||0)*0.3;y:23;width:parent.width-2*x;height:parent.height-y-8;spacing:(win.d.gapsIn||0)*0.7
                                                    Repeater {model:2;Rectangle {required property int index;width:(parent.width-parent.spacing)/2;height:parent.height;radius:Math.min(20,(win.d.rounding||0)*0.5);color:index===0?Theme.surfaceContainerHigh:Theme.surfaceContainerLow;border.width:Math.max(1,(win.d.borderSize||1)*0.6);border.color:index===0?Theme.glowDim:Theme.outlineVariant;opacity:index===1&&win.d.dimInactive?1-(win.d.dimStrength||0):1
                                                        Column{anchors{left:parent.left;right:parent.right;top:parent.top;margins:12}spacing:6;Repeater{model:4;Rectangle{width:parent.width*(index===0?0.5:0.8);height:index===0?5:3;radius:2;color:index===0?Theme.glowDim:Theme.outlineVariant}}}
                                                    }}
                                                }
                                            }
                                            Column {anchors{left:mini.right;right:parent.right;verticalCenter:parent.verticalCenter;leftMargin:22}spacing:8
                                                DeckText{text:"YOUR WORKSPACE";font.family:Theme.fontMono;font.pixelSize:9;color:Theme.glowDim}
                                                DeckText{text:"Forged to fit.";font.pixelSize:22;font.weight:Font.DemiBold}
                                                DeckText{text:"Preview changes before applying.";width:parent.width;color:Theme.surfaceVariantOn;font.pixelSize:12}
                                                Row{spacing:6;Repeater{model:[Theme.glow,Theme.brass,Theme.surfaceContainerHigh,Theme.metalEdge];Rectangle{required property color modelData;width:15;height:15;radius:4;color:modelData;border.color:Qt.alpha(Theme.surfaceOn,0.2)}}}
                                            }
                                        }
                                    }
                                    RowLayout {Layout.fillWidth:true;spacing:8
                                        DeckButton{text:"Balanced";Layout.fillWidth:true;onClicked:Settings.patch({rounding:14,gapsIn:6,gapsOut:12,borderSize:2,blur:true,shadows:true,dimInactive:true,dimStrength:0.1})}
                                        DeckButton{text:"Compact";Layout.fillWidth:true;onClicked:Settings.patch({rounding:6,gapsIn:3,gapsOut:6,borderSize:1,blur:true,shadows:true,dimInactive:true,dimStrength:0.08})}
                                        DeckButton{text:"Square";Layout.fillWidth:true;onClicked:Settings.patch({rounding:0,gapsIn:4,gapsOut:8,borderSize:2,blur:false,shadows:false,dimInactive:false,dimStrength:0.1})}
                                    }
                                    DeckCard {title:"Window geometry";subtitle:"The preview above follows these controls."
                                        DeckRange{title:"Corner radius";value:win.d.rounding??14;to:30;unit:" px";onChanged:v=>Settings.set("rounding",Math.round(v))}
                                        DeckRange{title:"Space between windows";value:win.d.gapsIn??6;to:30;unit:" px";onChanged:v=>Settings.set("gapsIn",Math.round(v))}
                                        DeckRange{title:"Space at screen edges";value:win.d.gapsOut??12;to:60;unit:" px";onChanged:v=>Settings.set("gapsOut",Math.round(v))}
                                        DeckRange{title:"Border weight";value:win.d.borderSize??2;from:1;to:5;unit:" px";onChanged:v=>Settings.set("borderSize",Math.round(v))}
                                    }
                                    DeckCard {title:"Light & depth"
                                        DeckToggle{title:"Background blur";hint:win.d.lowPower?"Paused while low power mode is enabled":"Softens translucent window backgrounds";checked:!!win.d.blur;onChanged:v=>Settings.set("blur",v)}
                                        DeckDivider{}
                                        DeckToggle{title:"Window shadows";hint:win.d.lowPower?"Paused while low power mode is enabled":"A little depth between windows";checked:!!win.d.shadows;onChanged:v=>Settings.set("shadows",v)}
                                        DeckDivider{}
                                        DeckToggle{title:"Dim inactive windows";checked:!!win.d.dimInactive;onChanged:v=>Settings.set("dimInactive",v)}
                                        DeckRange{visible:!!win.d.dimInactive;title:"Dimming strength";value:(win.d.dimStrength??0.1)*100;to:50;unit:"%";onChanged:v=>Settings.set("dimStrength",Math.round(v)/100)}
                                    }
                                    RowLayout{Layout.fillWidth:true
                                        DeckButton{text:"Wallpaper archive ↗";Layout.fillWidth:true;onClicked:{if(Settings.dirty) Settings.requestClose();else {Settings.open=false;Walls.toggle()}}}
                                        DeckButton{text:"Desktop instruments ↗";Layout.fillWidth:true;onClicked:{if(Settings.dirty) Settings.requestClose();else {Settings.open=false;DesktopWidgets.toggle()}}}
                                    }
                                }
                                ColumnLayout {
                                    visible:!win.query&&win.page===1;Layout.fillWidth:true;spacing:14
                                    DeckCard {title:"Connected displays";subtitle:"Choose the screen that hosts your panels."
                                        RowLayout {Layout.fillWidth:true;spacing:10
                                            Repeater {model:Settings.monitors
                                                Rectangle {required property var modelData;Layout.fillWidth:true;implicitHeight:100;radius:7;color:Theme.surfaceContainerLowest;border.color:win.d.primaryOutput===modelData.name?Theme.glowDim:Theme.outlineVariant
                                                    Column {anchors.centerIn:parent;spacing:7
                                                        Icon{name:"desktop_windows";size:28;color:Theme.glow;anchors.horizontalCenter:parent.horizontalCenter}
                                                        DeckText{text:modelData.name+" · "+modelData.width+" × "+modelData.height;font.pixelSize:12;anchors.horizontalCenter:parent.horizontalCenter}
                                                    }
                                                }
                                            }
                                        }
                                        RowLayout {Layout.fillWidth:true
                                            DeckText{text:"Panels open on";Layout.fillWidth:true}
                                            DeckChoice{model:["Automatic"].concat(Settings.monitors.map(m=>m.name));currentIndex:Math.max(0,model.indexOf(win.d.primaryOutput||"Automatic"));onActivated:Settings.set("primaryOutput",currentIndex?currentText:"")}
                                        }
                                        DeckButton{text:"Refresh displays";onClicked:Settings.refreshDevices()}
                                    }
                                    Repeater {model:Settings.monitors
                                        DeckCard {
                                            id:display;required property var modelData
                                            title:modelData.name;subtitle:modelData.description
                                            readonly property var saved:(win.d.monitors||[]).find(m=>m.output===modelData.name)||({output:modelData.name,mode:"preferred",position:modelData.x+"x"+modelData.y,scale:modelData.scale,transform:modelData.transform,disabled:!!modelData.disabled})
                                            function update(key,value){const m=Object.assign({},saved);m[key]=value;Settings.set("monitors",(win.d.monitors||[]).filter(x=>x.output!==modelData.name).concat([m]))}
                                            DeckToggle{title:"Enable display";hint:"At least one connected display must stay enabled";checked:!display.saved.disabled;onChanged:v=>display.update("disabled",!v)}
                                            RowLayout{Layout.fillWidth:true;DeckText{text:"Resolution & refresh rate";Layout.fillWidth:true} DeckChoice{Layout.maximumWidth:300;model:["preferred"].concat((display.modelData.availableModes||[]).map(x=>x.replace("Hz","")));currentIndex:Math.max(0,model.indexOf(display.saved.mode));onActivated:display.update("mode",currentText)}}
                                            RowLayout{Layout.fillWidth:true;DeckText{text:"Scale (1 = normal, higher = bigger)";Layout.fillWidth:true} DeckChoice{model:["0.75","1","1.25","1.5","1.75","2","2.5","3","4"].concat([String(display.saved.scale)]).filter((v,i,a)=>a.indexOf(v)===i).sort((a,b)=>Number(a)-Number(b));currentIndex:model.indexOf(String(display.saved.scale));onActivated:display.update("scale",Number(currentText))}}
                                            RowLayout{Layout.fillWidth:true;DeckText{text:"Rotation";Layout.fillWidth:true} DeckChoice{model:["Normal","90°","180°","270°","Flipped","Flipped 90°","Flipped 180°","Flipped 270°"];currentIndex:display.saved.transform||0;onActivated:display.update("transform",currentIndex)}}
                                            RowLayout{Layout.fillWidth:true;DeckText{text:"Position";Layout.fillWidth:true} DeckField{Layout.preferredWidth:140;text:display.saved.position;placeholderText:"0x0";onEditingFinished:display.update("position",text)} DeckButton{text:"Auto";onClicked:display.update("position","auto")}}
                                        }
                                    }
                                    DeckText{text:"Display changes are a 15-second preview. If the picture disappears, wait: the previous setup returns automatically.";color:Theme.surfaceVariantOn;font.pixelSize:12;Layout.fillWidth:true}
                                }
                                ColumnLayout {
                                    visible:!win.query&&win.page===2;Layout.fillWidth:true;spacing:14
                                    DeckCard {title:"Your languages";subtitle:"Keep up to four layouts. The first is used when the session starts."
                                        Flow {Layout.fillWidth:true;spacing:8
                                            Repeater{model:win.d.layouts||[];DeckButton{required property string modelData;text:modelData.toUpperCase()+((win.d.layouts||[]).length>1?"  ×":"");accent:true;enabled:(win.d.layouts||[]).length>1;onClicked:Settings.set("layouts",win.d.layouts.filter(x=>x!==modelData))}}
                                        }
                                        Flow {Layout.fillWidth:true;spacing:8
                                            Repeater{model:[{code:"us",label:"English (US)"},{code:"ru",label:"Русский"},{code:"de",label:"Deutsch"},{code:"fr",label:"Français"},{code:"es",label:"Español"},{code:"gb",label:"English (UK)"}]
                                                DeckButton{required property var modelData;text:"+ "+modelData.label;enabled:!(win.d.layouts||[]).includes(modelData.code)&&(win.d.layouts||[]).length<4;onClicked:Settings.set("layouts",win.d.layouts.concat([modelData.code]))}
                                            }
                                        }
                                        RowLayout{Layout.fillWidth:true
                                            DeckField{id:layoutCode;Layout.fillWidth:true;placeholderText:"Other layout code, e.g. pl";maximumLength:8}
                                            DeckButton{text:"Add layout";enabled:/^[a-z]{2,8}$/.test(layoutCode.text)&&!(win.d.layouts||[]).includes(layoutCode.text)&&(win.d.layouts||[]).length<4;onClicked:{Settings.set("layouts",win.d.layouts.concat([layoutCode.text]));layoutCode.clear()}}
                                        }
                                        DeckDivider{}
                                        RowLayout{Layout.fillWidth:true;DeckText{text:"Switch languages";Layout.fillWidth:true} DeckChoice{id:switcher;property var codes:["grp:alt_shift_toggle","grp:win_space_toggle","grp:ctrl_shift_toggle","grp:caps_toggle",""];model:["Alt + Shift","Super + Space","Ctrl + Shift","Caps Lock","Custom / disabled"];currentIndex:Math.max(0,codes.indexOf(win.d.layoutSwitch)>=0?codes.indexOf(win.d.layoutSwitch):4);onActivated:Settings.set("layoutSwitch",codes[currentIndex])}}
                                        DeckField{visible:switcher.currentIndex===4;Layout.fillWidth:true;text:win.d.layoutSwitch||"";placeholderText:"Custom XKB option, or leave empty";onTextEdited:Settings.set("layoutSwitch",text)}
                                        DeckText{visible:win.d.layoutSwitch==="grp:win_space_toggle";text:"Super+Space also opens the command console by default. Remap that action in Shortcuts if you use it for languages.";color:Theme.hazard;font.pixelSize:12;Layout.fillWidth:true}
                                    }
                                    DeckCard {title:"Typing rhythm";subtitle:"How held keys repeat."
                                        DeckRange{title:"Repeat speed";value:win.d.repeatRate??25;from:1;to:100;unit:" / sec";onChanged:v=>Settings.set("repeatRate",Math.round(v))}
                                        DeckRange{title:"Delay before repeating";value:win.d.repeatDelay??600;from:100;to:2000;step:50;unit:" ms";onChanged:v=>Settings.set("repeatDelay",Math.round(v))}
                                        DeckField{Layout.fillWidth:true;placeholderText:"Try typing here after applying…"}
                                    }
                                }
                                ColumnLayout {
                                    visible:!win.query&&win.page===3;Layout.fillWidth:true;spacing:14
                                    DeckCard {title:"Pointer response"
                                        DeckRange{title:"Sensitivity";value:win.d.sensitivity??0;from:-1;to:1;step:0.05;decimals:2;onChanged:v=>Settings.set("sensitivity",Math.round(v*100)/100)}
                                        RowLayout{Layout.fillWidth:true;DeckText{text:"Acceleration (adaptive speeds up with fast movement)";Layout.fillWidth:true} DeckChoice{model:["Adaptive","Flat / precise"];currentIndex:win.d.accelProfile==="flat"?1:0;onActivated:Settings.set("accelProfile",currentIndex?"flat":"adaptive")}}
                                        DeckDivider{}
                                        DeckToggle{title:"Left-handed mouse";hint:"Swap the primary and secondary buttons";checked:!!win.d.leftHanded;onChanged:v=>Settings.set("leftHanded",v)}
                                        DeckDivider{}
                                        DeckToggle{title:"Focus follows the pointer";hint:"Moving over a window gives it keyboard focus";checked:!!win.d.followMouse;onChanged:v=>Settings.set("followMouse",v)}
                                    }
                                    DeckCard {title:"Touchpad";subtitle:"These preferences apply when a touchpad is connected."
                                        DeckToggle{title:"Natural scrolling";hint:"Move content in the direction of your fingers";checked:!!win.d.naturalScroll;onChanged:v=>Settings.set("naturalScroll",v)}
                                        DeckDivider{}
                                        DeckToggle{title:"Tap to click";hint:"A light tap acts as a primary click";checked:!!win.d.tapToClick;onChanged:v=>Settings.set("tapToClick",v)}
                                    }
                                }
                                ColumnLayout {
                                    visible:!win.query&&win.page===4;Layout.fillWidth:true;spacing:14
                                    DeckCard {title:"Motion & power"
                                        DeckToggle{title:"Reduced motion";hint:"Quiet transitions in the shell and window manager";checked:!!win.d.reducedMotion;onChanged:v=>Settings.set("reducedMotion",v)}
                                        DeckDivider{}
                                        DeckToggle{title:"Low power mode";hint:"Pause ambient effects, window animations, blur and shadows";checked:!!win.d.lowPower;onChanged:v=>Settings.set("lowPower",v)}
                                    }
                                    DeckCard {title:"When you step away";subtitle:"Lock first. Let the displays rest afterwards."
                                        RowLayout{Layout.fillWidth:true;DeckText{text:"Lock after";Layout.fillWidth:true} DeckChoice{property var times:[60,120,300,600,900,1800,3600].concat([win.d.lockSeconds||600]).filter((v,i,a)=>a.indexOf(v)===i).sort((a,b)=>a-b);model:times.map(x=>(x/60)+" min");currentIndex:times.indexOf(win.d.lockSeconds||600);onActivated:{const n=times[currentIndex];Settings.patch({lockSeconds:n,screenOffSeconds:Math.max(n,win.d.screenOffSeconds)})}}}
                                        RowLayout{Layout.fillWidth:true;DeckText{text:"Turn screens off after";Layout.fillWidth:true} DeckChoice{property var times:[60,120,300,600,900,1800,3600,7200].concat([win.d.screenOffSeconds||900]).filter((v,i,a)=>v>=(win.d.lockSeconds||600)&&a.indexOf(v)===i).sort((a,b)=>a-b);model:times.map(x=>(x/60)+" min");currentIndex:times.indexOf(win.d.screenOffSeconds||900);onActivated:Settings.set("screenOffSeconds",times[currentIndex])}}
                                        Rectangle{Layout.fillWidth:true;implicitHeight:56;radius:7;color:Theme.surfaceContainerLowest
                                            RowLayout{anchors.fill:parent;anchors.margins:12;Icon{name:"lock";size:21;color:Theme.glowDim} DeckText{text:"Super+L locks immediately. Your session also locks before sleep.";Layout.fillWidth:true;font.pixelSize:12;color:Theme.surfaceVariantOn}}
                                        }
                                    }
                                }
                                ColumnLayout {
                                    visible:!win.query&&win.page===5;Layout.fillWidth:true;spacing:10
                                    DeckField{Layout.fillWidth:true;placeholderText:"Filter shortcuts by action or key…";onTextEdited:win.shortcutQuery=text}
                                    DeckText{text:"Select a shortcut to record a replacement. Restore returns just that action to its default.";color:Theme.surfaceVariantOn;font.pixelSize:12;Layout.fillWidth:true}
                                    Repeater {
                                        model:Settings.bindings.filter(b=>(b.keys+" "+b.description).toLowerCase().includes(win.shortcutQuery.toLowerCase())).sort((a,b)=>a.description.localeCompare(b.description))
                                        Rectangle {
                                            id:binding;required property var modelData
                                            readonly property string original:modelData.original||""
                                            readonly property bool overridden:original!==""&&Object.prototype.hasOwnProperty.call(win.d.bindings||{},original)
                                            readonly property string actual:overridden?win.d.bindings[original]:(original||modelData.keys)
                                            Layout.fillWidth:true;implicitHeight:Math.max(68,bindingRow.implicitHeight+24);radius:7;color:Qt.alpha(Theme.surfaceContainerLow,0.45);border.color:overridden?Qt.alpha(Theme.glowDim,0.6):Qt.alpha(Theme.outlineVariant,0.5)
                                            RowLayout{id:bindingRow;anchors{left:parent.left;right:parent.right;verticalCenter:parent.verticalCenter;margins:14}spacing:10
                                                ColumnLayout{Layout.fillWidth:true;spacing:3
                                                    DeckText{text:binding.modelData.description.split(":")[0].toUpperCase();font.family:Theme.fontMono;font.pixelSize:9;color:Theme.outline;Layout.fillWidth:true}
                                                    DeckText{text:binding.modelData.description.split(":").slice(1).join(":").trim()||binding.modelData.description;Layout.fillWidth:true;font.pixelSize:13}
                                                }
                                                DeckButton{text:binding.actual||"Disabled";Layout.maximumWidth:250;enabled:binding.original!=="";onClicked:{win.captureOriginal=binding.original;win.captureLabel=binding.modelData.description;win.captured=binding.actual;win.recording=false}}
                                                DeckButton{text:"↶";implicitWidth:32;visible:binding.overridden;onClicked:win.remap(binding.original,null);ToolTip.visible:hovered;ToolTip.text:"Restore default"}
                                            }
                                        }
                                    }
                                    DeckText{visible:Settings.bindings.filter(b=>(b.keys+" "+b.description).toLowerCase().includes(win.shortcutQuery.toLowerCase())).length===0;text:"No matching shortcuts.";color:Theme.outline;Layout.fillWidth:true}
                                }
                            }
                        }
                        DeckDivider{}
                        RowLayout {Layout.fillWidth:true;spacing:10
                            ColumnLayout{Layout.fillWidth:true;spacing:3
                                DeckText{id:statusLine;text:Settings.error||Privacy.error||BrowserPrivacy.error||(BrowserPrivacy.dirty?"Browser choices not yet applied":"")||Settings.status||(Settings.dirty?"Changes are ready to apply":"All changes saved");color:(Settings.error||Privacy.error||BrowserPrivacy.error)?Theme.rustText:Settings.dirty?Theme.hazard:Theme.surfaceVariantOn;font.pixelSize:12;Layout.fillWidth:true
                                    // One short pulse when a change lands, so "saved" is felt as well as read. Instant with reduced motion (dMedium is 0).
                                    onTextChanged:if(statusLine.text==="All changes saved"||statusLine.text==="Settings applied")savedPulse.restart()
                                    NumberAnimation{id:savedPulse;target:statusLine;property:"opacity";from:0.3;to:1;duration:Theme.dMedium;easing.type:Easing.OutCubic}
                                }
                                DeckText{visible:Settings.countdown>0;text:"Reverting displays in "+Settings.countdown+" seconds";color:Theme.hazard;font.pixelSize:12;Layout.fillWidth:true}
                            }
                            DeckButton{text:Settings.countdown>0?"Revert":"Discard";visible:!win.finalStep&&(Settings.unsaved||Settings.countdown>0);enabled:!Settings.busy&&!BrowserPrivacy.busy;onClicked:Settings.countdown>0?Settings.run("revert"):Settings.discard()}
                            DeckButton{
                                text:win.finalStep?(Settings.countdown>0?"Keep displays":Settings.busy||Privacy.busy?"Saving…":"Start using MachineSpirit"):Settings.countdown>0?"Keep displays":Settings.busy||BrowserPrivacy.busy?"Working…":Settings.dirty?(BrowserPrivacy.dirty?"Apply shell changes":"Apply changes"):BrowserPrivacy.preview!==""?"Apply browser changes":BrowserPrivacy.dirty?"Review browser changes":"Apply changes"
                                accent:true
                                enabled:!Settings.busy&&!Privacy.busy&&!BrowserPrivacy.busy&&(win.finalStep||Settings.unsaved||Settings.countdown>0||BrowserPrivacy.preview!=="")
                                onClicked:win.finalStep&&Settings.countdown===0?Settings.finishSetup():win.applyChanges()
                            }
                        }
                    }
                }
            }
            Rectangle {
                id:success;anchors.fill:frame;radius:frame.radius;visible:win.setupDone;color:Theme.surfaceContainerLow
                MouseArea { anchors.fill:parent }
                ColumnLayout {
                    anchors.centerIn:parent;width:Math.min(520,parent.width-80);spacing:22
                    DeckText { text:"✓";font.pixelSize:64;color:Theme.glow;Layout.alignment:Qt.AlignHCenter }
                    DeckText { text:"Setup complete";font.pixelSize:32;font.weight:Font.DemiBold;Layout.alignment:Qt.AlignHCenter }
                    DeckText { text:"Your choices are saved. Your desktop is ready.";Layout.fillWidth:true;horizontalAlignment:Text.AlignHCenter;color:Theme.surfaceVariantOn }
                    DeckText { text:"Good to know: tap Super to open the launcher · Super+Enter opens a terminal · Super+/ lists every shortcut · Super+, brings these settings back.";Layout.fillWidth:true;horizontalAlignment:Text.AlignHCenter;color:Theme.glowDim;font.pixelSize:13 }
                    DeckText { visible:BrowserPrivacy.dirty;text:"Unapplied browser changes are still waiting in Browsers.";Layout.fillWidth:true;horizontalAlignment:Text.AlignHCenter;color:Theme.hazard }
                    DeckButton { text:"Go to desktop";accent:true;Layout.alignment:Qt.AlignHCenter;onClicked:{win.setupDone=false;Settings.open=false} }
                    DeckButton { text:"Open settings";Layout.alignment:Qt.AlignHCenter;onClicked:{win.setupDone=false;win.go(0)} }
                }
            }
            Rectangle {
                anchors.fill:frame;radius:frame.radius;color:Qt.alpha("black",0.45)
                readonly property bool shown:Settings.closeRequested||win.captureOriginal!==""
                opacity:shown?1:0;visible:opacity>0.01   // fade in and out instead of popping
                Behavior on opacity { NumberAnimation { duration:shown?Theme.dShort:Theme.dClose;easing.type:Easing.OutCubic } }
                MouseArea{anchors.fill:parent}
                Rectangle {
                    anchors.centerIn:parent;width:Math.min(500,parent.width-60);height:dialog.implicitHeight+48;radius:12;color:Theme.surfaceContainerLow;border.color:Theme.metalEdge
                    ColumnLayout {
                        id:dialog;anchors{left:parent.left;right:parent.right;top:parent.top;margins:24}spacing:16
                        DeckText{text:Settings.closeRequested?"Close without applying?":"Choose a shortcut";font.pixelSize:24;font.weight:Font.DemiBold;Layout.fillWidth:true}
                        DeckText{text:Settings.closeRequested?"Your changes have not been applied yet. Keep editing to apply them, or discard them and close.":win.captureLabel;color:Theme.surfaceVariantOn;Layout.fillWidth:true}
                        DeckField {
                            id:recorder;visible:!Settings.closeRequested;Layout.fillWidth:true;readOnly:win.recording;text:win.captured;placeholderText:win.recording?"Press a combination…":"SUPER + ALT + E";onTextEdited:win.captured=text
                            Keys.onPressed:event=>{
                                if(!win.recording)return
                                event.accepted=true
                                if(event.key===Qt.Key_Escape){win.recording=false;return}
                                if(event.isAutoRepeat)return
                                const c=win.combo(event)
                                if(c){win.captured=c;win.recording=false}
                            }
                        }
                        DeckText{visible:!Settings.closeRequested;text:win.recording?"Listening. Escape cancels recording.":"Record keys, type a combination, or disable this action. Conflicts are checked when you apply.";font.pixelSize:12;color:Theme.surfaceVariantOn;Layout.fillWidth:true}
                        RowLayout{Layout.fillWidth:true
                            DeckButton{text:Settings.closeRequested?"Keep editing":win.recording?"Stop recording":"Record keys";onClicked:{if(Settings.closeRequested)Settings.closeRequested=false;else {win.recording=!win.recording;recorder.forceActiveFocus()}}}
                            Item{Layout.fillWidth:true}
                            DeckButton{text:Settings.closeRequested?"Discard changes":"Disable";onClicked:{if(Settings.closeRequested){Settings.discard();Settings.closeRequested=false;Settings.open=false}else{win.remap(win.captureOriginal,"");win.captureOriginal="";win.recording=false}}}
                            DeckButton{visible:!Settings.closeRequested;text:"Use shortcut";accent:true;enabled:win.captured!==""&&!win.recording;onClicked:{win.remap(win.captureOriginal,win.captured);win.captureOriginal=""}}
                        }
                        DeckButton{visible:!Settings.closeRequested;text:"Cancel";onClicked:{win.captureOriginal="";win.recording=false}}
                    }
                }
            }
        }
    }
}
