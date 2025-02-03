#! /usr/bin/env zsh

cd "$(dirname "$0")"
github=$(. ./github-prs.sh)
zendesk=$(. ./zendesk.sh)
echo "#[fg=#9e9e9e,bg=#303030] $github  $zendesk "
