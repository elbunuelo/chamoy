export XDG_CONFIG_HOME=$HOME/.config

for FILE in $(find $XDG_CONFIG_HOME/zsh -type f -mindepth 1 -maxdepth 1 | sort); do
  source $FILE
done
