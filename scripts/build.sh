#!/usr/bin/env bash
# Author: Arun
# Description : This script builds the Java web application using Maven and creates a WAR fil and confirms 
# Stop immediately if any command fails, an unset variable is used, or a
# command inside a pipeline fails.
set -euo pipefail

# Find the project root dynamically.
# If this script is /home/arun/Desktop/CK_E2E_Tasks_4-7-26/scripts/build.sh,
# ROOT_DIR becomes /home/arun/Desktop/CK_E2E_Tasks_4-7-26.
# This avoids hard-coding local paths and also works inside Jenkins workspaces.
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Maven project files are inside the app/ directory.
cd "$ROOT_DIR/app"

# Clean old build output and create a fresh WAR file under app/target/.
mvn clean package

# Expected WAR file created by Maven. The name comes from app/pom.xml:
# <finalName>devops-e2e-app</finalName>
WAR_FILE="$ROOT_DIR/app/target/devops-e2e-app.war"

# Fail the script if Maven did not create the WAR file.
# This makes Jenkins fail the Build stage instead of continuing silently.
if [[ ! -f "$WAR_FILE" ]]; then
  echo "WAR not found at $WAR_FILE" >&2
  exit 1
fi

# Print the final WAR path for humans and Jenkins logs.
echo "Built $WAR_FILE"
