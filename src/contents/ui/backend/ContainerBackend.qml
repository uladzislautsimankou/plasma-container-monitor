import QtQuick
import org.kde.plasma.plasma5support as Plasma5Support
import "../../code/engine.js" as Engine

Item {
    id: backend

    property string sourceId: ""
    property string title: ""
    property string host: ""            // ssh target; empty = this computer
    property string binary: "podman"
    property int refreshInterval: 3
    property int logsInterval: 3
    property int statsInterval: 5
    property bool showAll: false
    property bool showStats: true
    property int logLines: 40
    property bool showTime: false
    property bool active: true          // false while a panel popup is closed: only the cheap "ps" keeps running
    property bool logsEnabled: true

    property string status: "loading"
    property string errorMessage: ""
    property var containers: []
    property var stats: ({})
    property string selectedId: ""
    property string logs: ""
    property bool logsLoading: false
    property bool logsTimestamps: false
    property bool logsFinal: false

    readonly property int runningCount: {
        var n = 0;
        for (var i = 0; i < containers.length; i++) {
            if (containers[i].running) n++;
        }
        return n;
    }

    readonly property var selected: {
        for (var i = 0; i < containers.length; i++) {
            if (containers[i].id === selectedId) return containers[i];
        }
        return null;
    }

    function statsFor(container) {
        return Engine.lookupStats(stats, container);
    }

    function select(id) {
        if (id === selectedId) return;
        selectedId = id;
        logs = "";
        logsFinal = false;
        logsLoading = logsEnabled && id !== "";
        fetchLogs();
    }

    function refresh() {
        run("ps", Engine.psCommand(binary, showAll, host));
        fetchLogs();
        fetchStats();
    }

    function tickLogs() {
        if (logsEnabled && selected && (selected.running || !logsFinal)) fetchLogs();
    }

    function fetchStats() {
        if (active && showStats && runningCount > 0) run("stats", Engine.statsCommand(binary, host));
    }

    function runAction(action, id) {
        run("action", Engine.actionCommand(binary, action, id, host));
    }

    property var pending: ({})
    property string containersSignature: ""
    property bool ready: false

    function run(kind, command, tag, extra) {
        if (!command) return;
        pending[command] = { kind: kind, tag: tag || "", extra: extra || {} };
        runner.connectSource(command);
    }

    function fetchLogs() {
        if (!logsEnabled || !selectedId || status !== "ok") return;
        var withTime = showTime;
        var final = selected ? !selected.running : false;
        run("logs", Engine.logsCommand(binary, selectedId, logLines, withTime, host), selectedId,
            { timestamps: withTime, final: final });
    }

    function handleResult(job, exitCode, stdout, stderr) {
        switch (job.kind) {
        case "ps":     onContainers(exitCode, stdout, stderr); break;
        case "stats":  onStats(exitCode, stdout); break;
        case "logs":   onLogs(job, exitCode, stdout); break;
        case "action":
            if (exitCode !== 0) console.warn("podman-monitor: action failed:", stderr.trim());
            refresh();
            break;
        }
    }

    function describeFailure(exitCode, stderr) {
        var firstLine = (stderr || "").trim().split("\n")[0];

        if (host && exitCode === 255)
            return i18n("Can't connect to %1: %2", host, firstLine || i18n("unknown SSH error"));
        if (exitCode === 127)
            return host
                ? i18n("The “%1” command was not found on %2.", binary, host)
                : i18n("The “%1” command was not found. Is it installed?", binary);
        return firstLine || i18n("The command failed with exit code %1.", exitCode);
    }

    function fail(message) {
        status = "error";
        errorMessage = message;
        containers = [];
        containersSignature = "";
        stats = {};
        logs = "";
        logsLoading = false;
    }

    function onContainers(exitCode, stdout, stderr) {
        if (exitCode !== 0) {
            fail(describeFailure(exitCode, stderr));
            return;
        }
        var parsed;
        try {
            parsed = Engine.parseContainers(stdout);
        } catch (e) {
            fail(i18n("Unexpected output from %1.", binary));
            return;
        }

        status = "ok";
        errorMessage = "";

        var signature = JSON.stringify(parsed);
        if (signature !== containersSignature) {
            containers = parsed;
            containersSignature = signature;
        }

        reconcileSelection();

        if ((!showStats || runningCount === 0) && Object.keys(stats).length > 0) stats = {};
    }

    function reconcileSelection() {
        for (var i = 0; i < containers.length; i++) {
            if (containers[i].id === selectedId) return;
        }
        selectedId = containers.length > 0 ? containers[0].id : "";
        logs = "";
        logsFinal = false;
        logsLoading = logsEnabled && selectedId !== "";
        fetchLogs();
    }

    function onStats(exitCode, stdout) {
        if (exitCode !== 0) return;
        try {
            stats = Engine.parseStats(stdout);
        } catch (e) {
            console.warn("podman-monitor: cannot parse stats:", e);
        }
    }

    function onLogs(job, exitCode, stdout) {
        if (!logsEnabled || job.tag !== selectedId) return;
        var text = stdout.replace(/\s+$/, "");
        if (!text && exitCode !== 0)
            text = i18n("Failed to read logs (exit code %1).", exitCode);

        logsTimestamps = exitCode === 0 && job.extra.timestamps === true;
        logsFinal = exitCode === 0 && job.extra.final === true;
        if (text !== logs) logs = text;
        logsLoading = false;
    }

    onBinaryChanged: {
        if (!ready) return;
        status = "loading";
        errorMessage = "";
        containers = [];
        containersSignature = "";
        stats = {};
        selectedId = "";
        logs = "";
        logsFinal = false;
        logsLoading = false;
        refresh();
    }
    onShowAllChanged: if (ready) refresh()
    onLogsEnabledChanged: {
        if (!ready) return;
        logs = "";
        logsFinal = false;
        logsLoading = logsEnabled && selectedId !== "";
        if (logsEnabled) fetchLogs();
    }
    onShowStatsChanged: if (ready && !showStats) stats = {}
    onActiveChanged: if (ready && active) run("ps", Engine.psCommand(binary, showAll, host))
    onLogLinesChanged: if (ready) fetchLogs()
    onShowTimeChanged: if (ready) fetchLogs()

    Component.onCompleted: ready = true

    Plasma5Support.DataSource {
        id: runner
        engine: "executable"
        connectedSources: []

        onNewData: function(sourceName, data) {
            var job = backend.pending[sourceName];
            delete backend.pending[sourceName];
            disconnectSource(sourceName);
            if (!job) return;

            var code = data["exit code"];
            backend.handleResult(job,
                code === undefined ? 0 : code,
                data.stdout || "",
                data.stderr || "");
        }
    }

    Timer {
        interval: Math.max(1, backend.refreshInterval) * (backend.active ? 1 : 5)
            * (backend.status === "error" ? 4 : 1) * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: backend.run("ps", Engine.psCommand(backend.binary, backend.showAll, backend.host))
    }

    Timer {
        interval: Math.max(1, backend.logsInterval) * 1000
        running: backend.active && backend.logsEnabled
        repeat: true
        triggeredOnStart: true
        onTriggered: backend.tickLogs()
    }

    Timer {
        interval: Math.max(1, backend.statsInterval) * 1000
        running: backend.active && backend.showStats && backend.runningCount > 0
        repeat: true
        triggeredOnStart: true
        onTriggered: backend.fetchStats()
    }
}
