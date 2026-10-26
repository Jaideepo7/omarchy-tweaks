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

  PopupCard {
    id: popup
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.popupOpen
    contentWidth: popup.fittedContentWidth(controls.implicitWidth + popup.padding * 2)
    contentHeight: popup.fittedContentHeight(controls.implicitHeight)

    Row {
      id: controls
      anchors.centerIn: parent
      spacing: Style.space(6)

      Button {
        iconText: "󰒮"
        foreground: root.bar.foreground
        enabled: !!root.activePlayer && root.activePlayer.canGoPrevious
        opacity: enabled ? 1.0 : 0.4
        onClicked: root.activePlayer.previous()
      }

      Button {
        iconText: root.activePlayer && root.activePlayer.isPlaying ? "󰏤" : "󰐊"
        foreground: root.bar.foreground
        iconSize: Style.font.iconLarge
        enabled: !!root.activePlayer && root.activePlayer.canTogglePlaying
        opacity: enabled ? 1.0 : 0.4
        onClicked: root.activePlayer.togglePlaying()
      }

      Button {
        iconText: "󰒭"
        foreground: root.bar.foreground
        enabled: !!root.activePlayer && root.activePlayer.canGoNext
        opacity: enabled ? 1.0 : 0.4
        onClicked: root.activePlayer.next()
      }
    }
  }
}
