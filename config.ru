require "rack-timeout"
require "rack"

use Rack::Timeout
use Rack::Lock # ensure requests are serial

app = Proc.new do |env|
  sleep Float(ENV["EXAMPLE_SLEEP_TIME"] || 0 )
  req = Rack::Request.new(env)
  puts "POST body size: #{req.body.read.size}" if req.post?
  ["200", {"Content-Type" => "text/json"}, ["Got it!"]]
end

run app
