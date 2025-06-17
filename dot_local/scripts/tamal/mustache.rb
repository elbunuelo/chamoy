# Parses the content of a mustache expression and returns the computed value of
# the expression.
#
# The mustache expression must follow this format:
# `{{ format-date <date_expression> '<date_format>' }}`
#
# Where `<date_expression>` is defined as `<now|(date "next|last <day_of_week>")>`
# using `now` as your date expression will use the current date i.e. Date.today.
# A relative date can be specified as "next" or "last" followed by the name of a day
# of the week e.g. "next tuesday" or "last friday".
#
# No other mustache substitutions are currently supported. Any content that does not
# match a mustache expression will be copied over as-is to the newly created document.
#
# @param mustache [String]
# @return [String] The computed value of the expression or the unchanged mustache
# expression if it doesnt' match the expected format.
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
    days_until *= -1 if relative_part == 'last'

    date += days_until
  end

  date.strftime(date_format)
end
