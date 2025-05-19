#! /usr/bin/env zsh

cd "$(dirname "$0")"
github=$(. ./github-prs.sh)
zendesk=$(. ./zendesk.sh)
echo "#[bg=#121212,fg=#dca561]#[fg=#121212,bg=#dca561] $github  $zendesk #[fg=#7e9cd8,bg=#dca561]"
