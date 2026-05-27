pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.filedialog
import qs.services
import qs.utils

Item {
    id: root

    required property ShellScreen screen
    required property DrawerVisibilities visibilities
    readonly property var tabNames: ["dashboard", "media", "performance", "weather"]
    readonly property bool needsKeyboard: (content.item as Content)?.needsKeyboard ?? false
    readonly property DashboardState dashState: DashboardState {
        reloadableId: "dashboardState"
    }
    readonly property FileDialog facePicker: FileDialog {
        title: qsTr("Select a profile picture")
        filterLabel: qsTr("Image files")
        filters: Images.validImageExtensions
        onAccepted: path => {
            if (CUtils.copyFile(Qt.resolvedUrl(path), Qt.resolvedUrl(`${Paths.home}/.face`)))
                Quickshell.execDetached(["notify-send", "-a", "caelestia-shell", "-u", "low", "-h", `STRING:image-path:${path}`, "Profile picture changed", `Profile picture changed to ${Paths.shortenHome(path)}`]);
            else
                Quickshell.execDetached(["notify-send", "-a", "caelestia-shell", "-u", "critical", "Unable to change profile picture", `Failed to change profile picture to ${Paths.shortenHome(path)}`]);
        }
    }

    readonly property real nonAnimHeight: state === "visible" ? ((content.item as Content)?.nonAnimHeight ?? 0) : 0
    readonly property bool shouldBeActive: visibilities.dashboard && Config.dashboard.enabled
    property real offsetScale: shouldBeActive ? 0 : 1
    property string pendingSection: ""

    function normalizeSection(section: string): string {
        return (section ?? "").toLowerCase();
    }

    function sectionAtIndex(index: int): string {
        const contentItem = content.item as Content;
        if (!contentItem)
            return "";

        const tabs = contentItem.dashboardTabs;
        const tab = tabs[index];
        return (tab?.key ?? tabNames[index] ?? "").toLowerCase();
    }

    function currentSection(): string {
        if (pendingSection)
            return pendingSection;
        return root.sectionAtIndex(dashState.currentTab);
    }

    function setSection(section: string): bool {
        const contentItem = content.item as Content;
        if (!contentItem)
            return false;

        const wantedTab = root.normalizeSection(section);
        const tabs = contentItem.dashboardTabs;
        if (tabs.length === 0)
            return false;

        for (let i = 0; i < tabs.length; i++) {
            const tab = tabs[i];
            if ((tab?.key ?? tabNames[i] ?? "").toLowerCase() === wantedTab) {
                dashState.currentTab = i;
                return true;
            }
        }

        dashState.currentTab = 0;
        return true;
    }

    function openSection(section: string): void {
        const normalizedSection = root.normalizeSection(section);
        pendingSection = normalizedSection;
        visibilities.dashboard = true;

        if (normalizedSection.length === 0)
            return;

        Qt.callLater(() => root.applyPendingSection());
    }

    function toggleSection(section: string): void {
        const normalizedSection = root.normalizeSection(section);
        if (!normalizedSection) {
            visibilities.dashboard = !visibilities.dashboard;
            return;
        }

        if (visibilities.dashboard && root.currentSection() === normalizedSection) {
            pendingSection = "";
            visibilities.dashboard = false;
            return;
        }

        root.openSection(normalizedSection);
    }

    function applyPendingSection(): void {
        if (!pendingSection)
            return;

        if (!(content.item as Content))
            return;

        if (root.setSection(pendingSection))
            pendingSection = "";
    }

    onShouldBeActiveChanged: {
        if (shouldBeActive)
            root.applyPendingSection();
    }

    visible: offsetScale < 1
    anchors.topMargin: (-implicitHeight - 5) * offsetScale
    implicitHeight: content.implicitHeight
    implicitWidth: content.implicitWidth || 854 // Hard coded fallback for first open
    opacity: 1 - offsetScale

    Behavior on offsetScale {
        Anim {
            type: Anim.DefaultSpatial
        }
    }

    Loader {
        id: content

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom

        active: root.shouldBeActive || root.visible

        sourceComponent: Content {
            visibilities: root.visibilities
            dashState: root.dashState
            facePicker: root.facePicker
        }

        onLoaded: root.applyPendingSection()
    }

    Component.onCompleted: Visibilities.loadDashboard(root.screen, root)
    onScreenChanged: Visibilities.loadDashboard(root.screen, root)
}
