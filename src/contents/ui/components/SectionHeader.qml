import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    property var look
    property string title
    property string subtitle
    default property alias actions: actionsRow.data

    spacing: 4

    RowLayout {
        Layout.fillWidth: true

        StyledLabel {
            look: root.look
            role: "header"
            sizeOffset: 1
            text: root.title
            font.weight: Font.DemiBold
        }
        StyledLabel {
            look: root.look
            role: "secondary"
            text: root.subtitle ? " |  " + root.subtitle : ""
            elide: Text.ElideRight
            Layout.fillWidth: true
        }
        RowLayout {
            id: actionsRow
            spacing: 6
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: root.look ? root.look.separator : "transparent"
    }
}
