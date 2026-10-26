import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.Ui

BarWidget {
  id: root
  moduleName: "jaideep.albumart"

  // Prefer a player that is playing; otherwise fall back to the first with art.
  readonly property var activePlayer: {
    var list = Mpris.players.values
    var fallback = null
    for (var i = 0; i < list.length; i++) {
      var p = list[i]
      if (!p || !p.trackArtUrl) continue
      if (p.isPlaying) return p
      if (!fallback) fallback = p
    }
    return fallback
  }
  readonly property string artUrl: activePlayer && activePlayer.trackArtUrl ? activePlayer.trackArtUrl : ""

  readonly property real artSize: Math.round(barSize * 0.7)

  visible: artUrl !== ""
  implicitWidth: visible ? artSize + 10 : 0
  implicitHeight: barSize

  // Clicking the cover jumps to the workspace, window and (when the player
  // supports Raise, as Chromium does) the tab that is playing.
  Process {
    id: focusProc
    command: ["bash", Qt.resolvedUrl("focus-player.sh").toString().replace("file://", ""),
      root.activePlayer ? String(root.activePlayer.dbusName || "") : "",
      root.activePlayer ? String(root.activePlayer.desktopEntry || "") : "",
      root.activePlayer ? String(root.activePlayer.trackTitle || "") : ""]
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: if (root.activePlayer && !focusProc.running) focusProc.running = true
  }

  Rectangle {
    anchors.centerIn: parent
    width: root.artSize
    height: root.artSize
    radius: 4
    color: "transparent"
    clip: true

    Image {
      anchors.fill: parent
      source: root.artUrl
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      sourceSize.width: 64
      sourceSize.height: 64
    }
  }
}
