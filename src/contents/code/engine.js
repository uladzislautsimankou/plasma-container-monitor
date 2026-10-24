.pragma library

var ALLOWED_BINARIES = ["podman", "docker"];
var ALLOWED_ACTIONS = ["start", "stop", "restart"];
var ID_RE = /^[A-Za-z0-9_.-]+$/;

function safeBinary(bin) {
    return ALLOWED_BINARIES.indexOf(bin) !== -1 ? bin : "podman";
}

var HOST_RE = /^[A-Za-z0-9][A-Za-z0-9._@:-]*$/;
var SSH_OPTS = '-o BatchMode=yes -o ConnectTimeout=5 -o ServerAliveInterval=15 -o ServerAliveCountMax=2 '
    + '-o ControlMaster=auto -o ControlPersist=60 -o "ControlPath=${XDG_RUNTIME_DIR:-/tmp}/podman-monitor-%C"';

// empty host = this computer
function isValidHost(host) {
    return !host || HOST_RE.test(host);
}

function remote(host, cmd) {
    if (!cmd) return "";
    if (!host) return cmd;
    if (!HOST_RE.test(host)) return "";
    return "ssh " + SSH_OPTS + " " + host + " '" + cmd + "'";
}

function psCommand(bin, all, host) {
    return remote(host, safeBinary(bin) + " ps" + (all ? " -a" : "") + " --format json");
}

function statsCommand(bin, host) {
    return remote(host, safeBinary(bin) + " stats --no-stream --format json");
}

function logsCommand(bin, id, tail, timestamps, host) {
    if (!ID_RE.test(id)) return "";
    var n = Math.max(1, Math.min(5000, parseInt(tail, 10) || 40));
    return remote(host, safeBinary(bin) + " logs" + (timestamps ? " -t" : "") + " --tail " + n + " " + id + " 2>&1");
}

function actionCommand(bin, action, id, host) {
    if (ALLOWED_ACTIONS.indexOf(action) === -1 || !ID_RE.test(id)) return "";
    return remote(host, safeBinary(bin) + " " + action + " " + id);
}

function parseJsonList(text) {
    var t = (text || "").trim();
    if (!t) return [];
    try {
        var v = JSON.parse(t);
        if (v === null) return [];
        return Array.isArray(v) ? v : [v];
    } catch (e) {
        var out = [];
        var lines = t.split("\n");
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim();
            if (line) out.push(JSON.parse(line));
        }
        return out;
    }
}

function normalizeContainer(raw) {
    var id = String(raw.Id || raw.ID || raw.id || "");
    var name = "";
    if (Array.isArray(raw.Names)) name = raw.Names[0] || "";
    else if (raw.Names) name = String(raw.Names).split(",")[0];
    else name = raw.Name || raw.name || "";
    name = String(name).replace(/^\//, "");

    var state = String(raw.State || raw.state || "").toLowerCase();
    return {
        id: id,
        shortId: id.substring(0, 12),
        name: name || id.substring(0, 12),
        image: String(raw.Image || raw.image || ""),
        state: state,
        running: state === "running"
    };
}

function parseContainers(text) {
    var list = parseJsonList(text);
    var out = [];
    for (var i = 0; i < list.length; i++) {
        var c = normalizeContainer(list[i]);
        if (c.id) out.push(c);
    }
    return out;
}

function parseStats(text) {
    var list = parseJsonList(text);
    var map = {};
    for (var i = 0; i < list.length; i++) {
        var item = list[i];
        var id = String(item.id || item.ID || item.ContainerID || "");
        var name = String(item.name || item.Name || "");
        var memRaw = String(item.mem_usage || item.MemUsage || "");
        var entry = {
            cpu: String(item.cpu_percent || item.CPUPerc || item.CPU || "--"),
            mem: memRaw ? memRaw.split("/")[0].trim() : "--"
        };
        if (id) map[id.substring(0, 12)] = entry;
        if (name) map[name] = entry;
    }
    return map;
}

function lookupStats(map, container) {
    if (!map || !container) return null;
    return map[container.shortId] || map[container.name] || null;
}
