// [ PURITY SEAL ] Keep the signal clear. Preserve the entrusted work.
import QtQuick
import QtQuick.Controls
import qs.common
import qs.services
Instrument {
    id: root
    housing: "tape"
    title: Theme.lex("notes", "Memorandum"); serial: "05 / LOG"; corner: 5; quiet: true
    TextInput { id: heading; width: parent.width; height: 24; text: DesktopWidgets.state.note.title; selectByMouse: true; clip: true; color: Theme.glow; selectionColor: Theme.glowFaint
        font { family: Theme.fontNum; pixelSize: 17; weight: Font.Medium }
        onTextEdited: DesktopWidgets.note(text, body.text)
        onActiveFocusChanged: if (!activeFocus) DesktopWidgets.flush()
        Keys.onEscapePressed: { focus = false; DesktopWidgets.flush() }
    }
    // Ruled lines sit under each line of text, following the note's own line spacing.
    FontMetrics { id: lines; font: body.font }
    Repeater { model: Math.max(0, Math.floor((root.height - 56 - 15 - 42) / lines.lineSpacing))
        Rectangle { required property int index; x: 0; y: 32 + (index + 1) * lines.lineSpacing; width: parent.width; height: 1; color: Qt.alpha(Theme.glow, 0.07) }
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
        text: DesktopWidgets.status; color: DesktopWidgets.error ? Theme.rustText : Theme.glowDim; font { family: Theme.fontNum; pixelSize: 11 } }
}
