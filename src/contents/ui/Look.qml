import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: look
    visible: false

    property string fontFamily: "Monospace"
    property int fontSize: 11
    property bool useThemeColors: false

    property color customMain: "#D8DEE9"
    property color customHeader: "#D8DEE9"
    property color customSecondary: "#A4A8B0"
    property color customValues: "#81A1C1"
    property color customLog: "#D8DEE9"

    readonly property color textMain: useThemeColors ? Kirigami.Theme.textColor : customMain
    readonly property color textHeader: useThemeColors ? Kirigami.Theme.textColor : customHeader
    readonly property color textSecondary: useThemeColors ? Qt.alpha(Kirigami.Theme.textColor, 0.6) : customSecondary
    readonly property color textValues: useThemeColors ? Kirigami.Theme.highlightColor : customValues
    readonly property color textLog: useThemeColors ? Qt.alpha(Kirigami.Theme.textColor, 0.75) : customLog
    readonly property color separator: Qt.alpha(textSecondary, 0.45)

    property var levelColors: ({})
    property var levelEnabled: ({})
    property var levelKeywords: ({})

    property var logTime: ({ show: false, zone: "system", offsetMinutes: 0, format: "time" })

    // role: "main" | "header" | "secondary" | "values"
    function colorFor(role) {
        switch (role) {
        case "header":    return textHeader;
        case "secondary": return textSecondary;
        case "values":    return textValues;
        default:          return textMain;
        }
    }
}
