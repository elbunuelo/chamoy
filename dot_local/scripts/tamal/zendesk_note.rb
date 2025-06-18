require_relative 'note'
require_relative 'constants'
require 'fileutils'

# Returns the file path for a Zendesk ticket note based on the ticket ID
def zendesk_file_path(ticket_id)
  "#{NOTES_DIRECTORY}/zendesk/#{ticket_id}.md"
end

# Prints the file path for a Zendesk ticket note
def print_zendesk_file_path(ticket_id)
  puts zendesk_file_path(ticket_id)
end

# Custom template handling for Zendesk tickets
# This applies our specific placeholders without modifying the core mustache system
def apply_zendesk_template(template_path, file_path, config)
  return if File.exist?(file_path) || !File.exist?(template_path)
  
  # Create the directory if it doesn't exist
  FileUtils.mkdir_p(File.dirname(file_path)) unless Dir.exist?(File.dirname(file_path))
  
  # Read the template and replace our custom placeholders
  template_content = File.read(template_path)
  
  # Replace our custom placeholders
  template_content.gsub!('{{ ticket_id }}', config.ticket_id || '')
  template_content.gsub!('{{ user_name }}', config.user_name || '')
  template_content.gsub!('{{ user_link }}', config.user_link || '')
  template_content.gsub!('{{ account_name }}', config.account_name || '')
  template_content.gsub!('{{ account_link }}', config.account_link || '')
  
  # Process any remaining mustache expressions (like dates) using the existing system
  final_content = ''
  template_content.each_line do |line|
    if matches = line.match(MUSTACHE_REGEX)
      final_content += line.gsub(MUSTACHE_REGEX, replace_mustache(matches[:mustache]))
    else
      final_content += line
    end
  end
  
  # Write the processed content to the file
  File.write(file_path, final_content)
end

# Opens a Zendesk ticket note, creating it if it doesn't exist
def open_zendesk_note(config)
  ticket_id = config.ticket_id
  if ticket_id.nil? || ticket_id.empty?
    puts 'Please provide a ticket ID.'
    exit 1
  end
  
  # Define the paths
  template_path = "#{TEMPLATES_DIRECTORY}/zendesk.md"
  file_path = zendesk_file_path(ticket_id)
  
  # Apply our custom template handling
  apply_zendesk_template(template_path, file_path, config)
  
  # Create an empty file if it doesn't exist
  File.new(file_path, 'w+') unless File.exist?(file_path)
  
  # Open the file in the editor
  system(EDITOR, file_path)
end
