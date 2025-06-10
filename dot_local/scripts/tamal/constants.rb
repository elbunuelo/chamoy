EDITOR = (ENV['EDITOR'] || 'neovim -c "set laststatus=0" -c "set nonumber" -c "set textwidth=120"').freeze
NOTES_DIRECTORY = (ENV['NOTES_DIR'] || "#{ENV['HOME']}/notes").freeze
TEMPLATES_DIRECTORY = (ENV['TEMPLATES_DIR'] || "#{__dir__}/templates").freeze
MUSTACHE_REGEX = /{{\s*(?<mustache>.*)\s*}}/
