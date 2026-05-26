pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services

Item {
    id: root

    required property DrawerVisibilities visibilities

    implicitHeight: Tokens.sizes.utilities.width

    readonly property int padding: Tokens.padding.large

    property var allEntries: []
    property var pendingEntries: []

    readonly property var filteredEntries: {
        const q = search.text.toLowerCase();
        if (!q)
            return allEntries;
        return allEntries.filter(e => {
            const t = e.indexOf("\t");
            const display = t >= 0 ? e.slice(t + 1) : e;
            return display.toLowerCase().includes(q);
        });
    }

    function reload(): void {
        pendingEntries = [];
        allEntries = [];
        if (listProc.running)
            listProc.running = false;
        listProc.running = true;
    }

    function copyEntry(entry: string): void {
        const id = entry.split("\t")[0];
        copyProc.command = ["bash", "-c", "cliphist decode " + id + " | wl-copy"];
        if (copyProc.running)
            copyProc.running = false;
        copyProc.running = true;
    }

    Component.onCompleted: {
        reload();
        Qt.callLater(() => search.forceActiveFocus());
    }

    Process {
        id: listProc

        command: ["cliphist", "list"]
        stdout: SplitParser {
            onRead: line => {
                if (line.length > 0)
                    root.pendingEntries = root.pendingEntries.concat([line]);
            }
        }
        onExited: {
            root.allEntries = root.pendingEntries;
            listView.currentIndex = 0;
        }
    }

    Process {
        id: copyProc

        onExited: root.visibilities.cliphist = false
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.padding
        spacing: Tokens.spacing.small

        StyledListView {
            id: listView

            Layout.fillWidth: true
            Layout.fillHeight: true

            model: root.filteredEntries
            spacing: Tokens.spacing.small
            clip: true

            highlightFollowsCurrentItem: false
            highlight: StyledRect {
                radius: Tokens.rounding.normal
                color: Colours.palette.m3onSurface
                opacity: 0.08

                y: listView.currentItem?.y ?? 0
                implicitWidth: listView.width
                implicitHeight: listView.currentItem?.implicitHeight ?? 0

                Behavior on y {
                    Anim {
                        type: Anim.DefaultSpatial
                    }
                }
            }

            preferredHighlightBegin: 0
            preferredHighlightEnd: height
            highlightRangeMode: ListView.ApplyRange

            StyledScrollBar.vertical: StyledScrollBar {
                flickable: listView
            }

            delegate: Item {
                id: delegate

                required property string modelData
                required property int index

                readonly property string displayText: {
                    const t = modelData.indexOf("\t");
                    return t >= 0 ? modelData.slice(t + 1) : modelData;
                }

                implicitHeight: Tokens.sizes.launcher.itemHeight

                anchors.left: parent?.left
                anchors.right: parent?.right

                StateLayer {
                    radius: Tokens.rounding.normal
                    onClicked: root.copyEntry(delegate.modelData)
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: Tokens.padding.larger
                    anchors.rightMargin: Tokens.padding.larger

                    text: delegate.displayText
                    font.pointSize: Tokens.font.size.normal
                    elide: Text.ElideRight
                }
            }
        }

        StyledRect {
            Layout.fillWidth: true

            color: Colours.layer(Colours.palette.m3surfaceContainer, 2)
            radius: Tokens.rounding.full
            implicitHeight: Math.max(searchIcon.implicitHeight, search.implicitHeight)

            MaterialIcon {
                id: searchIcon

                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: root.padding

                text: "search"
                color: Colours.palette.m3onSurfaceVariant
            }

            StyledText {
                id: resultCount

                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: root.padding

                text: root.filteredEntries.length
                font.pointSize: Tokens.font.size.small
                color: Colours.palette.m3outline
            }

            StyledTextField {
                id: search

                anchors.left: searchIcon.right
                anchors.right: resultCount.left
                anchors.leftMargin: Tokens.spacing.small
                anchors.rightMargin: Tokens.spacing.small

                topPadding: Tokens.padding.larger
                bottomPadding: Tokens.padding.larger

                placeholderText: qsTr("Search clipboard…")

                onAccepted: {
                    const item = listView.currentItem;
                    if (item)
                        root.copyEntry(item.modelData);
                }

                Keys.onUpPressed: listView.decrementCurrentIndex()
                Keys.onDownPressed: listView.incrementCurrentIndex()
                Keys.onEscapePressed: root.visibilities.cliphist = false
            }
        }
    }
}
