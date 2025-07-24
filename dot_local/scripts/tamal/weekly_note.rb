require_relative 'note'
require_relative 'constants'
require_relative 'utils'

TIME_BLOCK_REGEX = /^###\s+(?<start_time>\d{1,2}:\d{2})\s+-\s+(?<end_time>\d{1,2}:\d{2})/
DAY_HEADER_REGEX = %r{^##\s+(?<day>Mon|Tue|Wed|Thu|Fri)\s+(?<date>\d{2}/\d{2})}
THREE_P_HEADER_REGEX = /^##\s+3Ps/
THREE_P_PROGRESS_REGEX = /^###\s+Progress/
THREE_P_PLANNED_REGEX = /^###\s+Planned/
THREE_P_PROBLEMS_REGEX = /^###\s+Problems/
TIME_BLOCK_HEADER_REGEX = /^###\s+(?<start_time>\d{1,2}:\d{2})\s+-\s+(?<end_time>\d{1,2}:\d{2})/
TASK_REGEX = /^\s*-\s+\[(?<status>[ x~])\](?<task>.*)/

def weekly_file_path
  note_name = Time.now.strftime '%Y - Week %W'
  "#{NOTES_DIRECTORY}/#{note_name}.md"
end

def open_weekly_note(config)
  config.name = File.basename(weekly_file_path)[0..-4]
  config.template = 'weekly'

  # Use prepare_note_file to create the file without opening it
  file_path = prepare_note_file(config)
  puts file_path
end

def parse_weekly_note
  week = {
    extra: [],
    days: {},
    three_p: {
      progress: [],
      planned: [],
      problems: []
    }
  }

  File.open(weekly_file_path) do |file|
    lines = file.readlines
    current_date = nil
    current_time_block = nil
    content_started = false
    three_p_started = false
    current_three_p = nil

    lines.each_with_index do |line, _i|
      if match = line.match(DAY_HEADER_REGEX)
        content_started = true
        date = Date.parse("#{match[:date]}/#{Date.today.year}")

        current_date = {
          blocks: [],
          notes: []
        }

        current_time_block = nil
        week[:days][date] = current_date
        next
      end

      if line.match(THREE_P_HEADER_REGEX)
        current_date = nil
        current_time_block = nil
        three_p_started = true
        next
      end

      if three_p_started && line.match(THREE_P_PROGRESS_REGEX)
        current_three_p = :progress
        next
      end

      if three_p_started && line.match(THREE_P_PLANNED_REGEX)
        current_three_p = :planned
        next
      end

      if three_p_started && line.match(THREE_P_PROBLEMS_REGEX)
        current_three_p = :problems
        next
      end

      if current_date && time_block_match = line.match(TIME_BLOCK_REGEX)
        current_time_block = {
          start_time: Time.parse(time_block_match[:start_time]),
          end_time: Time.parse(time_block_match[:end_time]),
          tasks: [],
          notes: []
        }

        current_date[:blocks] << current_time_block
        next
      end

      if current_time_block
        if task_match = line.match(TASK_REGEX)
          status = case task_match[:status]
                   when ' '
                     'pending'
                   when 'x'
                     'done'
                   when '~'
                     'canceled'
                   end

          current_time_block[:tasks] << {
            task: task_match[:task].chomp.strip,
            status:
          }
          next
        elsif !line.strip.empty?
          current_time_block[:notes] << line.chomp
          next
        end
      end

      if current_three_p
        week[:three_p][current_three_p] << line.chomp unless line.chomp.empty?
        next
      end

      week[:extra] << line.chomp unless content_started
    end
  end
  week
end

def output_weekly_note(week, config)
  output = []
  week[:extra].each do |extra|
    output << "#{extra}\n"
  end

  week[:days].each do |date, day|
    output << "## #{date.strftime('%a %d/%m')}\n\n"

    day[:blocks].each do |block|
      output << "### #{block[:start_time].strftime('%H:%M')} - #{block[:end_time].strftime('%H:%M')}\n"

      block[:tasks].each do |task|
        output << "\n"
        status = case task[:status]
                 when 'pending'
                   ' '
                 when 'done'
                   'x'
                 when 'canceled'
                   '~'
                 end
        output << "- [#{status}] #{task[:task]}\n"
      end
      output << "\n" unless block[:notes].empty?

      block[:notes].each { |line| output << "#{line}\n" }
      output << "\n"
    end
  end

  output << "## 3Ps\n\n"
  output << "### Progress\n\n"
  week[:three_p][:progress].each { |line| output << "#{line}\n" }
  output << "\n"

  output << "### Planned\n\n"
  week[:three_p][:planned].each { |line| output << "#{line}\n" }
  output << "\n"

  output << "### Problems\n\n"
  week[:three_p][:problems].each { |line| output << "#{line}\n" }
  output << "\n"

  if config.debug
    puts output.join ''
  else
    File.open(weekly_file_path, 'w') do |f|
      f.write output.join ''
    end
  end
end

def tasks(config)
  week = parse_weekly_note

  # Check if the date exists in the weekly note
  if week[:days][config.date].nil?
    puts "No entries found for date: #{config.date}"
    return
  end

  blocks = week[:days][config.date][:blocks]

  all_tasks = blocks.map do |b|
    b[:tasks].map { |t| "#{t[:status]},#{t[:task]}" }
  end.flatten

  puts(all_tasks)
end

def time_blocks(_config)
  week = parse_weekly_note
  today = Date.today

  # Check if today exists in the weekly note
  return unless week[:days][today]

  blocks = week[:days][today][:blocks]

  # Output each time block in the requested format
  blocks.each do |block|
    puts "#{block[:start_time].strftime('%H:%M')} - #{block[:end_time].strftime('%H:%M')}"
  end
end

def day_line_numbers(_config)
  # Open the weekly note file and scan through it line by line
  File.open(weekly_file_path) do |file|
    lines = file.readlines

    # Iterate through each line with its line number
    lines.each_with_index do |line, index|
      # Check if the line matches the day header pattern
      if match = line.match(DAY_HEADER_REGEX)
        # Output the line number (1-based) and the day of the week
        puts "#{index + 1},#{match[:day]}"
      end
    end
  end
end

def add_task(config)
  log("Creating task on #{config.date} at #{config.start_time.strftime '%H:%M'} - #{config.end_time.strftime '%H:%M'}",
      'DEBUG', config)
  week = parse_weekly_note

  # Check if the date exists in the weekly note, if not, create it
  if week[:days][config.date].nil?
    week[:days][config.date] = {
      blocks: [],
      notes: []
    }
  end

  blocks = week[:days][config.date][:blocks]

  existing_block_index = blocks.find_index do |block|
    config.start_time >= block[:start_time] && config.end_time <= block[:end_time]
  end

  if existing_block_index
    blocks[existing_block_index][:tasks] << { task: config.task, status: 'pending' }
  else
    block_index = 0
    found = false
    new_block = {
      start_time: config.start_time,
      end_time: config.end_time,
      tasks: [],
      notes: []
    }

    blocks.each_with_index do |block, i|
      block_index = i
      next if block[:start_time] < config.start_time

      found = true
    end

    block_index = blocks.length unless found
    blocks.insert(
      block_index,
      new_block
    )

    blocks[block_index][:tasks] << { task: config.task, status: 'pending' }
  end

  output_weekly_note(week, config)
end

def add_time_block_note(config)
  week = parse_weekly_note

  # Check if the date exists in the weekly note, if not, create it
  if week[:days][config.date].nil?
    week[:days][config.date] = {
      blocks: [],
      notes: []
    }
  end

  blocks = week[:days][config.date][:blocks]

  block_index = 0
  blocks.each_with_index do |block, i|
    next if block[:start_time] < config.start_time

    block_index = i
    if block[:start_time] == config.start_time
      block[:end_time] = [block[:end_time], config.end_time].max
    else
      blocks.insert(block_index, {
                      start_time: config.start_time,
                      end_time: config.end_time,
                      tasks: [],
                      notes: []
                    })
    end
    break
  end

  blocks[block_index][:notes] << "- #{config.note}"

  output_weekly_note(week, config)
end

def add_three_p_note(config)
  week = parse_weekly_note
  week[:three_p][config.section.to_sym] << "- #{config.note}"

  output_weekly_note(week, config)
end

def update_task(config)
  week = parse_weekly_note

  # Check if the date exists in the weekly note
  if week[:days][config.date].nil?
    puts "No entries found for date: #{config.date}"
    return
  end

  blocks = week[:days][config.date][:blocks]

  # Find the block that contains the current time
  block = blocks.detect { |b| config.time >= b[:start_time] && config.time <= b[:end_time] }
  return unless block

  # Find the task by matching its text
  task = block[:tasks].detect { |t| t[:task].strip == config.task.strip }
  task[:status] = config.status if task

  output_weekly_note(week, config)
end
