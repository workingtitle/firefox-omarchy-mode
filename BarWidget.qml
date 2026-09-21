import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Firefox Omarchy Mode. The widget keeps running while hidden: it re-syncs
// Firefox on every theme change and on a slow poll, and only shows its icon
// while Firefox is not in Omarchy mode (not enabled yet, a profile is missing
// the stylesheet, or Firefox still runs with the old look and needs a restart).
Panel {
  id: root
  moduleName: "io.github.workingtitle.firefox-omarchy-mode"
  ipcTarget: "io.github.workingtitle.firefox-omarchy-mode"

  property var shell: null

  property var status: ({})
  property bool loaded: false
  property bool busy: false
  property string output: ""
  property string errorOutput: ""
  property string message: ""
  property string pendingCommand: ""

  readonly property bool colors: setting("colors", true) === true
  readonly property bool squareCorners: setting("squareCorners", true) === true
  readonly property bool hideWindowButtons: setting("hideWindowButtons", true) === true
  readonly property bool compactTabs: setting("compactTabs", true) === true
  readonly property bool modeEnabled: status.enabled === true
  readonly property bool modeActive: status.active === true
  readonly property var profiles: status.profiles instanceof Array ? status.profiles : []
  readonly property string helperPath: Qt.resolvedUrl("firefox-omarchy-mode").toString().replace(/^file:\/\//, "")

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color accent: Color.accent
  readonly property color urgent: bar ? bar.urgent : Color.urgent
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  readonly property string headline: {
    if (!loaded) return "Checking Firefox…"
    if (!modeEnabled) return "Firefox is not in Omarchy mode"
    if (status.restartNeeded === true) return "Restart Firefox to finish"
    return "Updating Firefox profiles…"
  }
  readonly property string detail: {
    if (!loaded) return ""
    if (!modeEnabled) return "Enable it to give Firefox the colors of " + (status.theme || "your theme") + " and keep them in sync when you switch themes."
    if (status.restartNeeded === true) return "Firefox only reads its theme at startup. Close and reopen it, and this icon disappears."
    return "Some Firefox profiles do not have the Omarchy stylesheet yet."
  }

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function optionArgs() {
    return ["--colors", colors ? "on" : "off", "--corners", squareCorners ? "square" : "rounded",
      "--window-buttons", hideWindowButtons ? "hide" : "show",
      "--tabs", compactTabs ? "compact" : "default"]
  }

  // One helper at a time; a click during a background sync runs right after it.
  function run(command) {
    if (helperProc.running) {
      if (command !== "sync" || pendingCommand === "") pendingCommand = command
      return
    }
    busy = command !== "sync"
    output = ""
    errorOutput = ""
    helperProc.command = [helperPath, command].concat(command === "disable" ? [] : optionArgs())
    helperProc.running = true
  }

  function sync() { run("sync") }

  function saveOption(key, value) {
    var next = ({})
    for (var k in settings) next[k] = settings[k]
    next[key] = value
    if (!(shell && typeof shell.updateEntryInline === "function" && shell.updateEntryInline(moduleName, next)))
      message = "Could not save the setting"
  }

  function open() {
    controller.show()
    sync()
  }

  visible: loaded && profiles.length > 0 && !modeActive
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onModeActiveChanged: if (modeActive && opened) close()
  onColorsChanged: syncDebounce.restart()
  onSquareCornersChanged: syncDebounce.restart()
  onHideWindowButtonsChanged: syncDebounce.restart()
  onCompactTabsChanged: syncDebounce.restart()
  Component.onCompleted: sync()

  // A theme switch retints the shell, so any of these changing is the cue to
  // rewrite Firefox's stylesheet. The poll covers Firefox starting and quitting.
  Connections {
    target: Color
    function onBackgroundChanged() { syncDebounce.restart() }
    function onForegroundChanged() { syncDebounce.restart() }
    function onAccentChanged() { syncDebounce.restart() }
  }

  Timer {
    id: syncDebounce
    interval: 1500
    onTriggered: root.sync()
  }

  Timer {
    interval: root.opened ? 3000 : 15000
    running: true
    repeat: true
    onTriggered: root.sync()
  }

  Process {
    id: helperProc
    command: []
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: root.output = text }
    stderr: StdioCollector { waitForEnd: true; onStreamFinished: root.errorOutput = text }
    onExited: function(exitCode) {
      root.busy = false
      if (exitCode !== 0) {
        root.message = String(root.errorOutput).replace(/\s+/g, " ").trim() || "firefox-omarchy-mode failed"
      } else {
        try {
          root.status = JSON.parse(String(root.output || "{}"))
          root.loaded = true
          root.message = ""
        } catch (error) {
          root.message = "Could not read the Firefox status"
        }
      }
      if (root.pendingCommand !== "") {
        var next = root.pendingCommand
        root.pendingCommand = ""
        Qt.callLater(root.run, next)
      }
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰈹"
    active: root.opened
    tooltipText: root.headline
    onPressed: function(mouseButton) {
      if (mouseButton === Qt.RightButton) root.sync()
      else root.toggle()
    }
  }

  KeyboardPanel {
    id: popup
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    contentWidth: fittedContentWidth(Style.space(400))
    contentHeight: fittedContentHeight(content.implicitHeight)

    Column {
      id: content
      width: popup.contentWidth
        - popup.padding * 2
        - Border.left(popup.borderSpec)
        - Border.right(popup.borderSpec)
      spacing: Style.space(14)

      Column {
        width: parent.width
        spacing: Style.space(4)
        Text {
          width: parent.width
          wrapMode: Text.WordWrap
          text: root.headline
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.title
          font.bold: true
        }
        Text {
          width: parent.width
          visible: text !== ""
          wrapMode: Text.WordWrap
          text: root.detail
          color: Qt.darker(root.foreground, 1.35)
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
        }
      }

      Rectangle { width: parent.width; height: 1; color: Qt.darker(root.foreground, 1.8) }

      Repeater {
        model: [
          { key: "colors", label: "Use Omarchy theme colors", checked: root.colors },
          { key: "squareCorners", label: "Square corners", checked: root.squareCorners },
          { key: "hideWindowButtons", label: "Hide close button", checked: root.hideWindowButtons },
          { key: "compactTabs", label: "Compact tabs", checked: root.compactTabs }
        ]
        delegate: Row {
          required property var modelData
          width: content.width
          spacing: Style.space(10)
          Text {
            width: parent.width - optionSwitch.width - parent.spacing
            anchors.verticalCenter: parent.verticalCenter
            text: modelData.label
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
          }
          ToggleSwitch {
            id: optionSwitch
            anchors.verticalCenter: parent.verticalCenter
            checked: modelData.checked
            busy: root.busy
            foreground: root.foreground
            accent: root.accent
            onToggled: root.saveOption(modelData.key, !modelData.checked)
          }
        }
      }

      Text {
        width: parent.width
        visible: root.profiles.length > 0
        wrapMode: Text.WordWrap
        text: {
          var names = []
          for (var i = 0; i < root.profiles.length; i++)
            names.push(root.profiles[i].name + (root.profiles[i].installed ? " ✓" : ""))
          return "Profiles: " + names.join(", ")
        }
        color: Qt.darker(root.foreground, 1.45)
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }

      Text {
        visible: root.message !== ""
        width: parent.width
        wrapMode: Text.WordWrap
        text: root.message
        color: root.urgent
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
      }

      Row {
        spacing: Style.space(8)
        Button {
          visible: !root.modeEnabled
          text: root.busy ? "Enabling…" : "Enable Omarchy mode"
          iconText: "󰈹"
          enabled: !root.busy
          bordered: true
          foreground: root.foreground
          accent: root.accent
          onClicked: root.run("enable")
        }
        Button {
          visible: root.modeEnabled
          text: "Turn off"
          enabled: !root.busy
          bordered: true
          foreground: root.foreground
          accent: root.accent
          onClicked: root.run("disable")
        }
      }
    }
  }
}
