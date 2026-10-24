import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import "../code/engine.js" as Engine

KCM.SimpleKCM {
    id: page

    property string cfg_hosts
    property string cfg_hostsDefault

    property bool syncing: false

    ListModel { id: servers }

    function num(v, lo, hi, fallback) {
        var n = parseInt(v, 10);
        if (isNaN(n)) n = fallback;
        return Math.max(lo, Math.min(hi, n));
    }

    function load() {
        var list = [];
        try { list = JSON.parse(cfg_hosts || "[]"); } catch (e) { list = []; }
        servers.clear();
        for (var i = 0; i < list.length; i++) {
            var s = list[i] || {};
            servers.append({
                sid: String(s.id || ("s" + Date.now() + i)),
                srvName: s.name || "",
                host: s.host || "",
                engine: s.engine === "docker" ? "docker" : "podman",
                listSec: num(s.listInterval, 1, 60, 5),
                logsSec: num(s.logsInterval, 1, 300, 5),
                statsSec: num(s.statsInterval, 1, 300, 10)
            });
        }
    }

    function save() {
        var out = [];
        for (var i = 0; i < servers.count; i++) {
            var s = servers.get(i);
            out.push({
                id: s.sid, name: s.srvName, host: s.host, engine: s.engine,
                listInterval: s.listSec, logsInterval: s.logsSec, statsInterval: s.statsSec
            });
        }
        syncing = true;
        cfg_hosts = JSON.stringify(out);
        syncing = false;
    }

    function add() {
        servers.append({
            sid: "s" + Date.now(), srvName: "", host: "", engine: "podman",
            listSec: 5, logsSec: 5, statsSec: 10
        });
        save();
    }

    onCfg_hostsChanged: if (!syncing) load()
    Component.onCompleted: load()

    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing

        QQC2.Label {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: i18n("Servers are reached over SSH, without asking for a password: use a key (with ssh-agent or without a passphrase) and connect to the server once from a terminal first to accept its host key. The host can be an alias from ~/.ssh/config or user@host. The container engine must be installed on the server.")
        }

        Repeater {
            model: servers

            delegate: Kirigami.AbstractCard {
                id: card

                required property int index
                required property string srvName
                required property string host
                required property string engine
                required property int listSec
                required property int logsSec
                required property int statsSec

                Layout.fillWidth: true

                contentItem: Kirigami.FormLayout {
                    QQC2.TextField {
                        Kirigami.FormData.label: i18n("Name:")
                        text: card.srvName
                        placeholderText: i18n("shown in the widget (optional)")
                        onTextEdited: {
                            servers.setProperty(card.index, "srvName", text);
                            page.save();
                        }
                    }

                    QQC2.TextField {
                        Kirigami.FormData.label: i18n("SSH host:")
                        text: card.host
                        placeholderText: i18n("vps-admin or user@host")
                        onTextEdited: {
                            servers.setProperty(card.index, "host", text.trim());
                            page.save();
                        }
                    }

                    QQC2.Label {
                        visible: card.host === "" || !Engine.isValidHost(card.host)
                        color: Kirigami.Theme.negativeTextColor
                        text: card.host === ""
                            ? i18n("Enter a host, or this server is ignored.")
                            : i18n("This host name is not valid, the server is ignored.")
                    }

                    QQC2.ComboBox {
                        Kirigami.FormData.label: i18n("Engine:")
                        model: ["Podman", "Docker"]
                        currentIndex: card.engine === "docker" ? 1 : 0
                        onActivated: i => {
                            servers.setProperty(card.index, "engine", i === 1 ? "docker" : "podman");
                            page.save();
                        }
                    }

                    RowLayout {
                        Kirigami.FormData.label: i18n("Update list every:")
                        QQC2.SpinBox {
                            from: 1
                            to: 60
                            value: card.listSec
                            onValueModified: {
                                servers.setProperty(card.index, "listSec", value);
                                page.save();
                            }
                        }
                        QQC2.Label { text: i18n("seconds") }
                    }

                    RowLayout {
                        Kirigami.FormData.label: i18n("Update logs every:")
                        QQC2.SpinBox {
                            from: 1
                            to: 300
                            value: card.logsSec
                            onValueModified: {
                                servers.setProperty(card.index, "logsSec", value);
                                page.save();
                            }
                        }
                        QQC2.Label { text: i18n("seconds") }
                    }

                    RowLayout {
                        Kirigami.FormData.label: i18n("Update CPU and memory every:")
                        QQC2.SpinBox {
                            from: 1
                            to: 300
                            value: card.statsSec
                            onValueModified: {
                                servers.setProperty(card.index, "statsSec", value);
                                page.save();
                            }
                        }
                        QQC2.Label { text: i18n("seconds") }
                    }

                    QQC2.Button {
                        icon.name: "list-remove"
                        text: i18n("Remove this server")
                        onClicked: {
                            servers.remove(card.index);
                            page.save();
                        }
                    }
                }
            }
        }

        QQC2.Button {
            Layout.alignment: Qt.AlignHCenter
            icon.name: "list-add"
            text: i18n("Add server")
            onClicked: page.add()
        }
    }
}
