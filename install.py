#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
import termios
import tty
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import List, Tuple


USE_COLOR = sys.stdout.isatty() and not os.environ.get("NO_COLOR")
RESET = "\033[0m" if USE_COLOR else ""
LAVENDER = "\033[38;2;180;190;254m" if USE_COLOR else ""
GREEN = "\033[38;2;166;227;161m" if USE_COLOR else ""
YELLOW = "\033[38;2;249;226;175m" if USE_COLOR else ""
RED = "\033[38;2;243;139;168m" if USE_COLOR else ""
SUB = "\033[38;2;186;194;222m" if USE_COLOR else ""


COMPONENTS = [
	"kitty",
	"mpv",
	"neovide",
	"nvim",
	"fish",
	"aerospace",
	"sketchybar",
	"yazi",
	"figlet",
	"bat",
	"niri",
	"quickshell",
]

COMPONENT_DESCRIPTIONS = {
	"kitty": "Kitty terminal and related fonts",
	"mpv": "MPV media player and codec support",
	"neovide": "Neovide GUI for Neovim",
	"nvim": "Neovim + build/search toolchain",
	"fish": "Fish shell",
	"aerospace": "AeroSpace config (macOS focused)",
	"sketchybar": "SketchyBar config (macOS focused)",
	"yazi": "Yazi terminal file manager",
	"figlet": "Figlet utility",
	"bat": "bat pager",
	"niri": "Niri compositor",
	"quickshell": "Quickshell (Arch preferred)",
}

PACKAGE_MAP = {
	"apt": {
		"kitty": ["kitty", "fonts-jetbrains-mono", "fonts-noto-cjk", "fonts-wqy-zenhei"],
		"mpv": ["mpv", "ffmpeg"],
		"neovide": ["neovide"],
		"nvim": ["neovim", "ripgrep", "nodejs", "npm", "clang", "make", "cmake", "pkg-config"],
		"fish": ["fish"],
		"aerospace": [],
		"sketchybar": [],
		"yazi": ["yazi"],
		"figlet": ["figlet"],
		"bat": ["bat"],
		"niri": ["niri"],
		"quickshell": [],
	},
	"dnf": {
		"kitty": ["kitty", "jetbrains-mono-fonts", "google-noto-sans-cjk-fonts", "google-noto-serif-cjk-fonts"],
		"mpv": ["mpv", "ffmpeg"],
		"neovide": ["neovide"],
		"nvim": ["neovim", "ripgrep", "nodejs", "npm", "clang", "make", "cmake", "pkgconf-pkg-config"],
		"fish": ["fish"],
		"aerospace": [],
		"sketchybar": [],
		"yazi": ["yazi"],
		"figlet": ["figlet"],
		"bat": ["bat"],
		"niri": ["niri"],
		"quickshell": [],
	},
	"pacman": {
		"kitty": ["kitty", "ttf-jetbrains-mono", "noto-fonts-cjk", "wqy-zenhei"],
		"mpv": ["mpv", "ffmpeg"],
		"neovide": ["neovide"],
		"nvim": ["neovim", "ripgrep", "nodejs", "npm", "clang", "make", "cmake", "pkgconf"],
		"fish": ["fish"],
		"aerospace": [],
		"sketchybar": [],
		"yazi": ["yazi"],
		"figlet": ["figlet"],
		"bat": ["bat"],
		"niri": ["niri"],
		"quickshell": [],
	},
}


@dataclass
class InstallResult:
	name: str
	status: str
	message: str


def log(message: str) -> None:
	print(f"{LAVENDER}[INSTALL]{RESET} {message}")


def ok(message: str) -> None:
	print(f"{GREEN}[INSTALL][OK]{RESET} {message}")


def warn(message: str) -> None:
	print(f"{YELLOW}[INSTALL][WARN]{RESET} {message}")


def section(message: str) -> None:
	print()
	print(f"{LAVENDER}==>{RESET} {SUB}{message}{RESET}")


def fail(message: str) -> int:
	print(f"{RED}[INSTALL][ERROR]{RESET} {message}", file=sys.stderr)
	return 1


def parse_args() -> argparse.Namespace:
	parser = argparse.ArgumentParser(
		description="Install dotfiles into ~/.config (must be launched via bootstrap.sh)."
	)
	parser.add_argument(
		"--from-bootstrap",
		action="store_true",
		help="Internal flag set by bootstrap.sh. Do not use directly.",
	)
	parser.add_argument(
		"--mode",
		choices=["copy", "link"],
		default="copy",
		help="Install mode: copy directories or create symlinks.",
	)
	parser.add_argument(
		"--only",
		type=str,
		default="",
		help="Comma separated component list to install.",
	)
	parser.add_argument(
		"--skip",
		type=str,
		default="",
		help="Comma separated component list to skip.",
	)
	parser.add_argument(
		"--dry-run",
		action="store_true",
		help="Show actions without modifying files.",
	)
	parser.add_argument(
		"--non-interactive",
		action="store_true",
		help="Do not prompt for component selection (defaults to all unless --only/--skip is set).",
	)
	return parser.parse_args()


def parse_list(value: str) -> List[str]:
	if not value.strip():
		return []
	return [item.strip() for item in value.split(",") if item.strip()]


def dedupe_keep_order(items: List[str]) -> List[str]:
	seen = set()
	result: List[str] = []
	for item in items:
		if item in seen:
			continue
		seen.add(item)
		result.append(item)
	return result


def command_exists(name: str) -> bool:
	return shutil.which(name) is not None


def build_root_prefix() -> List[str]:
	if os.geteuid() == 0:
		return []
	if command_exists("sudo"):
		return ["sudo"]
	return []


def run_command(
	cmd: List[str],
	*,
	check: bool = True,
	quiet: bool = False,
	input_text: str | None = None,
) -> subprocess.CompletedProcess[str]:
	if quiet:
		return subprocess.run(
			cmd,
			check=check,
			text=True,
			input=input_text,
			stdout=subprocess.DEVNULL,
			stderr=subprocess.DEVNULL,
		)

	return subprocess.run(cmd, check=check, text=True, input=input_text)


def install_packages(pkg_manager: str, packages: List[str], root_prefix: List[str], best_effort: bool = True) -> None:
	if not packages:
		return

	for pkg in packages:
		if pkg_manager == "apt":
			cmd = root_prefix + ["apt-get", "install", "-y", pkg]
		elif pkg_manager == "dnf":
			cmd = root_prefix + ["dnf", "install", "-y", pkg]
		elif pkg_manager == "pacman":
			cmd = root_prefix + ["pacman", "-S", "--needed", "--noconfirm", pkg]
		else:
			raise RuntimeError(f"Unsupported package manager: {pkg_manager}")

		try:
			run_command(cmd, check=True, quiet=True)
			ok(f"Installed or already present package: {pkg}")
		except subprocess.CalledProcessError:
			if best_effort:
				warn(f"Skipped unavailable package: {pkg}")
			else:
				raise RuntimeError(f"Failed to install required package: {pkg}")


def setup_archlinuxcn(root_prefix: List[str]) -> None:
	pacman_conf = Path("/etc/pacman.conf")
	if not pacman_conf.exists():
		raise RuntimeError("/etc/pacman.conf not found")

	content = pacman_conf.read_text(encoding="utf-8")
	if "[archlinuxcn]" not in content:
		repo_block = "\n[archlinuxcn]\nServer = https://repo.archlinuxcn.org/$arch\n"
		if root_prefix:
			run_command(
				root_prefix + ["tee", "-a", "/etc/pacman.conf"],
				check=True,
				quiet=True,
				input_text=repo_block,
			)
		else:
			with pacman_conf.open("a", encoding="utf-8") as handle:
				handle.write(repo_block)
		ok("Added archlinuxcn repository")
	else:
		log("archlinuxcn repository already configured")

	run_command(root_prefix + ["pacman", "-Sy", "--noconfirm"], check=True, quiet=True)
	install_packages("pacman", ["archlinuxcn-keyring"], root_prefix, best_effort=False)


def setup_arch_paru(root_prefix: List[str]) -> None:
	if command_exists("paru"):
		log("paru already installed")
		return
	install_packages("pacman", ["paru"], root_prefix, best_effort=False)


def install_quickshell_arch(root_prefix: List[str]) -> None:
	if not command_exists("pacman"):
		return

	# quickshell requires qt6-5compat on Arch.
	install_packages("pacman", ["qt6-5compat"], root_prefix, best_effort=False)

	if command_exists("quickshell"):
		log("quickshell already installed")
		return

	try:
		install_packages("pacman", ["quickshell"], root_prefix, best_effort=False)
		return
	except RuntimeError:
		warn("quickshell not available in pacman repos, trying paru fallback")

	if not command_exists("paru"):
		raise RuntimeError("paru not available for quickshell fallback")

	try:
		run_command(["paru", "-S", "--noconfirm", "--needed", "quickshell"], check=True, quiet=True)
		ok("Installed quickshell via paru")
	except subprocess.CalledProcessError as exc:
		raise RuntimeError("Failed to install quickshell via paru") from exc


def build_package_plan(pkg_manager: str, selected_components: List[str]) -> List[str]:
	manager_map = PACKAGE_MAP.get(pkg_manager)
	if manager_map is None:
		raise RuntimeError(f"Unsupported package manager from bootstrap: {pkg_manager}")

	planned: List[str] = []
	for component in selected_components:
		planned.extend(manager_map.get(component, []))

	return dedupe_keep_order(planned)


def prompt_component_selection() -> List[str]:
	if not sys.stdin.isatty():
		warn("No interactive TTY detected. Defaulting to all components.")
		return COMPONENTS.copy()

	items = COMPONENTS.copy()
	checked = [True for _ in items]
	cursor = 0
	message = ""

	def render() -> None:
		print("\033[2J\033[H", end="")
		print(f"{LAVENDER}==>{RESET} {SUB}Choose components to install{RESET}")
		print(f"{SUB}Use Up/Down to move, Space or Tab to toggle, Enter to confirm.{RESET}")
		print(f"{LAVENDER}{'-' * 76}{RESET}")
		for idx, name in enumerate(items):
			desc = COMPONENT_DESCRIPTIONS.get(name, "")
			mark = "x" if checked[idx] else " "
			prefix = f"{LAVENDER}>{RESET}" if idx == cursor else " "
			print(f"{prefix} [{mark}] {name:<12} {SUB}{desc}{RESET}")
		print(f"{LAVENDER}{'-' * 76}{RESET}")
		if message:
			print(f"{YELLOW}{message}{RESET}")

	def read_key() -> str:
		first = sys.stdin.read(1)
		if first != "\x1b":
			return first

		second = sys.stdin.read(1)
		if second != "[":
			return first

		third = sys.stdin.read(1)
		if third == "A":
			return "UP"
		if third == "B":
			return "DOWN"
		return "ESC"

	fd = sys.stdin.fileno()
	old_settings = termios.tcgetattr(fd)
	print("\033[?25l", end="", flush=True)
	try:
		tty.setraw(fd)
		while True:
			render()
			key = read_key()

			if key == "UP":
				cursor = (cursor - 1) % len(items)
				message = ""
				continue

			if key == "DOWN":
				cursor = (cursor + 1) % len(items)
				message = ""
				continue

			if key in (" ", "\t"):
				checked[cursor] = not checked[cursor]
				message = ""
				continue

			if key in ("\r", "\n"):
				selected = [name for idx, name in enumerate(items) if checked[idx]]
				if not selected:
					message = "Please select at least one component."
					continue
				print()
				ok(f"Selected: {', '.join(selected)}")
				return selected

			if key.lower() == "q":
				print()
				warn("Selection cancelled by user. Defaulting to all components.")
				return COMPONENTS.copy()
	finally:
		termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)
		print("\033[?25h", end="", flush=True)


def install_system_packages(pkg_manager: str, selected_components: List[str]) -> None:
	section("Installing system packages and fonts")
	root_prefix = build_root_prefix()
	if os.geteuid() != 0 and not root_prefix:
		raise RuntimeError("Need root privileges or sudo to install system packages")

	if pkg_manager == "apt":
		run_command(root_prefix + ["apt-get", "update", "-y"], check=True, quiet=True)
	if pkg_manager == "pacman":
		run_command(root_prefix + ["pacman", "-Sy", "--noconfirm"], check=True, quiet=True)

	packages = build_package_plan(pkg_manager, selected_components)
	if packages:
		log(f"Package plan: {', '.join(packages)}")
		install_packages(pkg_manager, packages, root_prefix, best_effort=True)
	else:
		warn("No distro packages mapped for the selected components.")

	if pkg_manager == "pacman" and "quickshell" in selected_components:
		setup_archlinuxcn(root_prefix)
		setup_arch_paru(root_prefix)
		install_quickshell_arch(root_prefix)

	if "aerospace" in selected_components:
		warn("aerospace is macOS-oriented. Linux package installation is skipped.")
	if "sketchybar" in selected_components:
		warn("sketchybar is macOS-oriented. Linux package installation is skipped.")

	if command_exists("fc-cache"):
		run_command(["fc-cache", "-f"], check=False, quiet=True)
		ok("Font cache refreshed")


def ensure_bootstrap_guard(args: argparse.Namespace) -> bool:
	bootstrapped = os.environ.get("DOTFILES_BOOTSTRAPPED") == "1"
	if bootstrapped and args.from_bootstrap:
		return True

	print(
		f"{RED}[INSTALL][ERROR]{RESET} Please run ./bootstrap.sh first. Direct execution of install.py is blocked.",
		file=sys.stderr,
	)
	return False


def resolve_components(only_items: List[str], skip_items: List[str]) -> List[str]:
	unknown_only = [name for name in only_items if name not in COMPONENTS]
	unknown_skip = [name for name in skip_items if name not in COMPONENTS]

	if unknown_only or unknown_skip:
		unknown = unknown_only + unknown_skip
		raise ValueError(f"Unknown component(s): {', '.join(unknown)}")

	selected = COMPONENTS if not only_items else [name for name in COMPONENTS if name in only_items]
	return [name for name in selected if name not in skip_items]


def select_components(args: argparse.Namespace) -> List[str]:
	only_items = parse_list(args.only)
	skip_items = parse_list(args.skip)

	if only_items or skip_items:
		return resolve_components(only_items, skip_items)

	if args.non_interactive:
		log("Non-interactive mode enabled, selecting all components.")
		return COMPONENTS.copy()

	return prompt_component_selection()


def backup_path(backup_root: Path, name: str) -> Path:
	candidate = backup_root / name
	if not candidate.exists():
		return candidate

	stamp = datetime.now().strftime("%H%M%S")
	return backup_root / f"{name}-{stamp}"


def move_to_backup(target: Path, backup_root: Path, name: str, dry_run: bool) -> Tuple[bool, str]:
	if not target.exists() and not target.is_symlink():
		return True, "no existing target"

	dest = backup_path(backup_root, name)
	if dry_run:
		return True, f"would backup to {dest}"

	dest.parent.mkdir(parents=True, exist_ok=True)
	shutil.move(str(target), str(dest))
	return True, f"backed up to {dest}"


def install_component(
	repo_root: Path,
	config_root: Path,
	backup_root: Path,
	name: str,
	mode: str,
	dry_run: bool,
) -> InstallResult:
	source = repo_root / name
	target = config_root / name

	if not source.exists():
		return InstallResult(name, "skip", f"source missing: {source}")

	if mode == "link" and target.is_symlink():
		try:
			if target.resolve() == source.resolve():
				return InstallResult(name, "skip", "already linked")
		except FileNotFoundError:
			pass

	ok, backup_msg = move_to_backup(target, backup_root, name, dry_run)
	if not ok:
		return InstallResult(name, "fail", backup_msg)

	if dry_run:
		return InstallResult(name, "ok", f"{backup_msg}; would {mode} from {source} to {target}")

	try:
		target.parent.mkdir(parents=True, exist_ok=True)
		if mode == "copy":
			shutil.copytree(source, target, symlinks=True)
		else:
			target.symlink_to(source)
		return InstallResult(name, "ok", f"{backup_msg}; installed")
	except Exception as exc:  # noqa: BLE001
		return InstallResult(name, "fail", str(exc))


def write_manifest(manifest_path: Path, results: List[InstallResult], dry_run: bool) -> None:
	data = {
		"timestamp": datetime.now().isoformat(timespec="seconds"),
		"dry_run": dry_run,
		"results": [
			{"name": item.name, "status": item.status, "message": item.message}
			for item in results
		],
	}
	manifest_path.parent.mkdir(parents=True, exist_ok=True)
	manifest_path.write_text(json.dumps(data, ensure_ascii=True, indent=2), encoding="utf-8")


def main() -> int:
	args = parse_args()

	if not ensure_bootstrap_guard(args):
		return 1

	distro = os.environ.get("DOTFILES_DISTRO", "unknown")
	distro_like = os.environ.get("DOTFILES_DISTRO_LIKE", "")
	distro_version = os.environ.get("DOTFILES_DISTRO_VERSION", "unknown")
	pkg_manager = os.environ.get("DOTFILES_PKG_MANAGER", "unknown")

	log(
		f"Context received from bootstrap: distro={distro}, like={distro_like or 'n/a'}, "
		f"version={distro_version}, manager={pkg_manager}"
	)

	try:
		selected = select_components(args)
	except ValueError as exc:
		return fail(str(exc))

	if not selected:
		log("No components selected. Nothing to do.")
		return 0

	try:
		install_system_packages(pkg_manager, selected)
	except RuntimeError as exc:
		return fail(str(exc))

	repo_root = Path(__file__).resolve().parent
	config_root = Path.home() / ".config"
	timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
	backup_root = config_root / "dotfiles-backup" / timestamp

	section("Deploying dotfiles configuration")
	log(f"Install mode: {args.mode}")
	log(f"Selected components: {', '.join(selected)}")
	if args.dry_run:
		log("Dry run enabled. No filesystem changes will be made.")

	results: List[InstallResult] = []
	for name in selected:
		result = install_component(
			repo_root=repo_root,
			config_root=config_root,
			backup_root=backup_root,
			name=name,
			mode=args.mode,
			dry_run=args.dry_run,
		)
		results.append(result)
		if result.status == "ok":
			ok(f"{name}: {result.message}")
		elif result.status == "skip":
			warn(f"{name}: {result.message}")
		else:
			print(f"{RED}[INSTALL][FAIL]{RESET} {name}: {result.message}")

	manifest_path = backup_root / "manifest.json"
	if args.dry_run:
		manifest_path = config_root / "dotfiles-backup" / "dry-run-manifest.json"
	write_manifest(manifest_path, results, args.dry_run)
	ok(f"Manifest written to {manifest_path}")

	failures = [item for item in results if item.status == "fail"]
	skipped = [item for item in results if item.status == "skip"]
	succeeded = [item for item in results if item.status == "ok"]

	section("Summary")
	print(
		f"{LAVENDER}[INSTALL]{RESET} "
		f"{GREEN}success={len(succeeded)}{RESET}, "
		f"{YELLOW}skipped={len(skipped)}{RESET}, "
		f"{RED}failed={len(failures)}{RESET}"
	)

	if failures:
		return 1
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
