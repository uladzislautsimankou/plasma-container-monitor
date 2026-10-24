import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.components as PlasmaComponents

ColumnLayout {
    id: root

    property var look
    property var backend
    property bool hasBackground: true
    property bool current: false
    property bool compact: false
    property int maxListHeight: 220

    signal chosen()

    readonly property bool hasContainers: backend.status === "ok" && backend.containers.length > 0

    spacing: 6

    SectionHeader {
        Layout.fillWidth: true
        look: root.look
        title: root.backend.title
        subtitle: {
            if (!root.hasContainers) return "";
            var s = i18n("%1 running", root.backend.runningCount);
            if (root.backend.showAll)
                s += " " + i18n("(%1 total)", root.backend.containers.length);
            return s;
        }

        PlasmaComponents.ToolButton {
            icon.name: "view-filter"
            implicitWidth: 22
            implicitHeight: 22
            checkable: true
            checked: root.backend.showAll
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.text: root.backend.showAll
                ? i18n("Showing all (click for running only)")
                : i18n("Showing running only (click for all)")
            onClicked: root.backend.showAll = checked
        }

        PlasmaComponents.ToolButton {
            icon.name: "view-refresh"
            implicitWidth: 22
            implicitHeight: 22
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.text: i18n("Refresh")
            onClicked: root.backend.refresh()
        }
    }

    EmptyState {
        Layout.fillWidth: true
        Layout.fillHeight: !root.compact
        Layout.preferredHeight: root.compact ? 84 : -1
        visible: !root.hasContainers

        look: root.look
        compact: root.compact
        kind: root.backend.status === "ok" ? "empty" : root.backend.status
        binary: root.backend.title
        showAll: root.backend.showAll
        errorMessage: root.backend.errorMessage
        onShowAllRequested: root.backend.showAll = true
    }

    ContainerList {
        Layout.fillWidth: true
        Layout.preferredHeight: desiredHeight
        visible: root.hasContainers

        look: root.look
        backend: root.backend
        hasBackground: root.hasBackground
        maxHeight: root.maxListHeight
        highlightId: root.current ? root.backend.selectedId : ""
        onChosen: root.chosen()
    }
}
