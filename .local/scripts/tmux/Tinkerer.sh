#! /usr/bin/env bash

script_dir=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
github=$(./github-prs.sh)
zendesk=$(./zendesk.sh)
echo "#[fg=#9e9e9e,bg=#303030] $github  $zendesk"
