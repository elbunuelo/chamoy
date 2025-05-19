#! /usr/bin/env fish

function pnpm
  set _pnpm $(which pnpm)
  wo $_pnpm $argv
end
