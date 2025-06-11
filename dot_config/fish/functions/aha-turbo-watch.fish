#! /usr/bin/env fish

function aha-turbo-watch
  cd "$HOME/projects/aha-app"
  set notified 0
  fish -c "pnpm install --frozen-lockfile --prefer-offline && NODE_OPTIONS=--max_old_space_size=12000 pnpm turbo:watch" | while read line
   echo $line
    if test $notified = 0 && string match -q "*webpack compiled*" $line
      /Applications/VLC.app/Contents/MacOS/VLC --intf dummy /Users/nariasgonzalez/Downloads/Human/Rifleman/RiflemanReady1.wav > /dev/null 2>&1
      set notified 1
    end
  end
end

