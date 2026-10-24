import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

Item {
    id: root

    property var look
    // "loading" | "error" | "empty"
    property string kind: "empty"
    property string binary: "podman"
    property bool showAll: false
    property string errorMessage
    property bool compact: false

    signal showAllRequested()

    QQC2.BusyIndicator {
        anchors.centerIn: parent
        visible: root.kind === "loading"
        running: visible
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width - 32, 320)
        visible: root.kind !== "loading"
        spacing: 6

        Kirigami.Icon {
            visible: !root.compact
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Kirigami.Units.iconSizes.large
            Layout.preferredHeight: Kirigami.Units.iconSizes.large
            source: root.kind === "error" ? "dialog-error" : "package-x-generic"
            opacity: 0.6
        }

        StyledLabel {
            Layout.fillWidth: true
            look: root.look
            sizeOffset: 2
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            text: {
                if (root.kind === "error") return i18n("Can't get the container list");
                return root.showAll ? i18n("No containers") : i18n("No running containers");
            }
        }

        StyledLabel {
            Layout.fillWidth: true
            look: root.look
            role: "secondary"
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            text: {
                if (root.kind === "error") return root.errorMessage;
                return root.showAll
                    ? i18n("%1 doesn't have any containers yet.", root.binary)
                    : i18n("Stopped containers are hidden.");
            }
        }

        PlasmaComponents.Button {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 4
            visible: root.kind === "empty" && !root.showAll
            text: i18n("Show stopped containers")
            icon.name: "view-filter"
            font.family: root.look ? root.look.fontFamily : "Monospace"
            onClicked: root.showAllRequested()
        }
    }
}
