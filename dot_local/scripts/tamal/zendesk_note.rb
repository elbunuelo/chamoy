require_relative 'note'
require_relative 'constants'
require 'fileutils'

# Section headers in the Zendesk template
DESCRIPTION_SECTION_REGEX = /^##\s+Description\s+of\s+the\s+Issue/i
HYPOTHESIS_SECTION_REGEX = /^##\s+Hypothesis/i
INVESTIGATION_SECTION_REGEX = /^##\s+Investigation\s+Steps/i
NOTES_SECTION_REGEX = /^##\s+Notes/i
RESOLUTION_SECTION_REGEX = /^##\s+Resolution/i

# Returns the file path for a Zendesk ticket note based on the ticket ID
def zendesk_file_path(ticket_id)
  "#{NOTES_DIRECTORY}/zendesk/#{ticket_id}.md"
end

# Prints the file path for a Zendesk ticket note
def print_zendesk_file_path(ticket_id)
  if ticket_id.nil? || ticket_id.empty?
    puts 'Please provide a ticket ID.'
    exit 1
  end
  puts zendesk_file_path(ticket_id)
end

# Apply the zendesk template with custom placeholders
def apply_zendesk_template(template_path, file_path, config)
  return if File.exist?(file_path) || !File.exist?(template_path)

  # Create the directory if it doesn't exist
  FileUtils.mkdir_p(File.dirname(file_path)) unless Dir.exist?(File.dirname(file_path))

  # Read the template and replace our custom placeholders
  template_content = File.read(template_path)

  # Replace our custom placeholders
  template_content = template_content.gsub('{{ ticket_id }}', config.ticket_id || '')
  template_content = template_content.gsub('{{ user_name }}', config.user_name || '')
  template_content = template_content.gsub('{{ user_link }}', config.user_link || '')
  template_content = template_content.gsub('{{ account_name }}', config.account_name || '')
  template_content = template_content.gsub('{{ account_link }}', config.account_link || '')

  # Process any remaining mustache expressions (like dates) using the existing system
  final_content = ''
  template_content.each_line do |line|
    final_content += if matches = line.match(MUSTACHE_REGEX)
                       line.gsub(MUSTACHE_REGEX, replace_mustache(matches[:mustache]))
                     else
                       line
                     end
  end

  # Write the processed content to the file
  File.write(file_path, final_content)
end

# Creates a Zendesk ticket note if it doesn't exist and returns its path
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

  # Output the file path instead of opening it
  puts file_path
end

# Parse a Zendesk ticket note and return its content as a hash with sections
def parse_zendesk_note(ticket_id)
  file_path = zendesk_file_path(ticket_id)

  # If the file doesn't exist, create it first
  unless File.exist?(file_path)
    config = TamalConfig.new
    config.ticket_id = ticket_id
    open_zendesk_note(config)
  end

  # Initialize the structure to hold the parsed content
  content = {
    header: [],
    description: [],
    hypothesis: [],
    investigation: [],
    notes: [],
    resolution: []
  }

  current_section = :header

  # Parse the file line by line
  File.open(file_path) do |file|
    file.each_line do |line|
      if line.match?(DESCRIPTION_SECTION_REGEX)
        current_section = :description
        content[current_section] << line.chomp
      elsif line.match?(HYPOTHESIS_SECTION_REGEX)
        current_section = :hypothesis
        content[current_section] << line.chomp
      elsif line.match?(INVESTIGATION_SECTION_REGEX)
        current_section = :investigation
        content[current_section] << line.chomp
      elsif line.match?(NOTES_SECTION_REGEX)
        current_section = :notes
        content[current_section] << line.chomp
      elsif line.match?(RESOLUTION_SECTION_REGEX)
        current_section = :resolution
        content[current_section] << line.chomp
      else
        content[current_section] << line.chomp
      end
    end
  end

  content
end

# Add a note to a specific section of a Zendesk ticket note
def add_zendesk_section_note(config)
  ticket_id = config.ticket_id
  section = config.section ? config.section.to_sym : :notes # Default to notes section if not specified
  note = config.note

  if ticket_id.nil? || ticket_id.empty?
    puts 'Please provide a ticket ID.'
    exit 1
  end

  if note.nil? || note.empty?
    puts 'Please provide a note to add.'
    exit 1
  end

  # Map the section name to the internal section key
  section_map = {
    'description' => :description,
    'hypothesis' => :hypothesis,
    'investigation' => :investigation,
    'notes' => :notes,
    'resolution' => :resolution,
    # Add aliases for easier typing
    'desc' => :description,
    'hyp' => :hypothesis,
    'invest' => :investigation,
    'res' => :resolution
  }

  section_key = section_map[section.to_s.downcase]
  if section_key.nil?
    puts "Unknown section: #{section}. Valid sections are: description, hypothesis, investigation, notes, resolution."
    exit 1
  end

  # Parse the current content
  content = parse_zendesk_note(ticket_id)

  # Add the note to the specified section
  # Find the last non-empty line in the section
  last_non_empty_index = content[section_key].rindex { |line| !line.strip.empty? } || 0

  # Add a blank line if the last line isn't already blank
  content[section_key] << '' if last_non_empty_index == content[section_key].length - 1

  # Add the note with a bullet point
  content[section_key] << "- #{note}"
  content[section_key] << ''

  # Write the updated content back to the file
  file_path = zendesk_file_path(ticket_id)
  File.open(file_path, 'w') do |file|
    %i[header description hypothesis investigation notes resolution].each do |section|
      content[section].each do |line|
        file.puts line
      end
    end
  end

  puts file_path
end
