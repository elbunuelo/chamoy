#! /usr/bin/env fish

function nuke
  cd "$HOME/projects/aha-app"
  wo rm -rf node_modules packages/*/node_modules .turbo-cache /Users/nariasgonzalez/Library/pnpm/store/v3
end
