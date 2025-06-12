require_relative 'utils'
require_relative 'constants'
require_relative 'mustache'

# Applies the specified template to the note in the
# destination file.
#
# The function does nothing if either the destination file
# already exists or the template file does not exist.
def apply_template(config, template_path, file_path)
  if File.exist?(template_path) && !File.exist?(file_path)
    log('Applying template to new note.', 'DEBUG', config)
    File.open(file_path, 'w+') do |file|
      File.foreach(template_path) do |template_line|
        if matches = template_line.match(MUSTACHE_REGEX)
          log(template_line.gsub(MUSTACHE_REGEX, replace_mustache(matches[:mustache])), 'DEBUG', config)
          log(replace_mustache(matches[:mustache]), 'DEBUG', config)
          file.write(template_line.gsub(MUSTACHE_REGEX,
                                        replace_mustache(matches[:mustache])))
        else
          file.write(template_line)
        end
      end
    end
  elsif File.exist?(file_path)
    log('Destination file exists, no templates applied.', 'DEBUG', config)
  end
end

# Gets the note file path based on the note name.
#
# @param note_name [String] The name of the note.
# @return [String] The full path to the note file.
def get_note_path(note_name)
  "#{NOTES_DIRECTORY}/#{note_name}.md"
end

# Prepares a note file by applying a template and ensuring the file exists.
#
# @param config [TamalConfig] The configuration object.
# @return [String] The path to the prepared note file.
def prepare_note_file(config)
  note_name = config.name
  if note_name.empty?
    puts 'Please provide a note name.'
    exit 1
  end

  template_path = "#{TEMPLATES_DIRECTORY}/#{config.template}.md"
  file_path = get_note_path(note_name)
  log("Destination filepath is #{file_path}", 'DEBUG', config)

  # Create notes directory if it doesn't exist
  FileUtils.mkdir_p(File.dirname(file_path)) unless Dir.exist?(File.dirname(file_path))

  if config.template.empty?
    log('No template specified, will create an empty note if needed.', 'DEBUG', config)
  else
    log("Using template #{template_path}.", 'DEBUG', config)
  end

  if !config.template.empty? && !File.exist?(template_path)
    log(
      "Template #{config.template} was selected but it doesn't exist in the templates directory, no template will be applied.", 'WARN', config
    )
  end

  apply_template(config, template_path, file_path)
  File.new(file_path, 'w+') unless File.exist? file_path
  
  file_path
end

# Creates a note if it doesn't exist and returns its path.
#
# @param config [TamalConfig] The configuration object.
def note_path(config)
  file_path = prepare_note_file(config)
  puts file_path
end

# Opens a note for editing, optionally applying a template to the note.
#
# Creates the note if it doesn't already exist based on the value
# of config.name.
#
# When config.template exists and the note does not yet exist, the
# note is created and the template applied to it, replacing
# mustache values when applicable.
def open_note(config)
  file_path = prepare_note_file(config)
  system(EDITOR, file_path)
end
