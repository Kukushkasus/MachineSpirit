// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import qs.common
import qs.services

// Pict archive on a cogitator screen: sources and order on top, the query line with colour lenses, picts in phosphor frames.
// Click a pict to make it the wallpaper (the whole shell recolours), right-click or Space to inspect it.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData
        // created lazily: `ready` flips right after creation so the opening animation still runs
        property bool ready: false
        Component.onCompleted: Qt.callLater(() => ready = true)
        readonly property bool mine: ready && Walls.open && (Settings.primary()?.name ?? modelData.name) === modelData.name
        property int sel: 0
        property var inspect: null
        readonly property int cols: frame.width < 1100 ? 3 : 4

        visible: mine || frame.opacity > 0.01
        WlrLayershell.namespace: "machinespirit-walls"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: mine ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        onMineChanged: if (mine) { inspect = null; sel = 0; field.forceActiveFocus() }

        function keys(event) {
            const k = event.key
            if (k === Qt.Key_Escape) { if (inspect) inspect = null; else Walls.close() }
            else if (inspect && (k === Qt.Key_Return || k === Qt.Key_Enter)) { Walls.apply(inspect); inspect = null }
            else if (k === Qt.Key_Right) sel = Math.min(Walls.items.length - 1, sel + 1)
            else if (k === Qt.Key_Left) sel = Math.max(0, sel - 1)
            else if (k === Qt.Key_Down) sel = Math.min(Walls.items.length - 1, sel + cols)
            else if (k === Qt.Key_Up) sel = Math.max(0, sel - cols)
            else if ((k === Qt.Key_Return || k === Qt.Key_Enter) && Walls.items[sel]) Walls.apply(Walls.items[sel])
            else if (k === Qt.Key_Space && Walls.items[sel] && !field.activeFocus) inspect = Walls.items[sel]
            else if (k === Qt.Key_PageDown) Walls.nextPage()
            else if (k === Qt.Key_PageUp) Walls.prevPage()
            else return false
            return true
        }

        Rectangle { anchors.fill: parent; color: Theme.glass; opacity: win.mine ? 0.6 : 0; Behavior on opacity { NumberAnimation { duration: Theme.dMedium } }
            MouseArea { anchors.fill: parent; onClicked: Walls.close() } }

        Item {
            id: frame
            width: Math.min(win.width - 80, 1360)
            height: Math.min(win.height - 110, 820)
            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 70 }
            opacity: win.mine ? 1 : 0
            scale: win.mine ? 1 : 0.97
            Behavior on opacity { NumberAnimation { duration: Theme.dMedium } }
            Behavior on scale { NumberAnimation { duration: Theme.dMedium; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeDecel } }
            MouseArea { anchors.fill: parent }
            focus: true
            Keys.onPressed: event => event.accepted = win.keys(event)

            // a cogitator screen: bezel, glass that powers on, phosphor heading
            Bezel { anchors.fill: parent; radius: 14; inset: 0; boltSize: 6; role: "window" }
            CrtScreen { id: archiveGlass; anchors { fill: parent; margins: 8 } radius: 8; padding: 0; bootOnLoad: false; ambient: false }
            Connections { target: win; function onMineChanged() { if (win.mine) archiveGlass.powerOn() } }
            ScreenTitle { anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 20 } text: Theme.lex("archiveTitle", "Pict Archive") }
            BrassMini { anchors { right: parent.right; top: parent.top; margins: 18 } icon: "close"; onClicked: Walls.close() }

            BrassMini { anchors { left: parent.left; top: parent.top; margins: 18 } label: "Desktop widgets"; icon: "widgets"; onClicked: { Walls.close(); DesktopWidgets.editing = true } }

            // ---------------- sources: phosphor tabs along the top
            Row {
                id: tabs
                x: 20; y: 54
                spacing: 6
                Repeater {
                    model: Walls.sources
                    Item {
                        id: tab
                        required property var modelData
                        readonly property bool chosen: Walls.source === modelData.id
                        width: tabText.implicitWidth + (modelData.needsKey ? 54 : 36); height: 34
                        Tile { anchors.fill: parent; radius: 6; padding: 0; lit: tab.chosen; opacity: tab.chosen || tm.containsMouse ? 1 : 0.55 }
                        Rectangle { x: 10; anchors.verticalCenter: parent.verticalCenter; width: 6; height: 6; radius: 3; color: tab.chosen ? Theme.glow : Theme.glowFaint }
                        Text { id: tabText; x: 24; anchors.verticalCenter: parent.verticalCenter; text: tab.modelData.name
                            color: tab.chosen ? Theme.glow : Theme.glowDim; font { family: Theme.fontNum; pixelSize: 14; weight: Font.DemiBold } renderType: Text.NativeRendering }
                        Icon { visible: tab.modelData.needsKey; anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter } name: "key"; size: 14
                            color: tab.chosen ? Theme.glow : Theme.glowFaint }
                        MouseArea { id: tm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Walls.setSource(tab.modelData.id) }
                    }
                }
            }
            // order: a segmented switch on the right of the tabs
            Row {
                anchors { right: parent.right; rightMargin: 62; verticalCenter: tabs.verticalCenter }
                visible: Walls.current.sorts.length > 0
                spacing: 0
                Repeater {
                    model: Walls.current.sorts
                    Item {
                        id: seg
                        required property string modelData
                        required property int index
                        readonly property bool on: Walls.sort === modelData
                        width: segText.implicitWidth + 24; height: 30
                        Rectangle {
                            anchors.fill: parent
                            radius: 5
                            color: seg.on ? Qt.alpha(Theme.glow, 0.85) : (sgm.containsMouse ? Qt.alpha(Theme.glow, 0.12) : Qt.alpha(Theme.glow, 0.04))
                            border { width: 1; color: Qt.alpha(Theme.glow, 0.3) }
                        }
                        Text { id: segText; anchors.centerIn: parent; text: ({ top: "Top", latest: "Newest", random: "Random", relevance: "Best match" })[seg.modelData]
                            color: seg.on ? Theme.glass : Theme.glowDim; font { family: Theme.fontNum; pixelSize: 13; weight: Font.DemiBold } renderType: Text.NativeRendering }
                        MouseArea { id: sgm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Walls.setSort(seg.modelData) }
                    }
                }
            }

            // ---------------- query line + lens button
            property bool lensOpen: false
            Tile {
                id: queryBox
                x: 20; y: tabs.y + tabs.height + 12
                width: frame.width - 40 - (lensBtn.visible ? lensBtn.width + 10 : 0); height: 42; radius: 6; padding: 0
                Glow { x: 12; anchors.verticalCenter: parent.verticalCenter; font { family: Theme.fontMono; pixelSize: 15; weight: Font.Bold } text: "++>" }
                TextInput {
                    id: field
                    anchors { left: parent.left; leftMargin: 52; right: status.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
                    color: Theme.glow; selectionColor: Theme.glowFaint
                    font { family: Theme.fontMono; pixelSize: 15 }
                    clip: true
                    onTextChanged: Walls.setQuery(text)
                    Keys.onPressed: event => {
                        if ([Qt.Key_Escape, Qt.Key_Down, Qt.Key_Up, Qt.Key_PageDown, Qt.Key_PageUp, Qt.Key_Return, Qt.Key_Enter].includes(event.key)) event.accepted = win.keys(event)
                    }
                    Text { anchors.fill: parent; verticalAlignment: Text.AlignVCenter; visible: field.text === ""
                        text: Walls.source === "local" ? "search your wallpapers by name" : "search " + Walls.current.name + ": forge, gothic, rain, mechanicus"; color: Theme.glowFaint; font: field.font }
                }
                Glow {
                    id: status
                    anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                    halo: 0.4; color: Walls.status !== "" ? Theme.glow : Theme.glowDim
                    font { family: Theme.fontMono; pixelSize: 12 }
                    text: Walls.status !== "" ? Walls.status : (Walls.busy ? "consulting the archive" : Walls.total + " found")
                }
            }
            Item {
                id: lensBtn
                visible: Walls.current.colors
                anchors { right: parent.right; rightMargin: 20; verticalCenter: queryBox.verticalCenter }
                width: 92; height: 42
                Tile { anchors.fill: parent; radius: 6; padding: 0; lit: frame.lensOpen }
                Row {
                    anchors.centerIn: parent; spacing: 6
                    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 18; height: 18; radius: 9
                        color: Walls.color !== "" ? "#" + Walls.color : "transparent"; border { width: 1.5; color: Theme.glow }
                        Icon { anchors.centerIn: parent; visible: Walls.color === ""; name: "palette"; size: 12; color: Theme.glow } }
                    Text { anchors.verticalCenter: parent.verticalCenter; text: "Lens"; color: Theme.glow
                        font { family: Theme.fontNum; pixelSize: 14; weight: Font.DemiBold } renderType: Text.NativeRendering }
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: frame.lensOpen = !frame.lensOpen }
            }
            // lens drawer
            Item {
                id: lensBar
                x: 20; y: queryBox.y + queryBox.height + 8
                width: frame.width - 40
                height: frame.lensOpen && Walls.current.colors ? 40 : 0
                clip: true
                Behavior on height { NumberAnimation { duration: Theme.dShort; easing.type: Easing.OutCubic } }
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 5
                    Repeater {
                        model: Walls.lenses
                        Item {
                            id: lens
                            required property string modelData
                            readonly property bool on: Walls.color === modelData
                            width: 30; height: 30
                            Rectangle { anchors.fill: parent; radius: 15; color: "transparent"; border { width: lens.on ? 2 : 1; color: lens.on ? Theme.glow : Theme.glowFaint } }
                            Rectangle { anchors.centerIn: parent; width: 22; height: 22; radius: 11; color: "#" + lens.modelData
                                Rectangle { x: 4; y: 3; width: 6; height: 6; radius: 3; color: Qt.rgba(1, 1, 1, 0.35) } }
                            scale: lm.containsMouse ? 1.12 : 1
                            Behavior on scale { NumberAnimation { duration: Theme.dShort } }
                            MouseArea { id: lm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Walls.setColor(lens.modelData) }
                        }
                    }
                    BrassMini { visible: Walls.color !== ""; label: "Clear"; onClicked: Walls.setColor(Walls.color) }
                }
            }

            // ---------------- picts
            Item {
                id: gallery
                x: 20; y: lensBar.y + lensBar.height + 8
                width: frame.width - 40
                height: frame.height - y - 74
                clip: true

                GridView {
                    id: grid
                    anchors.fill: parent
                    visible: !Walls.needKey
                    cellWidth: width / win.cols
                    cellHeight: cellWidth * 9 / 16
                    bottomMargin: 64          // room to scroll past the floating dock
                    model: Walls.items
                    currentIndex: win.sel
                    onCurrentIndexChanged: positionViewAtIndex(currentIndex, GridView.Contain)
                    boundsBehavior: Flickable.StopAtBounds
                    delegate: Item {
                        id: cell
                        required property var modelData
                        required property int index
                        readonly property bool chosen: win.sel === index
                        readonly property bool isCurrent: modelData.local && Theme.sourceWallpaper === modelData.full
                        width: grid.cellWidth; height: grid.cellHeight
                        Item {
                            anchors { fill: parent; margins: 6 }
                            scale: pm.containsMouse ? 1.03 : 1
                            Behavior on scale { NumberAnimation { duration: Theme.dShort; easing.type: Easing.OutCubic } }
                            Rectangle {   // thin phosphor frame
                                anchors.fill: parent; radius: 6
                                color: Theme.glass
                                border { width: cell.isCurrent ? 2 : 1; color: cell.isCurrent ? Theme.glow : (cell.chosen ? Theme.glowDim : Theme.glowFaint) }
                            }
                            Item {
                                anchors { fill: parent; margins: 2 }
                                clip: true
                                Image {
                                    id: img
                                    anchors.fill: parent
                                    source: cell.modelData.local ? "file://" + cell.modelData.thumb : cell.modelData.thumb
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    sourceSize: Qt.size(480, 270)
                                    opacity: status === Image.Ready ? 1 : 0
                                    Behavior on opacity { NumberAnimation { duration: Theme.dMedium } }
                                }
                                Glow { anchors.centerIn: parent; visible: img.status !== Image.Ready; halo: 0; color: Theme.glowFaint; font.pixelSize: 12; text: img.status === Image.Error ? "lost" : "loading" }
                                Rectangle {   // details strip on hover
                                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                                    height: 26; visible: pm.containsMouse
                                    color: Qt.alpha(Theme.glass, 0.82)
                                    Glow { x: 8; anchors.verticalCenter: parent.verticalCenter; width: parent.width - 90; elide: Text.ElideRight; halo: 0; font.pixelSize: 11
                                        text: cell.modelData.resolution + (cell.modelData.credit ? "  " + cell.modelData.credit : "") }
                                    Row { anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter } spacing: 3
                                        Repeater { model: cell.modelData.colors.slice(0, 5)
                                            Rectangle { required property string modelData; width: 10; height: 10; radius: 5; color: "#" + modelData; border { width: 1; color: Theme.glowDim } } } }
                                }
                                Rectangle {
                                    anchors.fill: parent
                                    visible: Walls.applying === cell.modelData.id
                                    color: Qt.alpha(Theme.glass, 0.7)
                                    Column {   // consecrating: a ring of segments with a running light, drawn on the glass
                                        anchors.centerIn: parent
                                        spacing: 8
                                        Item {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            width: 46; height: 46
                                            Repeater {
                                                model: 12
                                                Rectangle {
                                                    required property int index
                                                    x: 23 + Math.cos(index / 12 * Math.PI * 2) * 17 - 2; y: 23 + Math.sin(index / 12 * Math.PI * 2) * 17 - 5
                                                    width: 4; height: 10; radius: 2
                                                    rotation: index / 12 * 360 + 90
                                                    color: Qt.alpha(Theme.glow, 0.2)
                                                }
                                            }
                                            Item {   // the running light: three lit segments that sweep round
                                                id: sweep
                                                anchors.fill: parent
                                                Repeater {
                                                    model: 3
                                                    Rectangle {
                                                        required property int index
                                                        x: 23 + Math.cos(-index / 12 * Math.PI * 2) * 17 - 2; y: 23 + Math.sin(-index / 12 * Math.PI * 2) * 17 - 5
                                                        width: 4; height: 10; radius: 2
                                                        rotation: -index / 12 * 360 + 90
                                                        color: Theme.glow; opacity: 1 - index * 0.3
                                                    }
                                                }
                                                RotationAnimator on rotation { from: 0; to: 360; duration: 1100; loops: Animation.Infinite; running: sweep.visible && Walls.applying !== "" }
                                            }
                                        }
                                        Glow { anchors.horizontalCenter: parent.horizontalCenter; halo: 0.4
                                            font { family: Theme.fontNum; pixelSize: 11; weight: Font.Bold; letterSpacing: 2; capitalization: Font.AllUppercase }
                                            text: "Consecrating" }
                                    }
                                }
                            }
                            Rectangle {   // "current" tag
                                visible: cell.isCurrent
                                anchors { left: parent.left; top: parent.top; margins: 8 }
                                width: curT.implicitWidth + 14; height: 20; radius: 5; color: Theme.glow
                                Text { id: curT; anchors.centerIn: parent; text: "Current"; color: Theme.glass; renderType: Text.NativeRendering
                                    font { family: Theme.fontNum; pixelSize: 11; weight: Font.Bold } }
                            }
                            MouseArea {
                                id: pm
                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onEntered: win.sel = cell.index
                                onClicked: mouse => { if (mouse.button === Qt.RightButton) win.inspect = cell.modelData; else Walls.apply(cell.modelData) }
                            }
                        }
                    }
                }

                Glow {
                    anchors.centerIn: parent
                    visible: Walls.error !== "" && !Walls.needKey
                    halo: 0.4; color: Theme.rustText
                    font { family: Theme.fontMono; pixelSize: 14 }
                    text: "+++ " + Walls.error + " +++"
                }

                Tile {
                    visible: Walls.needKey
                    anchors.centerIn: parent
                    width: 520; height: 170; radius: 6; padding: 16
                    Column {
                        anchors.fill: parent; spacing: 10
                        Glow { font { pixelSize: 16; weight: Font.DemiBold } text: Walls.current.name + " needs an access key" }
                        Glow { width: parent.width; wrapMode: Text.Wrap; halo: 0; color: Theme.glowDim; font { family: Theme.fontUi; pixelSize: 13 } text: Walls.keyHint + ". It stays on this machine in ~/.config/machinespirit/keys.conf." }
                        Rectangle {
                            width: parent.width; height: 34; radius: 4; color: Theme.glassHi; border { width: 1; color: Theme.glowFaint }
                            TextInput {
                                id: keyField
                                anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                                verticalAlignment: TextInput.AlignVCenter
                                color: Theme.glow; echoMode: TextInput.Password
                                font { family: Theme.fontMono; pixelSize: 14 }
                                onAccepted: if (text.trim() !== "") Walls.setKey(text.trim())
                            }
                        }
                        Row { spacing: 8
                            BrassMini { label: "Save key"; icon: "key"; onClicked: if (keyField.text.trim() !== "") Walls.setKey(keyField.text.trim()) }
                            BrassMini { label: "Get a key"; icon: "open_in_new"; onClicked: Quickshell.execDetached(["xdg-open", Walls.source === "unsplash" ? "https://unsplash.com/developers" : "https://www.pexels.com/api/"]) }
                        }
                    }
                }
            }

            Flicker { anchors { fill: parent; margins: 8 } radius: 8; active: win.mine; z: 50 }

            // ---------------- floating action dock
            Item {
                id: dock
                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 14 }
                width: dockRow.implicitWidth + 28; height: 50
                Rectangle { anchors.fill: parent; radius: 12; color: Qt.darker(Theme.glass, 1.2); border { width: 1; color: Qt.alpha(Theme.glow, 0.3) } }
                Row {
                    id: dockRow
                    anchors.centerIn: parent
                    spacing: 8
                    BrassMini { icon: "casino"; label: "Surprise me"; onClicked: Walls.applyRandom() }
                    BrassMini { icon: "folder_open"; label: "Open folder"; onClicked: Walls.openFolder() }
                    BrassMini { icon: "refresh"; label: "Refresh"; onClicked: Walls.search() }
                    Rectangle { width: 1; height: 26; color: Theme.glowFaint; anchors.verticalCenter: parent.verticalCenter }
                    BrassMini { icon: "chevron_left"; opacity: Walls.page > 1 ? 1 : 0.4; onClicked: Walls.prevPage() }
                    Glow { anchors.verticalCenter: parent.verticalCenter; halo: 0; color: Theme.glow; font { family: Theme.fontNum; pixelSize: 14; weight: Font.DemiBold } text: Walls.page + " / " + Walls.pages }
                    BrassMini { icon: "chevron_right"; opacity: Walls.page < Walls.pages ? 1 : 0.4; onClicked: Walls.nextPage() }
                }
            }
        }

        // ---------------- inspection
        Item {
            anchors.fill: parent
            visible: win.inspect !== null
            Rectangle { anchors.fill: parent; color: Qt.alpha(Theme.glass, 0.85); MouseArea { anchors.fill: parent; onClicked: win.inspect = null } }
            Item {
                id: big
                width: Math.min(win.width - 160, 1500); height: width * 9 / 16
                anchors.centerIn: parent; anchors.verticalCenterOffset: -24
                Bezel { anchors { fill: parent; margins: -12 } radius: 14; inset: 0; boltSize: 7 }
                PrivateImage {
                    feature:"wallpapers";manual:true
                    anchors.fill: parent
                    requestSource: win.inspect ? (win.inspect.local ? "file://" + win.inspect.full : win.inspect.full) : ""
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    sourceSize: Qt.size(width * 1.5, height * 1.5)
                    Image { anchors.fill: parent; z: -1; visible: parent.status !== Image.Ready; fillMode: Image.PreserveAspectFit
                        source: win.inspect ? (win.inspect.local ? "file://" + win.inspect.thumb : win.inspect.thumb) : "" }
                }
            }
            Row {
                anchors { horizontalCenter: parent.horizontalCenter; top: big.bottom; topMargin: 26 }
                spacing: 10
                BrassMini { icon: "check"; label: "Make wallpaper"; onClicked: { Walls.apply(win.inspect); win.inspect = null } }
                BrassMini { visible: win.inspect && !win.inspect.local; icon: "download"; label: "Save"; onClicked: Walls.save(win.inspect) }
                BrassMini { icon: "close"; label: "Close"; onClicked: win.inspect = null }
                Glow { anchors.verticalCenter: parent.verticalCenter; halo: 0; color: Theme.glowDim; font.pixelSize: 13
                    text: win.inspect ? win.inspect.resolution + (win.inspect.credit ? ", " + win.inspect.credit : "") : "" }
            }
        }
    }
}
