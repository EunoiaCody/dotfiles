#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_SCRIPT="$SCRIPT_DIR/install.py"
REPO_URL="https://github.com/EunoiaCody/dotfiles.git"
CLONE_DIR="${DOTFILES_CLONE_DIR:-$HOME/.local/share/dotfiles}"

USE_COLOR=0
if [[ -t 1 ]] && [[ -z "${NO_COLOR:-}" ]]; then
	USE_COLOR=1
fi

if [[ "$USE_COLOR" -eq 1 ]]; then
	C_RESET=$'\033[0m'
	C_LAVENDER=$'\033[38;2;180;190;254m'
	C_GREEN=$'\033[38;2;166;227;161m'
	C_YELLOW=$'\033[38;2;249;226;175m'
	C_RED=$'\033[38;2;243;139;168m'
	C_SUB=$'\033[38;2;186;194;222m'
else
	C_RESET=""
	C_LAVENDER=""
	C_GREEN=""
	C_YELLOW=""
	C_RED=""
	C_SUB=""
fi

section() {
	echo
	echo "${C_LAVENDER}==>${C_RESET} ${C_SUB}$*${C_RESET}"
}

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
	echo "${C_LAVENDER}[BOOTSTRAP]${C_RESET} $*"
}

fail() {
	echo "${C_RED}[BOOTSTRAP][ERROR]${C_RESET} $*" >&2
	exit 1
}

ok() {
	echo "${C_GREEN}[BOOTSTRAP][OK]${C_RESET} $*"
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
	section "Installing minimal bootstrap dependencies"
	case "$PKG_MANAGER" in
		apt)
			local packages=(
				git
				python3
				python3-pip
				curl
				ca-certificates
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
	ok "Bootstrap dependencies are ready"
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
	section "Handing off to install.py"
	python3 "$INSTALL_SCRIPT" --from-bootstrap "$@"
}

main() {
	section "Dotfiles bootstrap starting"
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
	prepare_install_script
	run_main_installer "$@"
}

main "$@"