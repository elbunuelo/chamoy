#! /usr/bin/env bash

cd "$(dirname "$0")"
HOSTNAME_SCRIPT="$(hostname).sh"

if [ -f "./$HOSTNAME_SCRIPT" ]; then
 . "./$HOSTNAME_SCRIPT"
fi
