import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

MouseArea {
    id: root

    signal activated()

    acceptedButtons: Qt.LeftButton

    Layout.minimumWidth: {
        switch (Plasmoid.formFactor) {
        case PlasmaCore.Types.Vertical: return 0;
        case PlasmaCore.Types.Horizontal: return height;
        default: return Kirigami.Units.iconSizes.small;
        }
    }
    Layout.minimumHeight: {
        switch (Plasmoid.formFactor) {
        case PlasmaCore.Types.Vertical: return width;
        case PlasmaCore.Types.Horizontal: return 0;
        default: return Kirigami.Units.iconSizes.small;
        }
    }

    onClicked: root.activated()

    Kirigami.Icon {
        anchors.fill: parent
        source: Qt.resolvedUrl("../icons/container-monitor.svg")
        isMask: true
        color: Kirigami.Theme.textColor
    }
}
