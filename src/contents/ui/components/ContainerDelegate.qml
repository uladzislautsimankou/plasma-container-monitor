import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

Rectangle {
    id: root

    property var look
    property var container
    property var stat: null
    property bool selected: false
    property bool showStats: true

    signal clicked()
    signal actionRequested(string action)

    readonly property bool running: container ? container.running : false
    readonly property color overlay: look ? look.textMain : Kirigami.Theme.textColor

    height: Math.round((look ? look.fontSize : 11) * 3.5)
    radius: 3
    color: selected
        ? Qt.alpha(overlay, 0.08)
        : (mouse.containsMouse ? Qt.alpha(overlay, 0.04) : "transparent")

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 8

        Rectangle {
            Layout.preferredWidth: 6
            Layout.preferredHeight: 6
            Layout.alignment: Qt.AlignVCenter
            radius: 3
            color: root.running ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.negativeTextColor
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 1

            StyledLabel {
                Layout.fillWidth: true
                look: root.look
                text: root.container ? root.container.name : ""
                font.weight: Font.Medium
                elide: Text.ElideRight
            }
            StyledLabel {
                Layout.fillWidth: true
                look: root.look
                role: "secondary"
                sizeOffset: -2
                text: root.container ? root.container.image : ""
                elide: Text.ElideRight
            }
        }

        RowLayout {
            Layout.preferredWidth: Math.round((root.look ? root.look.fontSize : 11) * 11.5)
            Layout.alignment: Qt.AlignVCenter
            visible: !root.running || root.showStats
            spacing: 0

            Item { Layout.fillWidth: true }

            StyledLabel {
                look: root.look
                role: "values"
                sizeOffset: -1
                visible: root.running
                text: root.stat ? root.stat.cpu : "--"
            }
            StyledLabel {
                look: root.look
                role: "secondary"
                sizeOffset: -1
                visible: root.running
                text: "  |  "
            }
            StyledLabel {
                look: root.look
                role: "values"
                sizeOffset: -1
                visible: root.running
                text: root.stat ? root.stat.mem : "--"
            }
            StyledLabel {
                look: root.look
                role: "secondary"
                sizeOffset: -1
                visible: !root.running
                text: root.container && root.container.state ? root.container.state : i18n("stopped")
            }
        }

        PlasmaComponents.ToolButton {
            id: actionBtn
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            Layout.alignment: Qt.AlignVCenter
            icon.name: root.running ? "media-playback-stop" : "media-playback-start"

            opacity: (mouse.containsMouse || actionBtn.hovered || root.selected) ? 1.0 : 0.0
            enabled: opacity > 0

            QQC2.ToolTip.visible: hovered && opacity > 0
            QQC2.ToolTip.text: root.running ? i18n("Stop") : i18n("Start")
            onClicked: root.actionRequested(root.running ? "stop" : "start")
        }
    }
}
