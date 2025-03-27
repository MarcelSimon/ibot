#!/bin/bash
set -e

USER_ID=${LOCAL_UID:-10000}
GROUP_ID=${LOCAL_GID:-10000}

# Adjust user/group IDs only if they're different from existing
CURRENT_UID=$(id -u vscode)
CURRENT_GID=$(id -g vscode)

if [ "$USER_ID" != "$CURRENT_UID" ]; then
    usermod -u ${USER_ID} vscode
fi

if [ "$GROUP_ID" != "$CURRENT_GID" ]; then
    groupmod -g ${GROUP_ID} vscode
fi

chown -R vscode:vscode /home/vscode

# Switch to user vscode to execute command
exec gosu vscode /usr/local/bin/nvidia_entrypoint.sh "$@"
