.pragma library

var LEVELS = ["fatal", "error", "warn", "info", "debug", "trace"];

var BUILTIN = {
    fatal: ["fatal", "ftl", "crit", "critical", "emerg", "emergency", "panic"],
    error: ["error", "err", "erro", "fail", "severe"],
    warn:  ["warn", "warning", "wrn"],
    info:  ["info", "inf", "information", "notice"],
    debug: ["debug", "dbug", "dbg"],
    trace: ["trace", "trce", "trc", "verbose", "vrb"]
};

var SCAN_LIMIT = 120;

var ANSI_RE = /\u001b\[[0-9;?]*[ -\/]*[@-~]/g;

function escapeRegex(s) {
    return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function splitKeywords(text) {
    var out = [];
    var parts = (text || "").split(/[,;\n]/);
    for (var i = 0; i < parts.length; i++) {
        var w = parts[i].trim().toLowerCase();
        if (w) out.push(w);
    }
    return out;
}

function buildDetector(extra) {
    var map = {};
    var i, j, words;
    for (i = 0; i < LEVELS.length; i++) {
        words = BUILTIN[LEVELS[i]];
        for (j = 0; j < words.length; j++) map[words[j]] = LEVELS[i];
    }

    for (i = 0; i < LEVELS.length; i++) {
        words = splitKeywords(extra ? extra[LEVELS[i]] : "");
        for (j = 0; j < words.length; j++) map[words[j]] = LEVELS[i];
    }
    var tokens = Object.keys(map).sort(function(a, b) { return b.length - a.length; });
    var alt = tokens.map(escapeRegex).join("|");
    var re = new RegExp("(?:^|[^A-Za-z0-9_])(" + alt + ")(?![A-Za-z0-9_])", "i");
    var start = new RegExp("^[\\[(<]?(?:" + alt + ")(?![A-Za-z0-9_])", "i");
    return { re: re, start: start, map: map };
}

function detectLevel(line, detector) {
    var m = detector.re.exec(line.substring(0, SCAN_LIMIT));
    return m ? (detector.map[m[1].toLowerCase()] || "") : "";
}

function stripAnsi(s) {
    return s.replace(ANSI_RE, "");
}

var TS_RE = /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:\.(\d+))?(Z|[+-]\d{2}:?\d{2})\s?/;

function parseTimestamp(line) {
    var m = TS_RE.exec(line);
    if (!m) return null;
    var frac = m[7] ? (m[7] + "00").substring(0, 3) : "000";
    var offset = 0;
    if (m[8] !== "Z") {
        var digits = m[8].replace(/[^0-9]/g, "");
        offset = parseInt(digits.substring(0, 2), 10) * 60 + parseInt(digits.substring(2, 4), 10);
        if (m[8].charAt(0) === "-") offset = -offset;
    }
    var ms = Date.UTC(+m[1], +m[2] - 1, +m[3], +m[4], +m[5], +m[6], +frac) - offset * 60000;
    return { ms: ms, rest: line.substring(m[0].length) };
}

function pad(n, width) {
    var s = String(n);
    while (s.length < (width || 2)) s = "0" + s;
    return s;
}

// zone: "system" | "utc" | "offset" (offsetMinutes), format: "time" | "timeMs" | "dateTime"
function formatTime(ms, zone, offsetMinutes, format) {
    var d, Y, M, D, h, m, s, msec;
    if (zone === "system") {
        d = new Date(ms);
        Y = d.getFullYear(); M = d.getMonth() + 1; D = d.getDate();
        h = d.getHours(); m = d.getMinutes(); s = d.getSeconds(); msec = d.getMilliseconds();
    } else {
        d = new Date(zone === "offset" ? ms + (offsetMinutes || 0) * 60000 : ms);
        Y = d.getUTCFullYear(); M = d.getUTCMonth() + 1; D = d.getUTCDate();
        h = d.getUTCHours(); m = d.getUTCMinutes(); s = d.getUTCSeconds(); msec = d.getUTCMilliseconds();
    }
    var t = pad(h) + ":" + pad(m) + ":" + pad(s);
    if (format === "timeMs") t += "." + pad(msec, 3);
    if (format === "dateTime") return Y + "-" + pad(M) + "-" + pad(D) + " " + t;
    return t;
}


var RECORD_START_RE = /^(?:[\[(]?\d{4}[-\/]\d{2}[-\/]\d{2}[T ]\d{2}:\d{2}|[\[(]?\d{2}:\d{2}:\d{2}|[A-Z][a-z]{2} {1,2}\d{1,2} \d{2}:\d{2}:\d{2}|\{|(?:time|ts|timestamp|level|lvl)=)/;
var CONTINUATION_RE = /^(?:\s|---|\.\.\. \d+ |Caused by:)/;

function lineKind(line, detector) {
    if (line === "") return "blank";
    if (CONTINUATION_RE.test(line)) return "cont";
    if (RECORD_START_RE.test(line) || detector.start.test(line)) return "start";
    return "plain";
}

function parseLines(text, detector, inherit, timestamps) {
    var raw = (text || "").split("\n");
    var rows = [];
    var starts = 0, candidates = 0;
    var i, line, time, t, kind;

    for (i = 0; i < raw.length; i++) {
        line = raw[i].replace(/\r$/, "");
        time = null;
        if (timestamps) {
            t = parseTimestamp(line);
            if (t) { time = t.ms; line = t.rest; }
        }
        line = stripAnsi(line);
        kind = lineKind(line, detector);
        if (kind === "start") { starts++; candidates++; }
        else if (kind === "plain") candidates++;
        rows.push({ time: time, text: line, kind: kind });
    }

    var structured = starts > 0 && starts * 3 >= candidates;

    var out = [];
    var cur = null;
    var prev = "";
    for (i = 0; i < rows.length; i++) {
        var row = rows[i];
        var joins = cur !== null
            && (row.kind === "cont" || row.kind === "blank" || (structured && row.kind === "plain"));
        if (joins) { cur.lines.push(row.text); continue; }

        var level = (row.kind === "start" || row.kind === "plain") ? detectLevel(row.text, detector) : "";
        if (level) prev = level;
        else if (inherit) level = prev;

        cur = { time: row.time, level: level, lines: [row.text], text: "" };
        out.push(cur);
    }
    for (i = 0; i < out.length; i++) out[i].text = out[i].lines.join("\n");
    return out;
}

function timeSample(format) {
    if (format === "dateTime") return "8888-88-88 88:88:88";
    if (format === "timeMs") return "88:88:88.888";
    return "88:88:88";
}
