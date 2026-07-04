#!/usr/bin/env bash
# Author: Arun
# Description: This script installs the prerequisites for the Java web application.

# Stop on errors, missing variables, or failed commands inside pipelines.
set -euo pipefail

# Root users do not need sudo. Normal users need sudo for package installs.
if [[ "$(id -u)" -eq 0 ]]; then
  SUDO=""
else
  # Fail early if sudo is not installed on the machine.
  if ! command -v sudo >/dev/null 2>&1; then
    echo "sudo is required. Run as root or install sudo first." >&2
    exit 1
  fi

  # Jenkins and other automation shells cannot type a sudo password.
  # If passwordless sudo is not configured, ask the user to run manually.
  if [[ ! -t 0 ]] && ! sudo -n true 2>/dev/null; then
    echo "sudo needs a password, but this shell is non-interactive." >&2
    echo "Run this script from your normal terminal: bash scripts/install_prereqs.sh" >&2
    exit 1
  fi

  SUDO="sudo"
fi

# Detect the available package manager and install project prerequisites.
# These tools are needed for Java builds, Git operations, downloads, archive
# extraction, and Ansible-based server configuration.
if command -v apt-get >/dev/null 2>&1; then
  # Ubuntu/Debian.
  $SUDO apt-get update
  $SUDO apt-get install -y openjdk-21-jdk maven curl unzip git ansible
elif command -v dnf >/dev/null 2>&1; then
  # Fedora/RHEL 8+.
  $SUDO dnf install -y java-21-openjdk-devel maven curl unzip git ansible
elif command -v yum >/dev/null 2>&1; then
  # Older CentOS/RHEL.
  $SUDO yum install -y java-21-openjdk-devel maven curl unzip git ansible
elif command -v brew >/dev/null 2>&1; then
  # macOS with Homebrew.
  brew install openjdk@21 maven curl unzip git ansible
else
  echo "Unsupported OS: install Java 21, Maven, curl, unzip, git, and Ansible manually." >&2
  exit 1
fi

echo "Prerequisites installed."
