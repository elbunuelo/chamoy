class TamalConfig
  attr_accessor :debug, :action, :date, :time, :task, :note, :name, :template, :start_time, :end_time, :task_index,
                :status, :section

  def initialize
    @debug = false
    @action = nil
    @date = Date.today
    @time = Time.now
    @start_time = Time.now
    @end_time = Time.now
    @task = nil
    @note = nil
    @status = nil
    @parser = nil
    @name = nil
    @template = nil
    @task_index = nil
    @section = nil

    parse_options
  end

  def parse_options
    OptionParser.new do |opts|
      @parser = opts
      opts.on('-o', '--open NOTE_NAME', 'Open or create note NOTE_NAME in your default editor.') do |name|
        @action = 'open'
        @name = name
      end

      opts.on('-p', '--note-path NOTE_NAME',
              'Create note NOTE_NAME if it doesn\'t exist and output its path.') do |name|
        @action = 'note-path'
        @name = name
      end

      opts.on('-w', '--weekly', 'Open the weekly notes in your default editor.') do
        @action = 'weekly'
      end

      opts.on('-W', '--weekly-note-path', 'Open the weekly notes in your default editor.') do
        @action = 'weekly-note-path'
      end

      opts.on(
        '-T',
        '--tasks',
        'List the tasks for the specified DATE and TIME. Uses current date and time if not provided'
      ) do
        @action = 'tasks'
      end

      opts.on(
        '-b',
        '--time-blocks',
        'List all time blocks for today in format <start_time>-<end_time>'
      ) do
        @action = 'time_blocks'
      end

      opts.on(
        '--day-line-numbers',
        'List the line numbers and days of the week for each day header in the weekly note'
      ) do
        @action = 'day_line_numbers'
      end

      opts.on('-D', '--debug') do
        @debug = true
      end

      opts.on('-d', '--date DATE') do |date|
        @date = Date.parse date
      end

      opts.on('-t', '--time TIME') do |time|
        @time = Time.parse time
      end

      opts.on('-s', '--start-time TIME') do |time|
        @start_time = Time.parse time
      end

      opts.on('-e', '--end-time TIME') do |time|
        @end_time = Time.parse time
      end

      opts.on('-a', '--add-task TASK',
              'Add a new task for the specified DATE and TIME. Uses current date and time if nor provided') do |task|
        @action = 'add_task'
        @task = task
      end

      opts.on('-n', '--note NOTE') do |note|
        @action ||= 'add_note'
        pp @action
        @note = note
      end

      opts.on('-3', '--three-p SECTION', 'Add the note to the specified 3P section') do |section|
        @action = 'three_p'
        @section = section.downcase
      end

      opts.on('-u', '--update-task INDEX') do |index|
        @action = 'update_task'
        @task_index = index.to_i
      end

      opts.on('-S', '--status STATUS') do |status|
        @status = status
      end

      opts.on('-h', '--help') do
        print opts
        exit
      end
    end.parse!
  end
end
