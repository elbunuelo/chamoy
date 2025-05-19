#! /usr/bin/env fish

function aha-start-server
  cd "$HOME/projects/aha-app"
  overmind s --any-can-die
end
