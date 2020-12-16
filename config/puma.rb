# frozen_string_literal: true

threads 5, 5

port ENV.fetch("PORT", 3000)
environment "production"

first_data_timeout ENV.fetch("FIRST_DATA_TIMEOUT", 30).to_i

if ENV.fetch("WEB_CONCURRENCY", 0).to_i > 1
  workers ENV.fetch("WEB_CONCURRENCY").to_i
  preload_app!

  before_fork do
    puts "Puma web server preparing to fork worker processes."
  end

  on_worker_boot do
    puts "Puma worker #{Process.pid} booted."
  end
end

on_restart do
  puts "Puma web server restarted."
end

# Allow puma to be restarted by `rails restart` command.
plugin :tmp_restart
