if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export XDG_CONFIG_HOME=$HOME/.config

for FILE in $(find $XDG_CONFIG_HOME/zsh -mindepth 1 -maxdepth 1 -type f | sort); do
  source $FILE
done
