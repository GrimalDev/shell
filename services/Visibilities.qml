pragma Singleton

import Quickshell
import qs.components
import qs.services

Singleton {
    property var screens: new Map()
    property var bars: new Map()
    property var dashboards: new Map()

    function load(screen: ShellScreen, visibilities: DrawerVisibilities): void {
        screens.set(Hypr.monitorFor(screen), visibilities);
    }

    function loadDashboard(screen: ShellScreen, dashboard): void {
        dashboards.set(Hypr.monitorFor(screen), dashboard);
    }

    function getForActive(): DrawerVisibilities {
        return screens.get(Hypr.focusedMonitor);
    }

    function getDashboardForActive() {
        return dashboards.get(Hypr.focusedMonitor);
    }
}
