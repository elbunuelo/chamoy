EDITOR = (ENV['EDITOR'] || 'vi').freeze
NOTES_DIRECTORY = (ENV['NOTES_DIR'] || "#{ENV['HOME']}/notes").freeze
TEMPLATES_DIRECTORY = "#{__dir__}/templates".freeze
MUSTACHE_REGEX = /{{\s*(?<mustache>.*)\s*}}/
