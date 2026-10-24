import QtQuick
import QtQuick.Controls as QQC2

QQC2.ScrollView {
    id: root

    property var look
    property var backend
    property bool hasBackground: true
    property int maxHeight: 220
    property string highlightId: ""

    signal chosen()

    readonly property real desiredHeight: Math.min(Math.max(list.contentHeight, 40), maxHeight)

    clip: true
    QQC2.ScrollBar.vertical.policy: root.hasBackground ? QQC2.ScrollBar.AsNeeded : QQC2.ScrollBar.AlwaysOff

    ListView {
        id: list
        model: root.backend.containers
        spacing: 2

        delegate: ContainerDelegate {
            required property var modelData

            width: ListView.view.width
            look: root.look
            container: modelData
            stat: root.backend.statsFor(modelData)
            selected: root.highlightId === modelData.id
            showStats: root.backend.showStats

            onClicked: {
                root.chosen();
                root.backend.select(modelData.id);
            }
            onActionRequested: action => root.backend.runAction(action, modelData.id)
        }
    }
}
