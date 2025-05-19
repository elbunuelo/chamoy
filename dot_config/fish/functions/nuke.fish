#! /usr/bin/env fish

function nuke
  cd "$HOME/projects/aha-app"
  wo rm -rf node_modules packages/*/node_modules .turbo-cache
end
