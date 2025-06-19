class TamalConfig
  attr_accessor :debug, :action, :date, :time, :task, :note, :name, :template, :start_time, :end_time, :task_index,
                :status, :section, :ticket_id, :user_name, :user_link, :account_name, :account_link

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
    @ticket_id = nil
    @user_name = ''
    @user_link = ''
    @account_name = ''
    @account_link = ''

    parse_options
  end

  def parse_options
    OptionParser.new do |opts|
      @parser = opts
      opts.on('-o', '--open NOTE_NAME', 'Open or create note NOTE_NAME and output its path.') do |name|
        @action = 'open'
        @name = name
      end

      opts.on('-w', '--weekly', 'Create the weekly notes if needed and output its path.') do
        @action = 'weekly'
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

      opts.on('-u', '--update-task TASK') do |task|
        @action = 'update_task'
        @task = task
      end

      opts.on('-S', '--status STATUS') do |status|
        @status = status
      end

      opts.on('--zendesk TICKET_ID', 'Create a Zendesk ticket note if needed and output its path') do |ticket_id|
        @action = 'zendesk'
        @ticket_id = ticket_id
      end

      opts.on('--user-name USER_NAME', 'User name for Zendesk ticket') do |user_name|
        @user_name = user_name
      end

      opts.on('--user-link USER_LINK', 'User link for Zendesk ticket') do |user_link|
        @user_link = user_link
      end

      opts.on('--account-name ACCOUNT_NAME', 'Account name for Zendesk ticket') do |account_name|
        @account_name = account_name
      end

      opts.on('--account-link ACCOUNT_LINK', 'Account link for Zendesk ticket') do |account_link|
        @account_link = account_link
      end

      opts.on('-h', '--help') do
        print opts
        exit
      end
    end.parse!
  end
end
