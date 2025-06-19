-- time_utils.lua: Time-related utility functions for the tamal plugin

local M = {}

-- Helper function to adjust time by 15 minutes (positive or negative)
M.adjust_time_by_15min = function(time_str, increment)
  local hours, minutes = time_str:match '(%d+):(%d+)'
  if not hours or not minutes then
    return time_str
  end

  hours, minutes = tonumber(hours), tonumber(minutes)

  -- Convert to total minutes and adjust
  local total_minutes = hours * 60 + minutes
  total_minutes = total_minutes + (increment and 15 or -15)

  -- Handle day wrapping
  if total_minutes < 0 then
    total_minutes = total_minutes + 24 * 60 -- Wrap to previous day
  elseif total_minutes >= 24 * 60 then
    total_minutes = total_minutes - 24 * 60 -- Wrap to next day
  end

  -- Convert back to hours and minutes
  local new_hours = math.floor(total_minutes / 60)
  local new_minutes = total_minutes % 60

  return string.format('%02d:%02d', new_hours, new_minutes)
end

-- Helper function to round time to nearest 15 minutes
M.round_time_to_15min = function(hours, minutes, round_up)
  local total_minutes = hours * 60 + minutes
  local remainder = total_minutes % 15

  if remainder == 0 then
    return hours, minutes
  end

  if round_up then
    total_minutes = total_minutes + (15 - remainder)
  else
    total_minutes = total_minutes - remainder
  end

  local new_hours = math.floor(total_minutes / 60)
  local new_minutes = total_minutes % 60

  return new_hours, new_minutes
end

-- Helper function to format time as HH:MM
M.format_time = function(hours, minutes)
  return string.format('%02d:%02d', hours, minutes)
end

-- Helper function to parse time string into minutes
M.parse_time_to_minutes = function(time_str)
  local hours, minutes = time_str:match '(%d+):(%d+)'
  if hours and minutes then
    return tonumber(hours) * 60 + tonumber(minutes)
  end
  return nil
end

return M
