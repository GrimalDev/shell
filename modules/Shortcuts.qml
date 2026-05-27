import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import qs.components.misc
import qs.services
import qs.modules.controlcenter

Scope {
    id: root

    property bool launcherInterrupted
    readonly property bool hasFullscreen: Hypr.focusedWorkspace?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1) ?? false

    function toggleDashboardSectionWithRetry(section: string, retries: int): void {
        const visibilities = Visibilities.getForActive();
        if (!visibilities)
            return;

        const dashboard = Visibilities.getDashboardForActive();
        if (dashboard) {
            dashboard.toggleSection(section);
            return;
        }

        visibilities.dashboard = true;
        if (retries > 0)
            Qt.callLater(() => root.toggleDashboardSectionWithRetry(section, retries - 1));
    }

    function toggleDashboardSection(section: string): void {
        root.toggleDashboardSectionWithRetry(section, 5);
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "controlCenter"
        description: "Open control center"
        onPressed: WindowFactory.create()
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "showall"
        description: "Toggle launcher, dashboard and osd"
        onPressed: {
            if (root.hasFullscreen)
                return;
            const v = Visibilities.getForActive();
            v.launcher = v.dashboard = v.osd = v.utilities = !(v.launcher || v.dashboard || v.osd || v.utilities);
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "dashboard"
        description: "Toggle dashboard"
        onPressed: {
            if (root.hasFullscreen)
                return;
            const visibilities = Visibilities.getForActive();
            if (!visibilities)
                return;

            if (visibilities.dashboard)
                visibilities.dashboard = false;
            else
                root.toggleDashboardSection("dashboard");
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "dashboardMedia"
        description: "Open dashboard media tab"
        onPressed: {
            if (root.hasFullscreen)
                return;
            root.toggleDashboardSection("media");
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "dashboardPerformance"
        description: "Open dashboard performance tab"
        onPressed: {
            if (root.hasFullscreen)
                return;
            root.toggleDashboardSection("performance");
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "dashboardWeather"
        description: "Open dashboard weather tab"
        onPressed: {
            if (root.hasFullscreen)
                return;
            root.toggleDashboardSection("weather");
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "session"
        description: "Toggle session menu"
        onPressed: {
            if (root.hasFullscreen)
                return;
            const visibilities = Visibilities.getForActive();
            visibilities.session = !visibilities.session;
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "launcher"
        description: "Toggle launcher"
        onPressed: root.launcherInterrupted = false
        onReleased: {
            if (!root.launcherInterrupted && !root.hasFullscreen) {
                const visibilities = Visibilities.getForActive();
                visibilities.launcher = !visibilities.launcher;
            }
            root.launcherInterrupted = false;
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "launcherInterrupt"
        description: "Interrupt launcher keybind"
        onPressed: root.launcherInterrupted = true
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "sidebar"
        description: "Toggle sidebar"
        onPressed: {
            if (root.hasFullscreen)
                return;
            const visibilities = Visibilities.getForActive();
            visibilities.sidebar = !visibilities.sidebar;
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "cliphist"
        description: "Toggle cliphist"
        onPressed: {
            if (root.hasFullscreen)
                return;
            const visibilities = Visibilities.getForActive();
            visibilities.cliphist = !visibilities.cliphist;
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "utilities"
        description: "Toggle utilities"
        onPressed: {
            if (root.hasFullscreen)
                return;
            const visibilities = Visibilities.getForActive();
            visibilities.utilities = !visibilities.utilities;
        }
    }

    IpcHandler {
        function toggle(drawer: string): void {
            if (list().split("\n").includes(drawer)) {
                if (root.hasFullscreen && ["launcher", "session", "dashboard"].includes(drawer))
                    return;
                const visibilities = Visibilities.getForActive();
                visibilities[drawer] = !visibilities[drawer];
            } else {
                console.warn(lc, `Drawer "${drawer}" does not exist`);
            }
        }

        function openDashboardSection(section: string): void {
            if (root.hasFullscreen)
                return;
            root.toggleDashboardSection(section);
        }

        function list(): string {
            const visibilities = Visibilities.getForActive();
            return Object.keys(visibilities).filter(k => typeof visibilities[k] === "boolean").join("\n");
        }

        target: "drawers"
    }

    IpcHandler {
        function open(): void {
            WindowFactory.create();
        }

        target: "controlCenter"
    }

    IpcHandler {
        function info(title: string, message: string, icon: string): void {
            Toaster.toast(title, message, icon, Toast.Info);
        }

        function success(title: string, message: string, icon: string): void {
            Toaster.toast(title, message, icon, Toast.Success);
        }

        function warn(title: string, message: string, icon: string): void {
            Toaster.toast(title, message, icon, Toast.Warning);
        }

        function error(title: string, message: string, icon: string): void {
            Toaster.toast(title, message, icon, Toast.Error);
        }

        target: "toaster"
    }

    LoggingCategory {
        id: lc

        name: "caelestia.qml.shortcuts"
        defaultLogLevel: LoggingCategory.Info
    }
}
