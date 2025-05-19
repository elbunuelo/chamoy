#! /usr/bin/env fish

function addToPath
 set -xg PATH "$PATH:$argv[1]"
end
