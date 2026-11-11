// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Basic
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.common
import qs.services
import qs.kits

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
            {name:"Session & controls", icon:"shield", tag:"WATCH & REST", detail:"Locking, rest and the controls of the shell itself."},
            {name:"Shortcuts", icon:"keyboard_command_key", tag:"INSTRUMENT MANUAL", detail:"Find an action. Give it a combination you remember."},
            {name:"Privacy",icon:"shield_lock",tag:"YOUR DATA / YOUR CHOICE",detail:"Choose what connects, what is shared, and how requests travel."},
            {name:"Browsers",icon:"language",tag:"BROWSER POLICIES",detail:"Review supported controls before applying changes."},
            {name:"Updates",icon:"update",tag:"UPKEEP / RITES",detail:"Keep MachineSpirit current. Nothing is checked until you ask."},
            {name:"Themes",icon:"palette",tag:"FACTION / THEME PACKS",detail:"Try a faction before you commit to it. A preview changes nothing permanent."},
            {name:"Animations & effects",icon:"auto_awesome",tag:"MOTION / AMBIENT LIFE",detail:"How lively the machine is. Effects never delay a control or alter a reading."},
            {name:"Bar & panels",icon:"toolbar",tag:"MANIFOLD",detail:"What the bar carries, in what order, and where it hangs."},
            {name:"Desktop & widgets",icon:"widgets",tag:"DESK INSTRUMENTS",detail:"The instruments that sit on the wallpaper."},
            {name:"Notifications",icon:"notifications",tag:"MESSAGES",detail:"How messages arrive, how long they stay and how many are kept."}
        ]
        // the sidebar: groups in reading order, each entry is an index into `pages`
        readonly property var nav: [
            {group:"LOOK", items:[0,9,10]}, {group:"SHELL", items:[11,12,13]},
            {group:"SYSTEM", items:[1,2,3,4,5]}, {group:"DATA", items:[6,7,8]}
        ]
        readonly property var navFlat: { const out=[]; for (const g of nav) { out.push({head:g.group}); for (const i of g.items) out.push({page:i}) } return out }
        // Every control can be found by its own name; `to` is the exact title of the control, which then lights up and scrolls into view.
        readonly property var searchItems: [
            {title:"Theme packs",hint:"faction mechanicus ultramarines necrons khorne chaos preview apply revert",page:9},
            {title:"Colour mode",hint:"wallpaper colours matugen palette follow guarded faction",page:9},
            {title:"Recommended wallpapers",hint:"theme background picture",page:9},
            {title:"Corner radius",hint:"rounding window shape",page:0,to:"Corner radius"},
            {title:"Space between windows",hint:"gaps inner",page:0,to:"Space between windows"},
            {title:"Space at screen edges",hint:"gaps outer margin",page:0,to:"Space at screen edges"},
            {title:"Border weight",hint:"window border width",page:0,to:"Border weight"},
            {title:"Background blur",hint:"transparency glass",page:0,to:"Background blur"},
            {title:"Window shadows",hint:"depth",page:0,to:"Window shadows"},
            {title:"Dim inactive windows",hint:"focus dimming",page:0,to:"Dim inactive windows"},
            {title:"Panel opacity",hint:"transparency glass see through",page:0,to:"Panel opacity"},
            {title:"Glow strength",hint:"phosphor halo bloom light",page:0,to:"Glow strength"},
            {title:"Decoration",hint:"ornaments seals heraldry decor skulls minimal",page:0,to:"Decoration"},
            {title:"Effect intensity",hint:"sparks lightning ambient off subtle lively",page:10,to:"Intensity"},
            {title:"How often effects come",hint:"frequency rare",page:10,to:"How often"},
            {title:"Discharges at the bar",hint:"lightning cables arcs sparks",page:10,to:"Discharges at the bar"},
            {title:"Life on the screens",hint:"flicker crt scan sweep",page:10,to:"Life on the screens"},
            {title:"Particles",hint:"sparks drops",page:10,to:"Particles"},
            {title:"Atmospheric messages",hint:"litany binary text",page:10,to:"Atmospheric messages"},
            {title:"Animation speed",hint:"faster slower transitions",page:10,to:"Animation speed"},
            {title:"Reduced motion",hint:"animations flicker flashes accessibility",page:10,to:"Reduced motion"},
            {title:"Low power mode",hint:"battery performance gpu",page:10,to:"Low power mode"},
            {title:"Bar modules & order",hint:"clock tray player window title hide move",page:11},
            {title:"Weather beside the clock",hint:"bar temperature",page:11,to:"Weather beside the clock"},
            {title:"Network rate in figures",hint:"bar speed",page:11,to:"Network rate in figures"},
            {title:"Bar on every screen",hint:"monitor second display",page:11,to:"Bar on every screen"},
            {title:"Density",hint:"compact comfortable spacing",page:11,to:"Density"},
            {title:"Desktop instruments",hint:"widgets clock weather resources notes size",page:12},
            {title:"Seconds on the clock",hint:"widget time",page:12,to:"Seconds on the clock"},
            {title:"Scan line",hint:"widget sweep effect",page:12,to:"Scan line"},
            {title:"Pop-up duration",hint:"notification toast seconds timeout",page:13,to:"Stay on screen"},
            {title:"Pop-ups at once",hint:"notification toast count",page:13,to:"At most at once"},
            {title:"Urgent messages in quiet mode",hint:"do not disturb dnd critical",page:13,to:"Urgent messages break through"},
            {title:"Notification log size",hint:"history kept",page:13,to:"Messages kept"},
            {title:"Display arrangement", hint:"monitor resolution scale rotation primary", page:1},
            {title:"Keyboard languages", hint:"layout English Russian switching", page:2},
            {title:"Repeat speed", hint:"keyboard typing", page:2,to:"Repeat speed"},
            {title:"Delay before repeating", hint:"keyboard typing", page:2,to:"Delay before repeating"},
            {title:"Pointer sensitivity", hint:"mouse speed", page:3,to:"Sensitivity"},
            {title:"Left-handed mouse", hint:"buttons swap", page:3,to:"Left-handed mouse"},
            {title:"Focus follows the pointer", hint:"mouse hover window", page:3,to:"Focus follows the pointer"},
            {title:"Natural scrolling", hint:"touchpad", page:3,to:"Natural scrolling"},
            {title:"Tap to click", hint:"touchpad", page:3,to:"Tap to click"},
            {title:"Idle & locking", hint:"sleep timeout minutes screen off lock screen", page:4},
            {title:"Hold time for dangerous actions", hint:"power off reboot log out press", page:4,to:"Hold to confirm"},
            {title:"Tap Super for the console", hint:"launcher key", page:4,to:"Tap Super to open the console"},
            {title:"Restart the shell", hint:"reload quickshell", page:4},
            {title:"Keyboard shortcuts", hint:"bindings remap keys hotkeys", page:5},
            {title:"Privacy, proxy & setup",hint:"telemetry offline city weather network",page:6},
            {title:"Browser privacy",hint:"firefox chrome chromium librewolf zen telemetry",page:7},
            {title:"Updates",hint:"update upgrade dots release version check",page:8}
        ]
        function seek(item) { go(item.page); if (item.to) { Settings.sought = ""; soughtArm.target = item.to; soughtArm.restart() } }
        Timer { id: soughtArm; property string target: ""; interval: 60; onTriggered: { Settings.sought = target; soughtClear.restart() } }
        Timer { id: soughtClear; interval: 2600; onTriggered: Settings.sought = "" }
        Connections { target: Settings; function onReveal(item) { if (!win.mine) return; const y = item.mapToItem(scroll.contentItem.contentItem, 0, 0).y; scroll.contentItem.contentY = Math.max(0, Math.min(y - 60, scroll.contentItem.contentHeight - scroll.contentItem.height)) } }
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
        Connections { target: Settings; function onShowPage(index) { if (index >= 0 && index < win.pages.length) win.go(index) } }
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
            const groups = {0:["rounding","gapsIn","gapsOut","borderSize","blur","shadows","dimInactive","dimStrength","panelOpacity","glowStrength","ornaments"],2:["layouts","layoutSwitch","repeatRate","repeatDelay"],3:["sensitivity","accelProfile","leftHanded","followMouse","naturalScroll","tapToClick"],4:["lockSeconds","screenOffSeconds","lockBackend","holdMs","superTap"],
                10:["fxLevel","fxFrequency","fxDischarge","fxScreens","fxParticles","fxMessages","animSpeed","reducedMotion","lowPower"],11:["barLeft","barRight","barWeather","barNetRate","barAllScreens","density"],12:["widgetScan"],13:["toastSeconds","toastMax","urgentThroughQuiet","historyLimit"]}
            const patch = {}; (groups[page] || []).forEach(k => patch[k] = Settings.defaults[k]); Settings.patch(patch)
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
                // Stay clear of the top bar whenever the screen has room for it.
                readonly property int barRoom:parent.height>=600?48:0
                anchors.horizontalCenter:parent.horizontalCenter;anchors.verticalCenter:parent.verticalCenter;anchors.verticalCenterOffset:barRoom/2
                width:Math.min(1120,parent.width-(parent.width<720?16:40));height:Math.min(790,parent.height-barRoom-(parent.height<520?16:48))
                // Mechanicus: a pane of glass with a metal edge. The other liveries build the deck as one of their
                // windows: a housing with the glass let into it.
                readonly property bool plain:Skin.frame==="mechanicus"
                radius:14;color:plain?Qt.alpha(Theme.glass,0.44):"transparent"
                border.color:plain?Qt.alpha(Theme.metalHi,0.65):"transparent"
                border.width:plain?1:0
                MouseArea {anchors.fill:parent}
                Bezel { visible:!frame.plain;anchors.fill:parent;radius:16;inset:0;role:"window";bolts:false }
                CrtScreen { visible:!frame.plain;anchors.fill:parent;anchors.margins:8;radius:11;padding:0;bootOnLoad:false;ambient:false }
                // the faction's fastenings at the corners of the deck; put away with reduced decoration
                Repeater { model:Theme.ornaments>0&&frame.plain?4:0
                    Bolt { required property int index;z:5;size:7;angle:20+index*47;visible:Theme.kit!=="necrons"||index===1||index===2
                        x:index%2===0?8:frame.width-size-8;y:index<2?8:frame.height-size-8 } }
                RowLayout {
                    anchors.fill:parent;spacing:0
                    Rectangle {
                        Layout.preferredWidth:frame.narrow?64:frame.width>950?240:190;Layout.fillHeight:true;color:frame.plain?Qt.alpha(Theme.surfaceContainerLowest,0.26):"transparent";radius:10;clip:!frame.plain
                        Layout.margins:frame.plain?0:14
                        SectionFrame { anchors.fill:parent;visible:!frame.plain;fill:Qt.alpha(Theme.glass,0.55);rim:Qt.alpha(Theme.outlineVariant,0.6) }
                        ColumnLayout {
                            anchors.fill:parent;anchors.margins:frame.narrow?8:18;spacing:8
                            RowLayout { spacing:10; Layout.topMargin:frame.compact?0:12;Layout.alignment:frame.narrow?Qt.AlignHCenter:Qt.AlignLeft
                                Heart {implicitWidth:26;implicitHeight:26;spin:false;hole:"transparent"}
                                ColumnLayout {spacing:1;visible:!frame.narrow
                                    DeckText {text:"MACHINE";font.family:Theme.fontMono;font.pixelSize:12;font.letterSpacing:2;color:Theme.glow}
                                    DeckText {text:"SPIRIT";font.family:Theme.fontMono;font.pixelSize:12;font.letterSpacing:4;color:Theme.glow}
                                }
                            }
                            DeckText {visible:!frame.compact&&!frame.narrow;text:"CONFIGURATION DECK";color:Theme.outline;font.family:Theme.fontMono;font.pixelSize:9;font.letterSpacing:1;Layout.topMargin:6;Layout.bottomMargin:4}
                            Flickable {   // the page list scrolls when the panel is short
                                Layout.fillWidth:true;Layout.fillHeight:true;clip:true;contentHeight:navColumn.implicitHeight;interactive:contentHeight>height;boundsBehavior:Flickable.StopAtBounds
                                ColumnLayout {
                                    id:navColumn;width:parent.width;spacing:frame.compact?2:3
                                Repeater { model:win.navFlat
                                    Loader {
                                        id:slot;required property var modelData
                                        Layout.fillWidth:true
                                        sourceComponent:modelData.head?navHead:navItem
                                        property var entry:modelData
                                    }
                                }
                                Component { id:navHead
                                    DeckText { text:frame.narrow?"·":parent.entry.head;color:Theme.outline;font.family:Theme.fontMono;font.pixelSize:9;font.letterSpacing:1.5;topPadding:frame.compact?2:8;leftPadding:frame.narrow?22:14;wrapMode:Text.NoWrap }
                                }
                                Component { id:navItem
                                    Basic.Button {
                                        id:nav;readonly property int index:parent.entry.page;readonly property var info:win.pages[index]
                                        implicitHeight:frame.compact?34:40;hoverEnabled:true;ToolTip.visible:frame.narrow&&hovered;ToolTip.text:info.name;onClicked:win.go(index)
                                        contentItem:RowLayout {spacing:11;Icon{name:nav.info.icon;size:20;color:win.page===nav.index?Theme.glow:Theme.outline} DeckText{visible:!frame.narrow;text:nav.info.name;color:win.page===nav.index?Theme.glow:Theme.surfaceVariantOn;Layout.fillWidth:true;font.weight:win.page===nav.index?Font.DemiBold:Font.Normal;elide:Text.ElideRight;wrapMode:Text.NoWrap}}
                                        background:Item {
                                            Face {anchors.fill:parent;radius:7;usePlain:true;hovered:nav.hovered;on:win.page===nav.index
                                                plainColor:win.page===nav.index?Qt.alpha(Theme.glow,0.09):nav.hovered?Theme.surfaceContainerLow:"transparent";plainBorder:nav.activeFocus?Theme.glow:"transparent"}
                                            Rectangle{anchors.left:parent.left;anchors.verticalCenter:parent.verticalCenter;width:3;height:18;radius:1;color:Theme.glow;visible:win.page===nav.index&&Skin.control==="mechanicus"}
                                        }
                                        leftPadding:14
                                    }
                                }

                                }
                            }
                            DeckText{visible:!frame.compact&&!frame.narrow;text:"Super+,  settings";color:Theme.outline;font.pixelSize:11;Layout.leftMargin:14;Layout.bottomMargin:6}
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
                                DeckText{readonly property string t:win.query?"Find your controls":win.pages[win.page].name;text:t;Layout.fillWidth:true
                                    // the page name in the faction's display face
                                    font.family:frame.plain?Theme.fontUi:Skin.display(t);font.weight:frame.plain?Font.DemiBold:Skin.titleWeight
                                    font.pixelSize:Math.round((frame.compact?22:30)*(frame.plain?1:Skin.titleScale));font.letterSpacing:frame.plain?0:Skin.type==="khorne"?0.5:2
                                    color:frame.plain?Theme.surfaceOn:Skin.type==="ultramarines"||Skin.type==="khorne"?Theme.brassHi:Theme.glow}
                                DeckText{visible:!frame.compact;text:win.query?"Jump straight to the setting you need.":win.pages[win.page].detail;color:Theme.surfaceVariantOn;font.pixelSize:13;Layout.fillWidth:true}
                            }
                            DeckButton {visible:!win.query&&[0,2,3,4,10,11,12,13].includes(win.page);text:"Reset page";onClicked:win.resetPage()}
                        }
                        ScrollView {
                            id:scroll;Layout.fillWidth:true;Layout.fillHeight:true;Layout.minimumHeight:120;clip:true;contentWidth:availableWidth
                            ColumnLayout {
                                width:scroll.availableWidth;spacing:14
                                PrivacyPage{stage:Privacy.onboarding?win.setupStep:-1;visible:!win.query&&win.page===6;Layout.fillWidth:true}
                                BrowserPage{visible:!win.query&&win.page===7;Layout.fillWidth:true}
                                UpdatesPage{visible:!win.query&&win.page===8;Layout.fillWidth:true}
                                Loader{active:win.mine&&!win.query&&win.page===9;visible:active;Layout.fillWidth:true;sourceComponent:ThemesPage{}}   // built only while shown
                                Loader{active:win.mine&&!win.query&&win.page===10;visible:active;Layout.fillWidth:true;sourceComponent:EffectsPage{}}   // built only while shown
                                Loader{active:win.mine&&!win.query&&win.page===11;visible:active;Layout.fillWidth:true;sourceComponent:BarPage{}}   // built only while shown
                                Loader{active:win.mine&&!win.query&&win.page===12;visible:active;Layout.fillWidth:true;sourceComponent:WidgetsPage{}}   // built only while shown
                                Loader{active:win.mine&&!win.query&&win.page===13;visible:active;Layout.fillWidth:true;sourceComponent:NotificationsPage{}}   // built only while shown
                                ColumnLayout {
                                    visible:win.query!=="";Layout.fillWidth:true;spacing:8
                                    Repeater {model:win.searchItems.filter(x=>(x.title+" "+x.hint).toLowerCase().includes(win.query.toLowerCase()))
                                        DeckButton {required property var modelData;Layout.fillWidth:true;implicitHeight:52;text:modelData.title+"   ·   "+win.pages[modelData.page].name+"   ›";onClicked:win.seek(modelData)}
                                    }
                                    DeckText {visible:win.searchItems.filter(x=>(x.title+" "+x.hint).toLowerCase().includes(win.query.toLowerCase())).length===0;text:"No settings found. Try “mouse”, “glow”, “sparks” or “lock”.";color:Theme.outline;Layout.fillWidth:true}
                                }
                                ColumnLayout {
                                    visible:!win.query&&win.page===0;Layout.fillWidth:true;spacing:14
                                    Rectangle {
                                        Layout.fillWidth:true;implicitHeight:frame.height<700?136:180;radius:10;color:Theme.surfaceContainerLowest;border.color:Theme.outlineVariant
                                        Image{anchors.fill:parent;anchors.margins:1;source:Theme.wallpaper?"file://"+Theme.wallpaper:"";fillMode:Image.PreserveAspectCrop;opacity:0.18}
                                        Rectangle{anchors.fill:parent;color:Qt.alpha(Theme.glass,0.35);radius:10}
                                        Item {
                                            anchors{fill:parent;margins:20}
                                            Rectangle{id:mini;anchors.left:parent.left;anchors.verticalCenter:parent.verticalCenter;width:parent.width*0.55;height:Math.min(108,parent.height);radius:6;color:Theme.surfaceContainerLowest;border.color:Theme.metalHi
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
                                    DeckCard {title:"Shell finish";subtitle:"Panels, the bar and the instruments. Colours and materials come from the theme."
                                        DeckRange{title:"Panel opacity";value:Math.round((win.d.panelOpacity??1)*100);from:60;to:100;step:5;unit:"%";onChanged:v=>Settings.set("panelOpacity",Math.round(v)/100)}
                                        DeckRange{title:"Glow strength";value:Math.round((win.d.glowStrength??1)*100);from:0;to:150;step:10;unit:"%";onChanged:v=>Settings.set("glowStrength",Math.round(v)/100)}
                                        DeckText{visible:!!win.d.lowPower;text:"Glow is paused while low power mode is on.";color:Theme.hazard;font.pixelSize:12;Layout.fillWidth:true}
                                        DeckDivider{}
                                        DeckSegments{title:"Decoration";value:win.d.ornaments||"full";onChanged:v=>Settings.set("ornaments",v)
                                            options:[{id:"full",name:"Full",hint:"Seals, heraldry, guardians and the faction's bar fittings."},{id:"reduced",name:"Reduced",hint:"Frames and fittings stay; seals, heraldry and guardians are put away."},{id:"off",name:"Plain",hint:"Bare instruments: no fittings between the bar's mounts, no ornament."}]}
                                    }
                                    RowLayout{Layout.fillWidth:true;spacing:8
                                        DeckButton{text:"Themes ›";Layout.fillWidth:true;implicitHeight:42;onClicked:win.go(9)}
                                        DeckButton{text:"Wallpaper archive ↗";Layout.fillWidth:true;implicitHeight:42;onClicked:{if(Settings.dirty) Settings.requestClose();else {Settings.open=false;Walls.toggle()}}}
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
                                    DeckCard {title:"When you step away";subtitle:"Lock first. Let the displays rest afterwards."
                                        RowLayout{Layout.fillWidth:true;DeckText{text:"Lock after";Layout.fillWidth:true} DeckChoice{property var times:[60,120,300,600,900,1800,3600].concat([win.d.lockSeconds||600]).filter((v,i,a)=>a.indexOf(v)===i).sort((a,b)=>a-b);model:times.map(x=>(x/60)+" min");currentIndex:times.indexOf(win.d.lockSeconds||600);onActivated:{const n=times[currentIndex];Settings.patch({lockSeconds:n,screenOffSeconds:Math.max(n,win.d.screenOffSeconds)})}}}
                                        RowLayout{Layout.fillWidth:true;DeckText{text:"Turn screens off after";Layout.fillWidth:true} DeckChoice{property var times:[60,120,300,600,900,1800,3600,7200].concat([win.d.screenOffSeconds||900]).filter((v,i,a)=>v>=(win.d.lockSeconds||600)&&a.indexOf(v)===i).sort((a,b)=>a-b);model:times.map(x=>(x/60)+" min");currentIndex:times.indexOf(win.d.screenOffSeconds||900);onActivated:Settings.set("screenOffSeconds",times[currentIndex])}}
                                        Rectangle{Layout.fillWidth:true;implicitHeight:56;radius:7;color:Theme.surfaceContainerLowest
                                            RowLayout{anchors.fill:parent;anchors.margins:12;Icon{name:"lock";size:21;color:Theme.glowDim} DeckText{text:"Super+L locks immediately. Your session also locks before sleep.";Layout.fillWidth:true;font.pixelSize:12;color:Theme.surfaceVariantOn}}
                                        }
                                        DeckSegments{title:"Lock screen";value:win.d.lockBackend||"quickshell";onChanged:v=>Settings.set("lockBackend",v)
                                            options:[{id:"quickshell",name:"MachineSpirit",hint:"The shell's own lock screen, in the current theme."},{id:"hyprlock",name:"hyprlock",hint:"The separate hyprlock program, if it is installed."}]}
                                    }
                                    DeckCard {title:"Controls"
                                        DeckRange{title:"Hold to confirm";value:(win.d.holdMs??800)/1000;from:0.4;to:2.5;step:0.1;decimals:1;unit:" s";onChanged:v=>Settings.set("holdMs",Math.round(v*10)*100)}
                                        DeckText{text:"How long Reboot, Shut down and Log out must be held before they act.";Layout.fillWidth:true;font.pixelSize:12;color:Theme.surfaceVariantOn}
                                        DeckDivider{}
                                        DeckToggle{title:"Tap Super to open the console";hint:"Off leaves Super for shortcuts only; the console keeps its own shortcut";checked:win.d.superTap!==false;onChanged:v=>Settings.set("superTap",v)}
                                        DeckDivider{}
                                        RowLayout{Layout.fillWidth:true;spacing:12
                                            ColumnLayout{Layout.fillWidth:true;spacing:3
                                                DeckText{text:"Restart the shell";Layout.fillWidth:true}
                                                DeckText{text:"Bar, panels and widgets start again. Windows and the session are not touched.";Layout.fillWidth:true;font.pixelSize:12;color:Theme.surfaceVariantOn}
                                            }
                                            DeckButton{text:"Restart";implicitHeight:42;enabled:!Settings.unsaved;onClicked:Quickshell.execDetached(["ms-session","restart"])}
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
