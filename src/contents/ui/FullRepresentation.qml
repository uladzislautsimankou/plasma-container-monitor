import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import "components"

ColumnLayout {
    id: root

    property var look
    property var backends: []
    property var current: null
    property bool hasBackground: true
    property bool followLogs: true
    property bool inheritLevel: true

    property int wantedWidth: 440
    property int wantedHeight: 520
    property bool trackSize: false

    signal containerChosen(var backend)
    signal sizeSettled(int width, int height)

    Layout.minimumWidth: 320
    Layout.preferredWidth: wantedWidth
    Layout.preferredHeight: wantedHeight

    Timer {
        id: sizeTimer
        interval: 600
        onTriggered: root.sizeSettled(Math.round(root.width), Math.round(root.height))
    }
    onWidthChanged: if (trackSize && width > 0) sizeTimer.restart()
    onHeightChanged: if (trackSize && height > 0) sizeTimer.restart()

    readonly property bool multi: backends.length > 1

    spacing: 8

    PlasmaComponents.Label {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: root.backends.length === 0
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.Wrap
        color: root.look.textSecondary
        font.family: root.look.fontFamily
        text: i18n("No sources. Enable local containers or add a server in the widget settings.")
    }

    Repeater {
        model: root.backends

        delegate: HostBlock {
            id: block

            required property var modelData
            required property int index

            Layout.fillWidth: true
            Layout.fillHeight: !hasContainers && !root.multi
            Layout.topMargin: index > 0 ? 6 : 0

            look: root.look
            backend: modelData
            hasBackground: root.hasBackground
            current: root.current === modelData
            compact: root.multi
            maxListHeight: root.multi
                ? Math.max(56, Math.floor(root.height * 0.5 / root.backends.length) - 30)
                : 220
            onChosen: root.containerChosen(modelData)
        }
    }

    Loader {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 120
        active: root.current !== null && !!root.current.selected
        visible: active

        sourceComponent: LogView {
            look: root.look
            backend: root.current
            showHost: root.multi
            hasBackground: root.hasBackground
            follow: root.followLogs
            inheritLevel: root.inheritLevel
        }
    }
}
