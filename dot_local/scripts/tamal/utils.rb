def log(text, level = 'DEBUG', config)
  return unless config.debug

  puts "[#{level}][#{Time.now}] #{text}"
end
