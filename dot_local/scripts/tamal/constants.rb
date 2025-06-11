EDITOR = (ENV['EDITOR'] || 'vim').freeze
NOTES_DIRECTORY = (ENV['NOTES_DIR'] || "#{ENV['HOME']}/notes").freeze
TEMPLATES_DIRECTORY = (ENV['TEMPLATES_DIR'] || "#{__dir__}/templates").freeze
MUSTACHE_REGEX = /{{\s*(?<mustache>.*)\s*}}/
