#! /usr/bin/env fish

function nuke
  cd "$HOME/projects/aha-app"
  echo "Removing node modules."
  rm -rf node_modules
  echo "Removing packages node modules."
  rm -rf packages/*/node_modules
  echo "Removing services node modules."
  rm -rf services/*/node_modules
  echo "Removing turbo cache."
  rm -rf .turbo-cache
  echo "Removing pnpm store."
  rm -rf /Users/nariasgonzalez/Library/pnpm/store/v3
end
