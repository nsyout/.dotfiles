#!/usr/bin/env bash

COLOR_RESET='\033[0m'
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[1;33m'
COLOR_BLUE='\033[0;34m'

info() {
	printf "%b[INFO]%b %s\n" "$COLOR_GREEN" "$COLOR_RESET" "$1"
}

warn() {
	printf "%b[WARN]%b %s\n" "$COLOR_YELLOW" "$COLOR_RESET" "$1"
}

error() {
	printf "%b[ERROR]%b %s\n" "$COLOR_RED" "$COLOR_RESET" "$1" >&2
	return 1
}

step() {
	printf "\n%b==>%b %s\n\n" "$COLOR_BLUE" "$COLOR_RESET" "$1"
}

command_exists() {
	command -v "$1" >/dev/null 2>&1
}
