pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components

Item {
    id: root

    required property DrawerVisibilities visibilities

    readonly property bool shouldBeActive: visibilities.cliphist
    property real offsetScale: shouldBeActive ? 0 : 1

    visible: offsetScale < 1
    anchors.topMargin: (-implicitHeight - 5) * offsetScale
    implicitWidth: Tokens.sizes.utilities.width
    implicitHeight: content.implicitHeight + content.anchors.margins * 2
    opacity: 1 - offsetScale

    Behavior on offsetScale {
        Anim {
            type: Anim.DefaultSpatial
        }
    }

    Loader {
        id: content

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: Tokens.padding.large

        active: root.shouldBeActive || root.visible

        sourceComponent: Content {
            implicitWidth: Tokens.sizes.utilities.width - content.anchors.margins * 2
            visibilities: root.visibilities
        }
    }
}
