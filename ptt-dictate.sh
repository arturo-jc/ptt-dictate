#!/bin/bash

STATE_DIR="/tmp/ptt-dictate"
mkdir -p "$STATE_DIR"
STACK_TAG="ptt-dictate"
LOCKFILE="$STATE_DIR/$STACK_TAG.lock"
PIDFILE="$STATE_DIR/$STACK_TAG.pid"
RECORDING="$STATE_DIR/$STACK_TAG.wav"
TRANSCRIPT="$STATE_DIR/$STACK_TAG.txt"
APP_NAME="PTT Dictate"
WHISPER_URL="127.0.0.1:8080/inference"
YDOTOOL_SOCKET="${YDOTOOL_SOCKET:-/tmp/.ydotool_socket}"

toast(){ notify-send -a "$APP_NAME" -t 1500 -u low -h "string:x-dunst-stack-tag:$STACK_TAG" "$1" "${2:-}"; }

# Function to start recording
start_recording() {
    if [ -f "$LOCKFILE" ]; then
        toast "Recording Error" "Recording already in progress"
        exit 1
    fi

    # Create lockfile
    touch "$LOCKFILE"

    # Start recording with pw-record
    pw-record "$RECORDING" &
    RECORDER_PID=$!

    # Save the PID
    echo $RECORDER_PID > "$PIDFILE"

    toast "Recording" "Saving to: $RECORDING"
}

transcribe() {
  curl -sS ${WHISPER_URL} \
    -H "Content-Type: multipart/form-data" \
    -F file="${RECORDING}" \
    -F response-format="json" \
    | jq -r .text \
    | tr '\n' ' '  \
    | sed 's/  \+/ /g; s/^[[:space:]]\+//; s/[[:space:]]\+$//' \
    > "$TRANSCRIPT"
}

type_text() {
  YDOTOOL_SOCKET="$YDOTOOL_SOCKET" ydotool type -d=0 "$(cat $TRANSCRIPT)"
}

# Function to stop recording
stop_recording() {
    if [ ! -f "$LOCKFILE" ]; then
        toast "Recording Error" "No recording in progress"
        exit 1
    fi

    if [ ! -f "$PIDFILE" ]; then
        toast "Recording Error" "PID file not found"
        rm "$LOCKFILE"
        exit 1
    fi

    RECORDER_PID=$(cat "$PIDFILE")

    # Send SIGTERM to allow graceful shutdown
    if kill -0 $RECORDER_PID 2>/dev/null; then
        kill -TERM $RECORDER_PID

        # Wait for the process to finish writing (up to 5 seconds)
        for i in {1..50}; do
            if ! kill -0 $RECORDER_PID 2>/dev/null; then
                break
            fi
            sleep 0.1
        done

        # If still running, force kill
        if kill -0 $RECORDER_PID 2>/dev/null; then
            kill -KILL $RECORDER_PID
        fi
    fi

    # Additional safety: sync filesystem to ensure file is written
    sync

    # Small delay to ensure file handle is released
    sleep 0.2

    # Clean up
    rm "$LOCKFILE"
    rm "$PIDFILE"

    toast "Recording Stopped" "Processing..."
    transcribe
    type_text
}

# Main logic
if [ -f "$LOCKFILE" ]; then
    stop_recording
else
    start_recording
fi
