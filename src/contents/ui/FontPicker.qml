import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

QQC2.Button {
    id: root

    property string fontFamily: "Monospace"

    readonly property var allFamilies: {
        var out = ["Monospace"];
        try {
            var list = Qt.fontFamilies();
            for (var i = 0; i < list.length; i++) {
                if (list[i] && list[i].charAt(0) !== ".") out.push(list[i]);
            }
        } catch (e) {
            console.warn("podman-monitor: cannot list fonts:", e);
        }
        return out;
    }

    readonly property string query: search.text.trim().toLowerCase()

    readonly property var filtered: {
        if (!query) return allFamilies;
        var out = [];
        for (var i = 0; i < allFamilies.length; i++) {
            if (allFamilies[i].toLowerCase().indexOf(query) !== -1) out.push(allFamilies[i]);
        }
        return out;
    }

    readonly property bool exactMatch: {
        for (var i = 0; i < allFamilies.length; i++) {
            if (allFamilies[i].toLowerCase() === query) return true;
        }
        return false;
    }

    function choose(name) {
        fontFamily = name;
        popup.close();
    }

    text: fontFamily || "Monospace"
    font.family: fontFamily || "Monospace"
    icon.name: "font-select-symbolic"
    implicitWidth: Kirigami.Units.gridUnit * 15
    onClicked: popup.opened ? popup.close() : popup.open()

    QQC2.Popup {
        id: popup
        y: root.height
        width: root.width
        height: Kirigami.Units.gridUnit * 20
        padding: Kirigami.Units.smallSpacing

        onOpened: {
            search.text = "";
            search.forceActiveFocus();
            var i = root.filtered.indexOf(root.fontFamily);
            list.positionViewAtIndex(Math.max(i, 0), ListView.Center);
        }

        contentItem: ColumnLayout {
            spacing: Kirigami.Units.smallSpacing

            Kirigami.SearchField {
                id: search
                Layout.fillWidth: true
                placeholderText: i18n("Search fonts (%1 available)", root.allFamilies.length - 1)
                onAccepted: {
                    if (root.filtered.length > 0 && root.query) root.choose(root.filtered[0]);
                    else if (root.query) root.choose(search.text.trim());
                }
            }

            QQC2.ItemDelegate {
                Layout.fillWidth: true
                visible: root.query !== "" && !root.exactMatch
                text: i18n("Use “%1”", search.text.trim())
                onClicked: root.choose(search.text.trim())
            }

            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: root.filtered
                reuseItems: true

                QQC2.ScrollBar.vertical: QQC2.ScrollBar {}

                delegate: QQC2.ItemDelegate {
                    required property string modelData
                    width: ListView.view.width
                    text: modelData
                    font.family: modelData
                    highlighted: modelData === root.fontFamily
                    onClicked: root.choose(modelData)
                }

                QQC2.Label {
                    anchors.centerIn: parent
                    visible: list.count === 0
                    opacity: 0.6
                    text: i18n("No matching fonts")
                }
            }
        }
    }
}
