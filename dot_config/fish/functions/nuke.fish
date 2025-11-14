#! /usr/bin/env fish

function nuke
  cd "$HOME/projects/aha-app"
  echo "Removing node modules."
  time rm -rf node_modules
  echo "Removing packages node modules."
  time rm -rf packages/*/node_modules
  echo "Removing services node modules."
  time rm -rf services/*/node_modules
  echo "Removing turbo cache."
  time rm -rf .turbo-cache
  echo "Removing pnpm store."
  time rm -rf /Users/nariasgonzalez/Library/pnpm/store/v3
end
