#! /usr/bin/env bash

SCRIPT_DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
HOSTNAME_SCRIPT="$(hostname).sh"

if [ -f "$SCRIPT_DIR/$HOSTNAME_SCRIPT" ]; then
  echo "Running $HOSTNAME_SCRIPT"
  /bin/bash "$SCRIPT_DIR/$HOSTNAME_SCRIPT"
fi
