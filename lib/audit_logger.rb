class AuditLogger < Logger
  def format_message(severity, timestamp, progname, msg)
    pid, size = `ps ax -o pid,rss | grep -E "^[[:space:]]*#{Process::pid}"`.chomp.split(/\s+/).map {|s| s.strip.to_i}
    "[#{timestamp.to_formatted_s(:db)}] [#{severity}] [#{size} KB] #{msg}\n"
  end
end
