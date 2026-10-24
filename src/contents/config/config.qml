import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("General")
        icon: "configure"
        source: "configGeneral.qml"
    }
    ConfigCategory {
        name: i18n("Servers")
        icon: "network-server"
        source: "configServers.qml"
    }
    ConfigCategory {
        name: i18n("Logs")
        icon: "text-x-log"
        source: "configLogs.qml"
    }
}
