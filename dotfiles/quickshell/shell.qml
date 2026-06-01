//@ pragma ShellId oliver-shell
//@ pragma AppId oliver.quickshell

import Quickshell
import "components"

ShellRoot {
    settings.watchFiles: true

    Variants {
        model: Quickshell.screens

        Bar {
            required property var modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens

        Osd {
            required property var modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens

        Splash {
            required property var modelData
            screen: modelData
        }
    }
}
