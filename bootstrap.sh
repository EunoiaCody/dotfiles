#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_SCRIPT="$SCRIPT_DIR/install.py"
REPO_URL="https://github.com/EunoiaCody/dotfiles.git"
CLONE_DIR="${DOTFILES_CLONE_DIR:-$HOME/.local/share/dotfiles}"

is_streamed_script() {
	case "${BASH_SOURCE[0]}" in
		/dev/fd/*|/proc/self/fd/*)
			return 0
			;;
		*)
			return 1
			;;
	esac
}

log() {
	echo "[BOOTSTRAP] $*"
}

fail() {
	echo "[BOOTSTRAP][ERROR] $*" >&2
	exit 1
}

prepare_install_script() {
	if ! is_streamed_script && [[ -f "$INSTALL_SCRIPT" ]]; then
		return
	fi

	log "install.py not found next to bootstrap.sh, preparing repository clone..."

	if ! command -v git >/dev/null 2>&1; then
		fail "git is required to clone dotfiles repository when install.py is missing."
	fi

	mkdir -p "$(dirname "$CLONE_DIR")"

	if [[ -d "$CLONE_DIR/.git" ]]; then
		log "Found existing dotfiles repo at $CLONE_DIR, pulling latest changes..."
		git -C "$CLONE_DIR" pull --ff-only || fail "Failed to update existing repository at $CLONE_DIR"
	else
		if [[ -d "$CLONE_DIR" ]]; then
			log "Directory $CLONE_DIR exists but is not a git repo. Reusing local files."
		else
			log "Cloning dotfiles repository into $CLONE_DIR..."
			git clone "$REPO_URL" "$CLONE_DIR" || fail "Failed to clone dotfiles repository"
		fi
	fi

	if [[ ! -f "$CLONE_DIR/install.py" ]]; then
		fail "install.py is still missing after repository preparation at $CLONE_DIR"
	fi

	SCRIPT_DIR="$CLONE_DIR"
	INSTALL_SCRIPT="$SCRIPT_DIR/install.py"
	log "Using install script at $INSTALL_SCRIPT"
}

ensure_linux() {
	local kernel
	kernel="$(uname -s 2>/dev/null || true)"
	if [[ "$kernel" != "Linux" ]]; then
		fail "This installer only supports Linux. Please run this script on a Linux distribution."
	fi
}

load_os_release() {
	if [[ ! -f /etc/os-release ]]; then
		fail "Cannot detect Linux distribution because /etc/os-release is missing."
	fi
	# shellcheck disable=SC1091
	source /etc/os-release
}

detect_package_manager() {
	if command -v apt-get >/dev/null 2>&1; then
		PKG_MANAGER="apt"
		return
	fi

	if command -v dnf >/dev/null 2>&1; then
		PKG_MANAGER="dnf"
		return
	fi

	if command -v pacman >/dev/null 2>&1; then
		PKG_MANAGER="pacman"
		return
	fi

	PKG_MANAGER=""
}

require_sudo_if_needed() {
	if [[ "$(id -u)" -eq 0 ]]; then
		SUDO=""
		return
	fi

	if ! command -v sudo >/dev/null 2>&1; then
		fail "sudo is required when not running as root."
	fi

	if ! sudo -v; then
		fail "Failed to obtain sudo privileges."
	fi

	SUDO="sudo"
}

install_base_packages() {
	case "$PKG_MANAGER" in
		apt)
			local packages=(
				git
				python3
				python3-pip
				curl
				ca-certificates
				clang
				make
				cmake
				pkg-config
			)
			log "Updating apt package index..."
			$SUDO apt-get update -y
			log "Installing base dependencies with apt..."
			$SUDO apt-get install -y "${packages[@]}"
			;;
		dnf)
			local packages=(
				git
				python3
				python3-pip
				curl
				ca-certificates
				clang
				make
				cmake
				pkgconf-pkg-config
			)
			log "Installing base dependencies with dnf..."
			$SUDO dnf install -y "${packages[@]}"
			;;
		pacman)
			local packages=(
				git
				python
				python-pip
				curl
				ca-certificates
				clang
				make
				cmake
				pkgconf
			)
			log "Refreshing pacman databases..."
			$SUDO pacman -Sy --noconfirm
			log "Installing base dependencies with pacman..."
			$SUDO pacman -S --needed --noconfirm "${packages[@]}"
			;;
		*)
			fail "Unsupported Linux package manager. Please install git/python3/clang manually, then run python3 install.py through bootstrap."
			;;
	esac
}

install_optional_package() {
	local pkg="$1"
	case "$PKG_MANAGER" in
		apt)
			$SUDO apt-get install -y "$pkg"
			;;
		dnf)
			$SUDO dnf install -y "$pkg"
			;;
		pacman)
			$SUDO pacman -S --needed --noconfirm "$pkg"
			;;
		*)
			return 1
			;;
	esac
}

install_runtime_packages() {
	local packages=()

	case "$PKG_MANAGER" in
		apt)
			packages=(
				fish
				kitty
				mpv
				neovim
				bat
				ripgrep
				nodejs
				npm
				ffmpeg
			)
			;;
		dnf)
			packages=(
				fish
				kitty
				mpv
				neovim
				bat
				ripgrep
				nodejs
				npm
				ffmpeg
			)
			;;
		pacman)
			packages=(
				fish
				niri
				kitty
				mpv
				neovim
				neovide
				bat
				yazi
				ripgrep
				nodejs
				npm
				ffmpeg
				qt6-5compat
			)
			;;
		*)
			return
			;;
	esac

	log "Installing runtime/application packages (best effort)..."
	for pkg in "${packages[@]}"; do
		if install_optional_package "$pkg" >/dev/null 2>&1; then
			log "Installed or already present: $pkg"
		else
			log "Skipped unavailable package: $pkg"
		fi
	done
}

ensure_archlinuxcn_repo() {
	local repo_block='[archlinuxcn]
Server = https://repo.archlinuxcn.org/$arch'

	if grep -q '^\[archlinuxcn\]' /etc/pacman.conf; then
		log "archlinuxcn repo already configured"
		return
	fi

	log "Adding archlinuxcn repository to /etc/pacman.conf"
	if [[ -n "$SUDO" ]]; then
		printf "\n%s\n" "$repo_block" | $SUDO tee -a /etc/pacman.conf >/dev/null
	else
		printf "\n%s\n" "$repo_block" >>/etc/pacman.conf
	fi
}

install_arch_paru() {
	if command -v paru >/dev/null 2>&1; then
		log "paru already installed"
		return
	fi

	log "Installing paru from archlinuxcn"
	if ! install_optional_package paru >/dev/null 2>&1; then
		fail "Failed to install paru. Please check archlinuxcn mirror and pacman configuration."
	fi
}

install_quickshell_with_fallback() {
	if [[ "$PKG_MANAGER" == "pacman" ]]; then
		if pacman -Q qt6-5compat >/dev/null 2>&1; then
			log "Prerequisite already installed: qt6-5compat"
		else
			log "Installing prerequisite package: qt6-5compat"
			if ! $SUDO pacman -S --needed --noconfirm qt6-5compat; then
				fail "Failed to install required package qt6-5compat"
			fi
		fi
	fi

	if command -v quickshell >/dev/null 2>&1; then
		log "quickshell already installed"
		return
	fi

	if install_optional_package quickshell >/dev/null 2>&1; then
		log "Installed quickshell via pacman repository"
		return
	fi

	if ! command -v paru >/dev/null 2>&1; then
		log "paru not available, cannot install quickshell from AUR fallback"
		return
	fi

	log "Installing quickshell via paru fallback"
	if paru -S --noconfirm --needed quickshell >/dev/null 2>&1; then
		log "Installed quickshell via paru"
	else
		log "Failed to install quickshell via paru"
	fi
}

setup_arch_extras() {
	if [[ "$PKG_MANAGER" != "pacman" ]]; then
		return
	fi

	ensure_archlinuxcn_repo
	log "Refreshing pacman databases after archlinuxcn setup"
	$SUDO pacman -Sy --noconfirm

	log "Installing archlinuxcn keyring"
	install_optional_package archlinuxcn-keyring >/dev/null 2>&1 || fail "Failed to install archlinuxcn-keyring"

	install_arch_paru
	install_quickshell_with_fallback
}

run_main_installer() {
	if [[ ! -f "$INSTALL_SCRIPT" ]]; then
		prepare_install_script
	fi

	if [[ ! -f "$INSTALL_SCRIPT" ]]; then
		fail "install.py not found at $INSTALL_SCRIPT"
	fi

	if ! command -v python3 >/dev/null 2>&1; then
		fail "python3 is not available after dependency installation."
	fi

	export DOTFILES_BOOTSTRAPPED="1"
	export DOTFILES_OS="linux"
	export DOTFILES_DISTRO="${ID:-unknown}"
	export DOTFILES_DISTRO_LIKE="${ID_LIKE:-}"
	export DOTFILES_DISTRO_VERSION="${VERSION_ID:-unknown}"
	export DOTFILES_PKG_MANAGER="$PKG_MANAGER"

	log "Launching install.py with distro context: distro=${DOTFILES_DISTRO}, manager=${DOTFILES_PKG_MANAGER}"
	python3 "$INSTALL_SCRIPT" --from-bootstrap "$@"
}

main() {
	ensure_linux
	load_os_release
	detect_package_manager

	if [[ -z "${PKG_MANAGER:-}" ]]; then
		fail "Cannot determine package manager for this Linux distribution."
	fi

	log "Detected distro: ${ID:-unknown} ${VERSION_ID:-unknown}"
	log "Using package manager: $PKG_MANAGER"

	require_sudo_if_needed
	install_base_packages
	setup_arch_extras
	install_runtime_packages
	prepare_install_script
	run_main_installer "$@"
}

main "$@"