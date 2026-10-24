import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.kquickcontrols as KQControls

KCM.SimpleKCM {
    id: page

    property alias cfg_panelWidth: panelWidthSpin.value
    property int cfg_panelWidthDefault
    property alias cfg_panelHeight: panelHeightSpin.value
    property int cfg_panelHeightDefault
    property alias cfg_localEnabled: localCheck.checked
    property bool cfg_localEnabledDefault
    property string cfg_engine
    property string cfg_engineDefault
    property alias cfg_refreshInterval: intervalSpin.value
    property int cfg_refreshIntervalDefault
    property alias cfg_logsInterval: logsIntervalSpin.value
    property int cfg_logsIntervalDefault
    property alias cfg_statsInterval: statsIntervalSpin.value
    property int cfg_statsIntervalDefault
    property alias cfg_showAll: showAllCheck.checked
    property bool cfg_showAllDefault
    property alias cfg_showStats: showStatsCheck.checked
    property bool cfg_showStatsDefault

    property alias cfg_fontFamily: fontPicker.fontFamily
    property string cfg_fontFamilyDefault
    property alias cfg_fontSize: fontSizeSpin.value
    property int cfg_fontSizeDefault
    property alias cfg_showBackground: backgroundCheck.checked
    property bool cfg_showBackgroundDefault
    property alias cfg_showShadow: shadowCheck.checked
    property bool cfg_showShadowDefault
    property alias cfg_useThemeColors: themeColorsCheck.checked
    property bool cfg_useThemeColorsDefault
    property alias cfg_colorMain: colorMain.color
    property color cfg_colorMainDefault
    property alias cfg_colorHeader: colorHeader.color
    property color cfg_colorHeaderDefault
    property alias cfg_colorSecondary: colorSecondary.color
    property color cfg_colorSecondaryDefault
    property alias cfg_colorValues: colorValues.color
    property color cfg_colorValuesDefault

    function syncEngine() {
        var i = engineCombo.indexOfValue(cfg_engine);
        if (i >= 0) engineCombo.currentIndex = i;
    }
    onCfg_engineChanged: syncEngine()

    function resetAppearance() {
        fontPicker.fontFamily = cfg_fontFamilyDefault || "Monospace";
        fontSizeSpin.value = cfg_fontSizeDefault;
        backgroundCheck.checked = cfg_showBackgroundDefault;
        shadowCheck.checked = cfg_showShadowDefault;
        themeColorsCheck.checked = cfg_useThemeColorsDefault;
        colorMain.color = cfg_colorMainDefault;
        colorHeader.color = cfg_colorHeaderDefault;
        colorSecondary.color = cfg_colorSecondaryDefault;
        colorValues.color = cfg_colorValuesDefault;
    }

    Kirigami.FormLayout {
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("This computer")
        }

        QQC2.CheckBox {
            id: localCheck
            text: i18n("Show containers on this computer")
        }

        QQC2.ComboBox {
            id: engineCombo
            enabled: localCheck.checked
            Kirigami.FormData.label: i18n("Engine:")
            textRole: "text"
            valueRole: "value"
            model: [
                { text: "Podman", value: "podman" },
                { text: "Docker", value: "docker" }
            ]
            Component.onCompleted: page.syncEngine()
            onActivated: page.cfg_engine = currentValue
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Update list every:")
            enabled: localCheck.checked
            QQC2.SpinBox {
                id: intervalSpin
                from: 1
                to: 60
            }
            QQC2.Label { text: i18n("seconds") }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Update logs every:")
            enabled: localCheck.checked
            QQC2.SpinBox {
                id: logsIntervalSpin
                from: 1
                to: 300
            }
            QQC2.Label { text: i18n("seconds") }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Update CPU and memory every:")
            enabled: localCheck.checked && showStatsCheck.checked
            QQC2.SpinBox {
                id: statsIntervalSpin
                from: 1
                to: 300
            }
            QQC2.Label { text: i18n("seconds") }
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("All sources")
        }

        QQC2.CheckBox {
            id: showAllCheck
            text: i18n("Show stopped containers")
        }

        QQC2.CheckBox {
            id: showStatsCheck
            text: i18n("Show CPU and memory usage")
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Panel popup")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Size:")
            QQC2.SpinBox {
                id: panelWidthSpin
                from: 320
                to: 2400
                stepSize: 10
                editable: true
            }
            QQC2.Label { text: "×" }
            QQC2.SpinBox {
                id: panelHeightSpin
                from: 200
                to: 2400
                stepSize: 10
                editable: true
            }
            QQC2.Label { text: i18n("px") }
        }

        QQC2.Label {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 22
            wrapMode: Text.Wrap
            opacity: 0.7
            text: i18n("Used when the widget sits on a panel and opens as a popup. If you drag the popup's edge, the new size is saved here.")
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Appearance")
        }

        FontPicker {
            id: fontPicker
            Kirigami.FormData.label: i18n("Font:")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Size:")
            QQC2.SpinBox {
                id: fontSizeSpin
                from: 8
                to: 28
            }
            QQC2.Label { text: i18n("px") }
        }

        QQC2.CheckBox {
            id: backgroundCheck
            Kirigami.FormData.label: i18n("Background:")
            text: i18n("Draw the panel background")
        }

        QQC2.CheckBox {
            id: shadowCheck
            enabled: !backgroundCheck.checked
            text: i18n("Draw a shadow under text, lines and buttons")
        }

        QQC2.CheckBox {
            id: themeColorsCheck
            Kirigami.FormData.label: i18n("Colors:")
            text: i18n("Use the system theme colors")
        }

        KQControls.ColorButton {
            id: colorMain
            Kirigami.FormData.label: i18n("Main text:")
            enabled: !themeColorsCheck.checked
        }
        KQControls.ColorButton {
            id: colorHeader
            Kirigami.FormData.label: i18n("Headers:")
            enabled: !themeColorsCheck.checked
        }
        KQControls.ColorButton {
            id: colorSecondary
            Kirigami.FormData.label: i18n("Secondary:")
            enabled: !themeColorsCheck.checked
        }
        KQControls.ColorButton {
            id: colorValues
            Kirigami.FormData.label: i18n("Values:")
            enabled: !themeColorsCheck.checked
        }

        QQC2.Button {
            icon.name: "document-revert"
            text: i18n("Reset appearance to defaults")
            onClicked: page.resetAppearance()
        }
    }
}
