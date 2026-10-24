import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.kquickcontrols as KQControls

KCM.SimpleKCM {
    id: page

    // Display
    property alias cfg_logLines: linesSpin.value
    property int cfg_logLinesDefault
    property alias cfg_followLogs: followCheck.checked
    property bool cfg_followLogsDefault
    property alias cfg_inheritLevel: inheritCheck.checked
    property bool cfg_inheritLevelDefault

    // Time
    property alias cfg_showTime: showTimeCheck.checked
    property bool cfg_showTimeDefault
    property string cfg_timeZone
    property string cfg_timeZoneDefault
    property alias cfg_timeOffsetMinutes: offsetSpin.value
    property int cfg_timeOffsetMinutesDefault
    property string cfg_timeFormat
    property string cfg_timeFormatDefault

    // Colors
    property alias cfg_colorLogText: colorLogText.color
    property color cfg_colorLogTextDefault

    property alias cfg_useColorFatal: useFatal.checked
    property bool cfg_useColorFatalDefault
    property alias cfg_colorFatal: colorFatal.color
    property color cfg_colorFatalDefault
    property alias cfg_keywordsFatal: keywordsFatal.text
    property string cfg_keywordsFatalDefault

    property alias cfg_useColorError: useError.checked
    property bool cfg_useColorErrorDefault
    property alias cfg_colorError: colorError.color
    property color cfg_colorErrorDefault
    property alias cfg_keywordsError: keywordsError.text
    property string cfg_keywordsErrorDefault

    property alias cfg_useColorWarn: useWarn.checked
    property bool cfg_useColorWarnDefault
    property alias cfg_colorWarn: colorWarn.color
    property color cfg_colorWarnDefault
    property alias cfg_keywordsWarn: keywordsWarn.text
    property string cfg_keywordsWarnDefault

    property alias cfg_useColorInfo: useInfo.checked
    property bool cfg_useColorInfoDefault
    property alias cfg_colorInfo: colorInfo.color
    property color cfg_colorInfoDefault
    property alias cfg_keywordsInfo: keywordsInfo.text
    property string cfg_keywordsInfoDefault

    property alias cfg_useColorDebug: useDebug.checked
    property bool cfg_useColorDebugDefault
    property alias cfg_colorDebug: colorDebug.color
    property color cfg_colorDebugDefault
    property alias cfg_keywordsDebug: keywordsDebug.text
    property string cfg_keywordsDebugDefault

    property alias cfg_useColorTrace: useTrace.checked
    property bool cfg_useColorTraceDefault
    property alias cfg_colorTrace: colorTrace.color
    property color cfg_colorTraceDefault
    property alias cfg_keywordsTrace: keywordsTrace.text
    property string cfg_keywordsTraceDefault

    readonly property real keywordsWidth: Kirigami.Units.gridUnit * 14

    function pad(n) { return n < 10 ? "0" + n : String(n); }

    function syncCombos() {
        var i = zoneCombo.indexOfValue(cfg_timeZone);
        if (i >= 0) zoneCombo.currentIndex = i;
        i = formatCombo.indexOfValue(cfg_timeFormat);
        if (i >= 0) formatCombo.currentIndex = i;
    }
    onCfg_timeZoneChanged: syncCombos()
    onCfg_timeFormatChanged: syncCombos()

    function resetColors() {
        colorLogText.color = cfg_colorLogTextDefault;
        colorFatal.color = cfg_colorFatalDefault;
        colorError.color = cfg_colorErrorDefault;
        colorWarn.color = cfg_colorWarnDefault;
        colorInfo.color = cfg_colorInfoDefault;
        colorDebug.color = cfg_colorDebugDefault;
        colorTrace.color = cfg_colorTraceDefault;
    }

    Kirigami.FormLayout {
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Display")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Show last:")
            QQC2.SpinBox {
                id: linesSpin
                from: 1
                to: 1000
                stepSize: 10
                editable: true
            }
            QQC2.Label { text: i18n("lines") }
        }

        QQC2.CheckBox {
            id: followCheck
            text: i18n("Scroll to the newest line")
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Time")
        }

        QQC2.CheckBox {
            id: showTimeCheck
            text: i18n("Show the time of each line")
        }

        QQC2.ComboBox {
            id: zoneCombo
            Kirigami.FormData.label: i18n("Time zone:")
            enabled: showTimeCheck.checked
            textRole: "text"
            valueRole: "value"
            model: [
                { text: i18n("System time zone"), value: "system" },
                { text: "UTC", value: "utc" },
                { text: i18n("Fixed offset"), value: "offset" }
            ]
            Component.onCompleted: page.syncCombos()
            onActivated: page.cfg_timeZone = currentValue
        }

        QQC2.SpinBox {
            id: offsetSpin
            Kirigami.FormData.label: i18n("Offset:")
            visible: page.cfg_timeZone === "offset"
            enabled: showTimeCheck.checked
            from: -720
            to: 840
            stepSize: 30
            editable: true

            textFromValue: function(value) {
                var a = Math.abs(value);
                return "UTC" + (value < 0 ? "−" : "+") + page.pad(Math.floor(a / 60)) + ":" + page.pad(a % 60);
            }
            valueFromText: function(text) {
                var m = /([+\-−])?\s*(\d{1,2})(?::?(\d{2}))?/.exec(text.replace(/^UTC/i, ""));
                if (!m) return offsetSpin.value;
                var v = parseInt(m[2], 10) * 60 + (m[3] ? parseInt(m[3], 10) : 0);
                return (m[1] === "-" || m[1] === "−") ? -v : v;
            }
        }

        QQC2.ComboBox {
            id: formatCombo
            Kirigami.FormData.label: i18n("Format:")
            enabled: showTimeCheck.checked
            textRole: "text"
            valueRole: "value"
            model: [
                { text: i18n("Time (14:03:07)"), value: "time" },
                { text: i18n("Time with milliseconds (14:03:07.123)"), value: "timeMs" },
                { text: i18n("Date and time (2026-10-22 14:03:07)"), value: "dateTime" }
            ]
            Component.onCompleted: page.syncCombos()
            onActivated: page.cfg_timeFormat = currentValue
        }

        QQC2.Label {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 22
            wrapMode: Text.Wrap
            opacity: 0.7
            text: i18n("The time is taken from the container engine's log timestamps, so it is the moment the line was written, not a time printed by the application itself.")
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Colors")
        }

        KQControls.ColorButton {
            id: colorLogText
            Kirigami.FormData.label: i18n("Log text:")
        }

        QQC2.CheckBox {
            id: inheritCheck
            text: i18n("Lines without a level take the level of the previous line")
        }

        QQC2.Label {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 22
            wrapMode: Text.Wrap
            opacity: 0.7
            text: i18n("Tick a level to paint its lines with the chosen color. Unticked levels are still recognized, but their lines use the log text color. Standard names (fatal, error, warn, info, debug, trace and short forms like ERR, WRN, INF, DBG) always work; add your own words for a level in the field next to it, separated by commas.")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Fatal:")
            QQC2.CheckBox { id: useFatal }
            KQControls.ColorButton { id: colorFatal; enabled: useFatal.checked }
            QQC2.TextField {
                id: keywordsFatal
                Layout.preferredWidth: page.keywordsWidth
                placeholderText: i18n("extra words")
            }
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Error:")
            QQC2.CheckBox { id: useError }
            KQControls.ColorButton { id: colorError; enabled: useError.checked }
            QQC2.TextField {
                id: keywordsError
                Layout.preferredWidth: page.keywordsWidth
                placeholderText: i18n("extra words")
            }
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Warning:")
            QQC2.CheckBox { id: useWarn }
            KQControls.ColorButton { id: colorWarn; enabled: useWarn.checked }
            QQC2.TextField {
                id: keywordsWarn
                Layout.preferredWidth: page.keywordsWidth
                placeholderText: i18n("extra words")
            }
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Info:")
            QQC2.CheckBox { id: useInfo }
            KQControls.ColorButton { id: colorInfo; enabled: useInfo.checked }
            QQC2.TextField {
                id: keywordsInfo
                Layout.preferredWidth: page.keywordsWidth
                placeholderText: i18n("extra words")
            }
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Debug:")
            QQC2.CheckBox { id: useDebug }
            KQControls.ColorButton { id: colorDebug; enabled: useDebug.checked }
            QQC2.TextField {
                id: keywordsDebug
                Layout.preferredWidth: page.keywordsWidth
                placeholderText: i18n("extra words")
            }
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Trace:")
            QQC2.CheckBox { id: useTrace }
            KQControls.ColorButton { id: colorTrace; enabled: useTrace.checked }
            QQC2.TextField {
                id: keywordsTrace
                Layout.preferredWidth: page.keywordsWidth
                placeholderText: i18n("extra words")
            }
        }

        QQC2.Button {
            icon.name: "document-revert"
            text: i18n("Reset colors to defaults")
            onClicked: page.resetColors()
        }
    }
}
