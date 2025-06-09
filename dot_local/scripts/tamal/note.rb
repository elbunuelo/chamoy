require_relative 'utils'
require_relative 'constants'

def open_note(config)
  note_name = config.name
  if note_name.empty?
    puts 'Please provide a note name.'
    exit 1
  end

  template_path = "#{TEMPLATES_DIRECTORY}/#{config.template}.md"
  file_path = "#{NOTES_DIRECTORY}/#{note_name}.md"
  log("Destination filepath is #{file_path}", 'DEBUG', config)

  if config.template.empty?
    log('No template specified, will open an empty note.', 'DEBUG', config)
  else
    log("Opening note using template #{template_path}.", 'DEBUG', config)
  end

  if !config.template.empty? && !File.exist?(template_path)
    log(
      "Template #{config.template} was selected but it doesn't exist in the templates directory, no template will be applied.", 'WARN', config
    )
  end

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

  File.new(file_path, 'w+') unless File.exist? file_path
  system(EDITOR, file_path)
end

def replace_mustache(mustache)
  operation, *args = mustache.split ' '
  return mustache unless operation == 'format-date'

  args = args.join ' '
  date_regex = /\s*(now|\(\s*date "(?<relative_date>.*)"\s*\))\s*/
  return mustache unless date_match = args.match(date_regex)

  date_function = date_match[0].strip
  date_format = args[date_function.length...].gsub('\'', '').strip

  relative_date = date_match[:relative_date]
  date = Date.today
  if date_function != 'now' && relative_date != 'today'
    relative_date = date_match[:relative_date]
    relative_part, relative_day = relative_date.split ' '

    target_day = Date.parse(relative_day).wday
    days_until = (target_day - date.wday) % 7
    days_until = 7 if days_until == 0
    days_until *= -1 if relative_part == 'last'

    date += days_until
  end

  date.strftime(date_format)
end
