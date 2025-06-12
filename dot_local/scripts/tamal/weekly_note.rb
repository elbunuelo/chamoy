require_relative 'note'
require_relative 'constants'

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

def print_weekly_file_path
  puts weekly_file_path
end

def open_weekly_note(config)
  config.name = File.basename(weekly_file_path)[0..-4]
  config.template = 'weekly'

  open_note(config)
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

  blocks = week[:days][config.date][:blocks]
  block = blocks.detect { |b| config.time >= b[:start_time] && config.time <= b[:end_time] }

  return unless block

  puts(block[:tasks].map { |t| t[:task] })
end

def time_blocks(config)
  week = parse_weekly_note
  today = Date.today

  # Check if today exists in the weekly note
  if week[:days][today]
    blocks = week[:days][today][:blocks]

    # Output each time block in the requested format
    blocks.each do |block|
      puts "#{block[:start_time].strftime('%H:%M')} - #{block[:end_time].strftime('%H:%M')}"
    end
  end
end

def add_task(config)
  week = parse_weekly_note
  blocks = week[:days][config.date][:blocks]

  # First, check if the current time falls within any existing block
  existing_block_index = blocks.find_index { |block| config.time >= block[:start_time] && config.time <= block[:end_time] }

  # If we found an existing block that contains the current time, use it
  if existing_block_index
    blocks[existing_block_index][:tasks] << { task: config.task, status: 'pending' }
  else
    # Otherwise, find the right position to insert a new block
    block_index = 0
    inserted = false

    # If there are no blocks yet, create the first one starting at current time
    if blocks.empty?
      new_start_time = config.time
      new_end_time = new_start_time + (30 * 60) # 30 minutes later

      blocks << {
        start_time: new_start_time,
        end_time: new_end_time,
        tasks: [],
        notes: []
      }
      block_index = 0
      inserted = true
    else
      # Try to find where to insert the new block
      blocks.each_with_index do |block, i|
        next if block[:start_time] < config.time

        # If we're here, we found a block that starts after the current time
        block_index = i

        # If there's a previous block, start from its end time
        if i > 0
          new_start_time = blocks[i-1][:end_time]
          new_end_time = new_start_time + (30 * 60) # 30 minutes later

          # If this would overlap with the next block, adjust end time
          if new_end_time > block[:start_time]
            new_end_time = block[:start_time]
          end
        else
          # No previous block, start from current time
          new_start_time = config.time
          new_end_time = [new_start_time + (30 * 60), block[:start_time]].min
        end

        blocks.insert(block_index, {
          start_time: new_start_time,
          end_time: new_end_time,
          tasks: [],
          notes: []
        })

        inserted = true
        break
      end

      # If we didn't insert a block (meaning this goes at the end), add it now
      unless inserted
        # Start from the end time of the last block
        new_start_time = blocks.last[:end_time]
        new_end_time = new_start_time + (30 * 60) # 30 minutes later

        blocks << {
          start_time: new_start_time,
          end_time: new_end_time,
          tasks: [],
          notes: []
        }
        block_index = blocks.length - 1
        inserted = true
      end
    end

    # Add the task to the new block
    blocks[block_index][:tasks] << { task: config.task, status: 'pending' }
  end

  output_weekly_note(week, config)
end

def add_note(config)
  week = parse_weekly_note
  blocks = week[:days][config.date][:blocks]

  block_index = 0
  blocks.each_with_index do |block, i|
    next if block[:start_time] < config.start_time

    block_index = i
    if block[:start_time] == config.start_time
      block[:end_time] = [block[:end_time], config.end_time].max
    else
      blocks.insert(block_index, {
                      start_time:,
                      end_time:,
                      tasks: [],
                      notes: []
                    })
    end
    break
  end

  blocks[block_index][:notes] << "- #{config.note}"

  output_weekly_note(week, config)
end

def add_three_p(config)
  week = parse_weekly_note
  week[:three_p][config.section.to_sym] << "- #{config.note}"

  output_weekly_note(week, config)
end

def update_task(config)
  week = parse_weekly_note
  blocks = week[:days][config.date][:blocks]

  block_index = 0
  blocks.each_with_index do |block, i|
    next if block[:start_time] < config.start_time

    block_index = i
    break
  end

  blocks[block_index][:tasks][config.task_index][:status] = config.status

  output_weekly_note(week, config)
end
