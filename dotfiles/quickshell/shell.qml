//@ pragma ShellId oliver-shell
//@ pragma AppId oliver.quickshell
//@ pragma UseQApplication

import Quickshell
import Quickshell.Io
import "features/bar" as BarFeature
import "features/notifications" as NotificationFeature
import "features/osd" as OsdFeature
import "features/popovers" as PopoverFeature
import "features/startup" as StartupFeature
import "features/screentime" as ScreenTimeFeature

ShellRoot {
    id: root

    signal openSystemMenu
    signal openDisplayLayout
    signal openDisplayCurrent
    signal openScreenshotMenu
    signal openClipboardHistory
    signal openCalendarMedia
    signal openScreenTime
    signal toggleStatusPanel(string panelName)

    settings.watchFiles: true

    IpcHandler {
        target: "systemMenu"

        function open() {
            root.openSystemMenu();
        }
    }

    IpcHandler {
        target: "displayMenu"

        function openLayout() {
            root.openDisplayLayout();
        }

        function openCurrent() {
            root.openDisplayCurrent();
        }
    }

    IpcHandler {
        target: "screenshotMenu"

        function open() {
            root.openScreenshotMenu();
        }
    }

    IpcHandler {
        target: "clipboardHistory"

        function open() {
            root.openClipboardHistory();
        }
    }

    IpcHandler {
        target: "calendarMedia"

        function open() {
            root.openCalendarMedia();
        }
    }

    IpcHandler {
        target: "screenTime"

        function open() {
            root.openScreenTime();
        }

        function resetToday() {
            screenTimeTracker.resetToday();
        }

        function resetAll() {
            screenTimeTracker.resetAll();
        }

        function status(): string {
            return screenTimeTracker.ready ? screenTimeTracker.barLabel : "loading";
        }
    }

    IpcHandler {
        target: "statusPanel"

        function toggle(panelName: string) {
            root.toggleStatusPanel(panelName);
        }
    }

    readonly property string primaryMonitor: Quickshell.env("HYPR_PRIMARY_MONITOR") || ""
    readonly property var primaryScreens: {
        if (primaryMonitor === "")
            return Quickshell.screens;

        const screens = [];
        for (let i = 0; i < Quickshell.screens.length; i++) {
            if (Quickshell.screens[i].name === primaryMonitor)
                screens.push(Quickshell.screens[i]);
        }

        return screens.length > 0 ? screens : Quickshell.screens;
    }
    readonly property var mainScreens: root.primaryScreens.length > 0 ? [root.primaryScreens[0]] : []

    ScreenTimeFeature.ScreenTimeService {
        id: screenTimeTracker
    }

    Variants {
        model: root.primaryScreens

        BarFeature.Bar {
            required property var modelData
            shellRoot: root
            screenTimeService: screenTimeTracker
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens

        PopoverFeature.ScreenshotPopover {
            required property var modelData
            shellRoot: root
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens

        PopoverFeature.ClipboardHistory {
            required property var modelData
            shellRoot: root
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens

        PopoverFeature.DisplayPopoverAnchor {
            required property var modelData
            shellRoot: root
            screen: modelData
        }
    }

    Variants {
        model: root.primaryScreens

        OsdFeature.Osd {
            required property var modelData
            screen: modelData
        }
    }

    Variants {
        model: root.primaryScreens

        StartupFeature.Splash {
            required property var modelData
            screen: modelData
        }
    }

    Variants {
        model: root.mainScreens

        NotificationFeature.Notifications {
            required property var modelData
            screen: modelData
        }
    }
}
