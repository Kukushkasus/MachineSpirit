// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import QtQuick.Controls
import qs.common
import qs.services
Instrument {
    id: root
    housing: "tape"
    title: "Memorandum"; serial: "05 / LOG"; corner: 5; quiet: true
    TextInput { id: heading; width: parent.width; height: 24; text: DesktopWidgets.state.note.title; selectByMouse: true; clip: true; color: Theme.glow; selectionColor: Theme.glowFaint
        font { family: Theme.fontNum; pixelSize: 17; weight: Font.Medium }
        onTextEdited: DesktopWidgets.note(text, body.text)
        onActiveFocusChanged: if (!activeFocus) DesktopWidgets.flush()
        Keys.onEscapePressed: { focus = false; DesktopWidgets.flush() }
    }
    Repeater { model: 6
        Rectangle { required property int index; x: 0; y: 48 + index * 23; width: parent.width; height: 1; color: Qt.alpha(Theme.glow, 0.06) }
    }
    Flickable { x: 0; y: 32; width: parent.width; height: parent.height - 56; clip: true; contentHeight: body.height
        TextArea { id: body; width: parent.width; height: Math.max(140, implicitHeight); text: DesktopWidgets.state.note.text; padding: 0
            placeholderText: "Write a note…"; placeholderTextColor: Theme.glowDim; color: Theme.glowDim; selectionColor: Theme.glowFaint; wrapMode: TextEdit.Wrap; selectByMouse: true
            background: null; font { family: Theme.fontNum; pixelSize: 14 } persistentSelection: true
            onTextChanged: if (activeFocus) DesktopWidgets.note(heading.text, text)
            onActiveFocusChanged: if (!activeFocus) DesktopWidgets.flush()
            Keys.onEscapePressed: { focus = false; DesktopWidgets.flush() }
        }
        ScrollBar.vertical: ScrollBar { }
    }
    Text { anchors { bottom: parent.bottom; right: parent.right } width: parent.width; horizontalAlignment: Text.AlignRight; elide: Text.ElideRight
        text: DesktopWidgets.status; color: DesktopWidgets.error ? Theme.rustText : Theme.glowDim; font { family: Theme.fontNum; pixelSize: 10 } }
}
