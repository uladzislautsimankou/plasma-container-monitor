import QtQuick
import QtQml.Models
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import "backend"
import "../code/engine.js" as Engine

PlasmoidItem {
    id: root

    preferredRepresentation: Plasmoid.formFactor === PlasmaCore.Types.Planar
        ? fullRepresentation
        : compactRepresentation

    compactRepresentation: CompactRepresentation {
        onActivated: root.expanded = !root.expanded
    }

    implicitWidth: 440
    implicitHeight: 520

    Plasmoid.backgroundHints: {
        if (Plasmoid.configuration.showBackground) return PlasmaCore.Types.DefaultBackground;
        if (Plasmoid.configuration.showShadow) return PlasmaCore.Types.ShadowBackground;
        return PlasmaCore.Types.NoBackground;
    }

    readonly property bool active: Plasmoid.formFactor === PlasmaCore.Types.Planar || root.expanded
    readonly property bool hasBackground: (Plasmoid.effectiveBackgroundHints & PlasmaCore.Types.DefaultBackground) !== 0

    function clampInt(value, lo, hi, fallback) {
        var n = parseInt(value, 10);
        if (isNaN(n)) n = fallback;
        return Math.max(lo, Math.min(hi, n));
    }

    function buildSources() {
        var c = Plasmoid.configuration;
        var list = [];
        if (c.localEnabled) {
            list.push({
                id: "local", title: c.engine, host: "", engine: c.engine,
                listInterval: c.refreshInterval, logsInterval: c.logsInterval, statsInterval: c.statsInterval
            });
        }
        var servers = [];
        try { servers = JSON.parse(c.hosts || "[]"); } catch (e) { servers = []; }
        var seen = { local: true };
        for (var i = 0; i < servers.length; i++) {
            var s = servers[i];
            if (!s || !s.host || !Engine.isValidHost(s.host)) continue;
            var id = String(s.id || ("server" + i));
            while (seen[id]) id += "_";
            seen[id] = true;
            list.push({
                id: id,
                title: s.name || s.host,
                host: s.host,
                engine: s.engine === "docker" ? "docker" : "podman",
                listInterval: clampInt(s.listInterval, 1, 60, 5),
                logsInterval: clampInt(s.logsInterval, 1, 300, 5),
                statsInterval: clampInt(s.statsInterval, 1, 300, 10)
            });
        }
        return list;
    }

    readonly property string sourcesJson: JSON.stringify(buildSources())
    readonly property var sources: JSON.parse(sourcesJson)

    property var backendList: []
    property string chosenId: ""

    function collectBackends() {
        var l = [];
        for (var i = 0; i < instances.count; i++) {
            var o = instances.objectAt(i);
            if (o) l.push(o);
        }
        backendList = l;
    }

    readonly property var currentBackend: {
        var list = backendList;
        var chosen = null, i;
        for (i = 0; i < list.length; i++) if (list[i].sourceId === chosenId) chosen = list[i];
        if (chosen && chosen.selected) return chosen;
        for (i = 0; i < list.length; i++) if (list[i].selected) return list[i];
        return chosen || (list.length > 0 ? list[0] : null);
    }

    readonly property int totalRunning: {
        var n = 0;
        for (var i = 0; i < backendList.length; i++) n += backendList[i].runningCount;
        return n;
    }

    toolTipMainText: "Container Monitor"
    toolTipSubText: {
        if (backendList.length === 0) return i18n("No sources configured");
        if (backendList.length === 1 && backendList[0].status === "error") return backendList[0].errorMessage;
        return i18np("%1 container running", "%1 containers running", totalRunning);
    }

    Instantiator {
        id: instances
        model: root.sources

        delegate: ContainerBackend {
            id: source

            required property var modelData

            sourceId: modelData.id
            title: modelData.title
            host: modelData.host
            binary: modelData.engine
            refreshInterval: modelData.listInterval
            logsInterval: modelData.logsInterval
            statsInterval: modelData.statsInterval
            showAll: Plasmoid.configuration.showAll
            showStats: Plasmoid.configuration.showStats
            logLines: Plasmoid.configuration.logLines
            showTime: Plasmoid.configuration.showTime
            active: root.active
            logsEnabled: root.currentBackend === source
        }

        onObjectAdded: Qt.callLater(root.collectBackends)
        onObjectRemoved: (index, object) => {
            root.backendList = root.backendList.filter(o => o !== object);
            Qt.callLater(root.collectBackends);
        }
    }

    Component.onCompleted: collectBackends()

    Look {
        id: appearance

        fontFamily: Plasmoid.configuration.fontFamily || "Monospace"
        fontSize: Plasmoid.configuration.fontSize
        useThemeColors: Plasmoid.configuration.useThemeColors
        customMain: Plasmoid.configuration.colorMain
        customHeader: Plasmoid.configuration.colorHeader
        customSecondary: Plasmoid.configuration.colorSecondary
        customValues: Plasmoid.configuration.colorValues
        customLog: Plasmoid.configuration.colorLogText

        levelColors: ({
            fatal: Plasmoid.configuration.colorFatal,
            error: Plasmoid.configuration.colorError,
            warn:  Plasmoid.configuration.colorWarn,
            info:  Plasmoid.configuration.colorInfo,
            debug: Plasmoid.configuration.colorDebug,
            trace: Plasmoid.configuration.colorTrace
        })
        levelEnabled: ({
            fatal: Plasmoid.configuration.useColorFatal,
            error: Plasmoid.configuration.useColorError,
            warn:  Plasmoid.configuration.useColorWarn,
            info:  Plasmoid.configuration.useColorInfo,
            debug: Plasmoid.configuration.useColorDebug,
            trace: Plasmoid.configuration.useColorTrace
        })
        logTime: ({
            show: Plasmoid.configuration.showTime,
            zone: Plasmoid.configuration.timeZone,
            offsetMinutes: Plasmoid.configuration.timeOffsetMinutes,
            format: Plasmoid.configuration.timeFormat
        })
        levelKeywords: ({
            fatal: Plasmoid.configuration.keywordsFatal,
            error: Plasmoid.configuration.keywordsError,
            warn:  Plasmoid.configuration.keywordsWarn,
            info:  Plasmoid.configuration.keywordsInfo,
            debug: Plasmoid.configuration.keywordsDebug,
            trace: Plasmoid.configuration.keywordsTrace
        })
    }

    fullRepresentation: FullRepresentation {
        look: appearance
        wantedWidth: Plasmoid.configuration.panelWidth
        wantedHeight: Plasmoid.configuration.panelHeight
        trackSize: Plasmoid.formFactor !== PlasmaCore.Types.Planar
        backends: root.backendList
        current: root.currentBackend
        hasBackground: root.hasBackground
        followLogs: Plasmoid.configuration.followLogs
        inheritLevel: Plasmoid.configuration.inheritLevel

        onContainerChosen: backend => root.chosenId = backend.sourceId
        onSizeSettled: (w, h) => {
            var c = Plasmoid.configuration;
            if (Math.abs(c.panelWidth - w) >= 2) c.panelWidth = w;
            if (Math.abs(c.panelHeight - h) >= 2) c.panelHeight = h;
        }
    }
}
