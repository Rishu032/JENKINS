#!/bin/bash

# ===== CONFIGURATION =====
JENKINS_HOME_BASE="/HDD2TB/iansari/jenkins"
JENKINS_DATA_DIR="$JENKINS_HOME_BASE/jenkins_data"
BACKUP_DIR="$JENKINS_HOME_BASE/jenkins_backups"
CONTAINER_NAME="jenkins"

mkdir -p "$BACKUP_DIR"

container_exists() {
    docker ps -a --format '{{.Names}}' | grep -Fxq "$CONTAINER_NAME"
}

container_running() {
    docker ps --format '{{.Names}}' | grep -Fxq "$CONTAINER_NAME"
}

take_backup() {
    DATE=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="$BACKUP_DIR/jenkins_backup_$DATE.tar.gz"

    if [ ! -d "$JENKINS_DATA_DIR" ]; then
        echo "❌ ERROR: Jenkins data directory missing: $JENKINS_DATA_DIR"
        exit 1
    fi

    echo "🛑 Checking Jenkins container: $CONTAINER_NAME ..."

    if container_exists; then
        if container_running; then
            echo "🛑 Stopping Jenkins container..."
            docker stop "$CONTAINER_NAME" >/dev/null || echo "⚠️ Failed to stop container."
        else
            echo "⚠️ Container exists but is not running."
        fi
    else
        echo "⚠️ Container does NOT exist — backup will be taken live (unsafe)."
    fi

    echo "💾 Creating backup: $BACKUP_FILE ..."
    tar -czf "$BACKUP_FILE" -C "$JENKINS_HOME_BASE" "$(basename "$JENKINS_DATA_DIR")"
    if [ $? -ne 0 ]; then
        echo "❌ Backup FAILED."
        exit 1
    fi

    if container_exists; then
        if ! container_running; then
            echo "▶️ Starting Jenkins container..."
            docker start "$CONTAINER_NAME" >/dev/null
        else
            echo "ℹ️ Container was already running."
        fi
    else
        echo "⚠️ Container not started because it does not exist."
    fi

    echo "✅ Backup completed."
}

take_backup
