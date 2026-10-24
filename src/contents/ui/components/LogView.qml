import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.components as PlasmaComponents
import "../../code/logs.js" as Logs

ColumnLayout {
    id: root

    property var look
    property var backend
    property bool hasBackground: true
    property bool follow: true
    property bool inheritLevel: true
    property bool showHost: false

    readonly property var detector: Logs.buildDetector(look.levelKeywords)

    readonly property var entries: backend.logs
        ? Logs.parseLines(backend.logs, detector, inheritLevel, backend.logsTimestamps)
        : []

    readonly property bool showTime: look.logTime.show && backend.logsTimestamps
    readonly property int logFontSize: look.fontSize - 1
    readonly property real columnGap: 8
    readonly property real timeWidth: showTime ? Math.ceil(sample.width) : 0
    readonly property real barWidth: 3

    spacing: 6

    function timeText(entry) {
        if (entry.time === null) return "";
        var t = look.logTime;
        return Logs.formatTime(entry.time, t.zone, t.offsetMinutes, t.format);
    }

    function copyAll() {
        var parts = [];
        for (var i = 0; i < entries.length; i++) {
            var stamp = showTime ? timeText(entries[i]) : "";
            parts.push((stamp ? stamp + "  " : "") + entries[i].text);
        }
        clipboard.text = parts.join("\n");
        clipboard.selectAll();
        clipboard.copy();
        clipboard.text = "";
    }

    function showEntries() {
        var y = list.contentY;
        list.model = entries;
        if (follow) {
            list.positionViewAtEnd();
            Qt.callLater(list.positionViewAtEnd);
        } else {
            list.contentY = y;
        }
    }

    onEntriesChanged: showEntries()
    Component.onCompleted: showEntries()

    TextMetrics {
        id: sample
        font.family: root.look.fontFamily
        font.pixelSize: root.logFontSize
        text: Logs.timeSample(root.look.logTime.format)
    }

    TextEdit {
        id: clipboard
        visible: false
    }

    SectionHeader {
        Layout.fillWidth: true
        Layout.topMargin: 10
        look: root.look
        title: i18n("logs")
        subtitle: root.backend.selected
            ? i18np("%2 · last %1 line", "%2 · last %1 lines", root.backend.logLines,
              (root.showHost ? root.backend.title + " / " : "") + root.backend.selected.name)
            : ""

        PlasmaComponents.ToolButton {
            icon.name: "edit-copy"
            implicitWidth: 22
            implicitHeight: 22
            enabled: root.entries.length > 0
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.text: i18n("Copy all log lines")
            onClicked: root.copyAll()
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        Rectangle {
            anchors.fill: parent
            radius: 3
            color: root.hasBackground ? Qt.alpha(root.look.textMain, 0.07) : "transparent"
        }

        ListView {
            id: list
            anchors.fill: parent
            anchors.leftMargin: root.hasBackground ? 6 : 0
            anchors.rightMargin: root.hasBackground ? 6 : 0
            anchors.topMargin: root.hasBackground ? 4 : 2
            anchors.bottomMargin: root.hasBackground ? 4 : 2
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            spacing: 4

            QQC2.ScrollBar.vertical: QQC2.ScrollBar {
                policy: root.hasBackground ? QQC2.ScrollBar.AsNeeded : QQC2.ScrollBar.AlwaysOff
            }

            delegate: Item {
                id: row

                required property var modelData

                readonly property bool painted: modelData.level !== "" && root.look.levelEnabled[modelData.level] === true
                readonly property color accent: painted ? root.look.levelColors[modelData.level] : root.look.textLog
                readonly property real textX: root.timeWidth + (root.showTime ? root.columnGap : 0)
                    + root.barWidth + root.columnGap

                width: ListView.view.width
                height: Math.max(body.contentHeight, 1)

                Text {
                    visible: root.showTime
                    x: 0
                    width: root.timeWidth
                    text: root.timeText(row.modelData)
                    textFormat: Text.PlainText
                    color: root.look.textSecondary
                    font.family: root.look.fontFamily
                    font.pixelSize: root.logFontSize
                }

                Rectangle {
                    x: root.timeWidth + (root.showTime ? root.columnGap : 0)
                    width: root.barWidth
                    height: parent.height
                    radius: width / 2
                    color: row.painted ? row.accent : root.look.textSecondary
                    opacity: row.painted ? 1.0 : 0.35
                }

                TextEdit {
                    id: body
                    x: row.textX
                    width: parent.width - row.textX
                    text: row.modelData.text
                    textFormat: TextEdit.PlainText
                    wrapMode: TextEdit.Wrap
                    readOnly: true
                    selectByMouse: true
                    cursorDelegate: Item { visible: false }
                    color: row.accent
                    selectedTextColor: "#ffffff"
                    selectionColor: Qt.alpha(root.look.textValues, 0.5)
                    font.family: root.look.fontFamily
                    font.pixelSize: root.logFontSize
                }
            }
        }

        PlasmaComponents.Label {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.leftMargin: root.hasBackground ? 6 : 0
            anchors.topMargin: root.hasBackground ? 4 : 2
            visible: root.entries.length === 0
            text: root.backend.logsLoading ? i18n("Loading logs…") : i18n("No log output")
            color: root.look.textSecondary
            font.family: root.look.fontFamily
            font.pixelSize: root.logFontSize
        }
    }
}
