import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.Commons
import qs.Ui

// Live cava bars. Clicking (or resting on it, via the bar's hover-open) drops
// a small card with previous / play-pause / next for whatever is playing.
BarWidget {
  id: root
  moduleName: "jaideep.visualizer"

  readonly property int barCount: 10
  property var levels: new Array(barCount).fill(0)

  // Same pick as the album art: a playing player first, else the first one.
  readonly property var activePlayer: {
    var list = Mpris.players.values
    for (var i = 0; i < list.length; i++) if (list[i] && list[i].isPlaying) return list[i]
    return list.length > 0 ? list[0] : null
  }

  // Popup contract the bar looks for (open / close / opened).
  property bool popupOpen: false
  readonly property bool opened: popupOpen
  function open() { if (activePlayer) popupOpen = true }
  function close() { popupOpen = false }
  function toggle() { popupOpen ? close() : open() }

  onActivePlayerChanged: if (!activePlayer) close()

  implicitWidth: row.implicitWidth + 14
  implicitHeight: barSize

  Process {
    id: cava
    command: ["cava", "-p", Qt.resolvedUrl("cava.conf").toString().replace("file://", "")]
    running: true
    stdout: SplitParser {
      onRead: function(line) {
        var parts = line.split(";")
        var next = []
        for (var i = 0; i < root.barCount; i++) next.push(Math.min(100, parseInt(parts[i]) || 0) / 100)
        root.levels = next
      }
    }
  }

  Row {
    id: row
    anchors.centerIn: parent
    spacing: 2

    Repeater {
      model: root.barCount
      Rectangle {
        required property int index
        width: 3
        height: Math.max(2, (root.barSize * 0.6) * root.levels[index])
        radius: 1.5
        anchors.verticalCenter: parent.verticalCenter
        color: root.bar.barForeground
        opacity: 0.85
        Behavior on height { NumberAnimation { duration: 60 } }
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: root.activePlayer ? Qt.PointingHandCursor : Qt.ArrowCursor
    onClicked: root.toggle()
  }

  // Overall size of the media card; everything below scales with it.
  readonly property real popupScale: 1.35

  // One compact transport button: a glyph, a soft hover wash, nothing else.
  component MediaButton: Item {
    id: btn
    property string glyph: ""
    signal activated()
    width: Math.round(Style.space(26) * root.popupScale)
    height: Math.round(Style.space(24) * root.popupScale)
    opacity: enabled ? 1.0 : 0.35

    Rectangle {
      anchors.fill: parent
      radius: Style.cornerRadius
      color: root.bar.foreground
      opacity: btnMouse.pressed ? 0.16 : btnMouse.containsMouse ? 0.08 : 0
      Behavior on opacity { NumberAnimation { duration: 100 } }
    }

    Text {
      anchors.centerIn: parent
      text: btn.glyph
      color: root.bar.foreground
      font.family: root.bar.fontFamily
      font.pixelSize: Math.round(Style.font.body * root.popupScale)
    }

    MouseArea {
      id: btnMouse
      anchors.fill: parent
      enabled: btn.enabled
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: btn.activated()
    }
  }

  PopupCard {
    id: popup
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.popupOpen
    padding: Math.round(Style.space(4) * root.popupScale)
    contentWidth: controls.implicitWidth + popup.padding * 2 + 2 * Math.max(1, Style.space(2))
    contentHeight: popup.fittedContentHeight(controls.implicitHeight)

    Row {
      id: controls
      anchors.centerIn: parent
      spacing: Math.round(Style.space(2) * root.popupScale)

      MediaButton {
        glyph: "󰒮"
        enabled: !!root.activePlayer && root.activePlayer.canGoPrevious
        onActivated: root.activePlayer.previous()
      }

      MediaButton {
        glyph: root.activePlayer && root.activePlayer.isPlaying ? "󰏤" : "󰐊"
        enabled: !!root.activePlayer && root.activePlayer.canTogglePlaying
        onActivated: root.activePlayer.togglePlaying()
      }

      MediaButton {
        glyph: "󰒭"
        enabled: !!root.activePlayer && root.activePlayer.canGoNext
        onActivated: root.activePlayer.next()
      }
    }
  }
}
