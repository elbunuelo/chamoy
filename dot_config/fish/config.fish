#! /usr/bin/env fish

set SCRIPT_DIR (dirname (status --current-filename))

for file in $SCRIPT_DIR/fish/*
  source $file
end
