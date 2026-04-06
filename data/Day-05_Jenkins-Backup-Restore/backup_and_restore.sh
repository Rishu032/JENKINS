#!/bin/bash

# Jenkins Backup & Restore Script
# Ensure JENKINS_HOME_BASE is set correctly.

# ===== CONFIGURATION =====
JENKINS_HOME_BASE="/HDD2TB/iansari/jenkins"
JENKINS_DATA_DIR="$JENKINS_HOME_BASE/jenkins_data"
BACKUP_DIR="$JENKINS_HOME_BASE/jenkins_backups"
CONTAINER_NAME="jenkins"

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# Check if container exists
container_exists() {
    docker ps -a --format '{{.Names}}' | grep -Fxq "$CONTAINER_NAME"
}

# Check if container is running
container_running() {
    docker ps --format '{{.Names}}' | grep -Fxq "$CONTAINER_NAME"
}

take_backup() {
    DATE=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="$BACKUP_DIR/jenkins_backup_$DATE.zip"

    echo "🛑 Checking Jenkins container: $CONTAINER_NAME ..."

    if container_exists; then
        if container_running; then
            echo "🛑 Stopping Jenkins container..."
            docker stop "$CONTAINER_NAME" >/dev/null || echo "⚠️ Failed to stop container."
        else
            echo "⚠️ Container exists but is not running. Skipping stop."
        fi
    else
        echo "⚠️ Container '$CONTAINER_NAME' does NOT exist. Continuing backup WITHOUT stopping Jenkins."
    fi

    echo "💾 Creating backup: $BACKUP_FILE ..."
    (
        cd "$JENKINS_HOME_BASE" || exit
        zip -r "$BACKUP_FILE" "$(basename "$JENKINS_DATA_DIR")" >/dev/null
    )

    if container_exists && ! container_running; then
        echo "▶️ Attempting to start Jenkins container..."
        docker start "$CONTAINER_NAME" >/dev/null || echo "⚠️ Unable to start container."
    else
        echo "⚠️ Container not started because it does not exist."
    fi

    echo "✅ Backup completed."
    read -n1 -r -p "Press any key to continue..." key
}

restore_backup() {
    LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/jenkins_backup_*.zip 2>/dev/null | head -1)

    if [[ -z "$LATEST_BACKUP" ]]; then
        echo "⚠️ No backups found!"
        return
    fi

    echo "🛑 Checking Jenkins container: $CONTAINER_NAME ..."

    if container_exists; then
        if container_running; then
            echo "🛑 Stopping Jenkins container..."
            docker stop "$CONTAINER_NAME" >/dev/null || echo "⚠️ Failed to stop container."
        else
            echo "⚠️ Container exists but not running. Skipping stop."
        fi
    else
        echo "⚠️ Container '$CONTAINER_NAME' does NOT exist. Restoring anyway."
    fi

    echo "♻️ Restoring from: $LATEST_BACKUP"
    rm -rf "$JENKINS_DATA_DIR"
    mkdir -p "$JENKINS_DATA_DIR"

    (
        cd "$JENKINS_HOME_BASE" || exit
        unzip -o "$LATEST_BACKUP" >/dev/null
    )

    if container_exists && ! container_running; then
        echo "▶️ Attempting to start Jenkins container..."
        docker start "$CONTAINER_NAME" >/dev/null || echo "⚠️ Unable to start container."
    else
        echo "⚠️ Container not started because it does not exist."
    fi

    echo "✅ Restore completed!"
    read -n1 -r -p "Press any key to continue..." key
}

# ===== MENU LOOP =====
while true; do
    clear
    echo "================================="
    echo "🛠 Jenkins Backup & Restore Menu"
    echo "================================="
    echo "1. Take backup"
    echo "2. Restore latest backup"
    echo "x. Exit"
    echo "================================="
    read -rp "Enter your choice: " choice

    case "$choice" in
        1) take_backup ;;
        2) restore_backup ;;
        x|X) echo "👋 Exiting..."; exit 0 ;;
        *) echo "⚠️ Invalid input! Please enter 1, 2, or x." ;;
    esac
done

