#! /usr/bin/env fish

function los 
  set name (basename (pwd))
  if [ "$argv[1]" != "" ]
    set name $argv[1]
  end

  zellij attach $name || zellij -s $name
end
