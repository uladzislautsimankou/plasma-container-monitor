import QtQuick
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

PlasmaComponents.Label {
    property var look
    property string role: "main"
    property int sizeOffset: 0

    font.family: look ? look.fontFamily : "Monospace"
    font.pixelSize: (look ? look.fontSize : 11) + sizeOffset
    color: look ? look.colorFor(role) : Kirigami.Theme.textColor
}
