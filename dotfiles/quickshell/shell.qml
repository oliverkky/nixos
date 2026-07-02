//@ pragma ShellId oliver-shell
//@ pragma AppId oliver.quickshell
//@ pragma UseQApplication

import Quickshell
import Quickshell.Io
import "components"

ShellRoot {
    id: root

    signal openSystemMenu

    settings.watchFiles: true

    IpcHandler {
        target: "systemMenu"

        function open() {
            root.openSystemMenu();
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

    Variants {
        model: root.primaryScreens

        Bar {
            required property var modelData
            shellRoot: root
            screen: modelData
        }
    }

    Variants {
        model: root.primaryScreens

        Osd {
            required property var modelData
            screen: modelData
        }
    }

    Variants {
        model: root.primaryScreens

        Splash {
            required property var modelData
            screen: modelData
        }
    }

    Variants {
        model: root.mainScreens

        Notifications {
            required property var modelData
            screen: modelData
        }
    }
}
