// mine: "Suburbs glass" for a shell card, matching the notification cards:
// rounded, see-through, tinted with the theme accent, 1px accent edge.
// Hyprland's window-glassy layer rule frosts what is behind it. Keep every
// alpha >= 0.3: that rule's ignore_alpha skips blur below that. Every colour
// comes from the theme (Commons.Color), so it follows theme changes.
//
// Point `target` at the card (a BorderSurface). Without one, it searches the
// window it sits in for the first BorderSurface: that is how it finds the card
// inside the packaged KeyboardPanel / PopupCard, which park this helper in a
// wrapper of their own. Identical copies live in each plugin; keep them in step.

import QtQuick
import qs.Commons as Commons

Item {
  id: glass

  property Item target: null
  // Test switch: true = neutral frosted glass (the first mockups' option A),
  // false = accent-tinted "Suburbs glass". Same value in every copy and in
  // jaideep.notifications Toast.qml (glassFrost).
  property bool frost: true
  property real radius: 20
  property real opacityTop: 0.73
  property real opacityBody: 0.68
  property real edgeOpacity: 0.38
  property color base: Commons.Color.popups.background
  property color text: Commons.Color.popups.text
  readonly property color tint: Commons.Color.accent

  function findCard(item, depth) {
    if (!item || depth > 4) return null
    if (item !== glass && item.contentLeftInset !== undefined && item.borderSpec !== undefined) return item
    var kids = item.children || []
    for (var i = 0; i < kids.length; i++) {
      var hit = findCard(kids[i], depth + 1)
      if (hit) return hit
    }
    return null
  }
  property Item card: null
  function locate() {
    if (target) { card = target; return }
    var top = glass
    while (top.parent) top = top.parent
    card = findCard(top, 0)
  }
  Component.onCompleted: locate()
  onParentChanged: locate()
  onTargetChanged: locate()

  function mixed(a, b, t, alpha) {
    return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, alpha)
  }

  // Frost: the theme background lifted toward its text colour, a smoky grey
  // that keeps the theme's hue, lighter at the top like light on glass.
  readonly property color topColor: frost ? mixed(base, text, 0.18, 0.58) : mixed(base, tint, 0.28, opacityTop)
  readonly property color bodyColor: frost ? mixed(base, text, 0.14, 0.55)
                                           : Qt.rgba(base.r, base.g, base.b, opacityBody)
  readonly property color edgeColor: frost ? Qt.rgba(text.r, text.g, text.b, 0.16)
                                           : Qt.rgba(tint.r, tint.g, tint.b, edgeOpacity)

  Gradient {
    id: fill
    GradientStop { position: 0.0; color: glass.topColor }
    GradientStop { position: 0.4; color: glass.bodyColor }
    GradientStop { position: 1.0; color: glass.bodyColor }
  }

  Binding { when: glass.card !== null; target: glass.card; property: "radius"; value: glass.radius }
  Binding { when: glass.card !== null; target: glass.card; property: "gradient"; value: fill }
  Binding {
    when: glass.card !== null
    target: glass.card
    property: "borderSpec"
    value: Commons.Border.flat(glass.edgeColor, 1)
  }

  // A faint highlight along the top edge, like light catching glass.
  Item {
    parent: glass.card
    visible: glass.card !== null
    x: 1; y: 1
    width: glass.card ? glass.card.width - 2 : 0
    height: glass.radius * 0.6
    clip: true
    Rectangle {
      width: parent.width
      height: glass.card ? glass.card.height - 2 : 0
      radius: glass.radius - 1
      color: "transparent"
      border.width: 1
      border.color: Qt.rgba(glass.text.r, glass.text.g, glass.text.b, glass.frost ? 0.14 : 0.09)
    }
  }
}
