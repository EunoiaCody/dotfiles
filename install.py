#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import os
import shutil
import sys
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import List, Tuple


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


@dataclass
class InstallResult:
	name: str
	status: str
	message: str


def log(message: str) -> None:
	print(f"[INSTALL] {message}")


def fail(message: str) -> int:
	print(f"[INSTALL][ERROR] {message}", file=sys.stderr)
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
	return parser.parse_args()


def parse_list(value: str) -> List[str]:
	if not value.strip():
		return []
	return [item.strip() for item in value.split(",") if item.strip()]


def ensure_bootstrap_guard(args: argparse.Namespace) -> bool:
	bootstrapped = os.environ.get("DOTFILES_BOOTSTRAPPED") == "1"
	if bootstrapped and args.from_bootstrap:
		return True

	print(
		"[INSTALL][ERROR] Please run ./bootstrap.sh first. Direct execution of install.py is blocked.",
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
		selected = resolve_components(parse_list(args.only), parse_list(args.skip))
	except ValueError as exc:
		return fail(str(exc))

	if not selected:
		log("No components selected. Nothing to do.")
		return 0

	repo_root = Path(__file__).resolve().parent
	config_root = Path.home() / ".config"
	timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
	backup_root = config_root / "dotfiles-backup" / timestamp

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
		log(f"{name}: {result.status} - {result.message}")

	manifest_path = backup_root / "manifest.json"
	if args.dry_run:
		manifest_path = config_root / "dotfiles-backup" / "dry-run-manifest.json"
	write_manifest(manifest_path, results, args.dry_run)
	log(f"Manifest written to {manifest_path}")

	failures = [item for item in results if item.status == "fail"]
	skipped = [item for item in results if item.status == "skip"]
	succeeded = [item for item in results if item.status == "ok"]

	log(
		"Summary: "
		f"success={len(succeeded)}, skipped={len(skipped)}, failed={len(failures)}"
	)

	if failures:
		return 1
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
