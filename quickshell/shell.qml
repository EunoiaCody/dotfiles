//@ pragma UseQApplication

import QtQuick
import Quickshell
import Quickshell.Wayland

import "modules" as Modules

ShellRoot {
	Variants {
		model: Quickshell.screens

		Modules.Clock {}
	}

	Variants {
		model: Quickshell.screens

		Modules.Workspaces {}
	}

	Variants {
		model: Quickshell.screens

		Modules.PowerMenu {}
	}

	Variants {
		model: Quickshell.screens

		Modules.Notifications {}
	}

	Variants {
		model: Quickshell.screens

		Modules.Volume {}
	}

	Variants {
		model: Quickshell.screens

		Modules.Bluetooth {}
	}

	Variants {
		model: Quickshell.screens

		Modules.Network {}
	}

	Variants {
		model: Quickshell.screens

		Modules.SystemMonitor {}
	}

	Variants {
		model: Quickshell.screens

		Modules.SystemTray {}
	}
}
