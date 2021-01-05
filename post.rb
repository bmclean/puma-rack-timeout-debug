require "faraday"
require "json"

payload = ""
7500.times do
  payload += "g5555555aaMCCCCCCEBRBCCCCCIA/QQQQ777sWWWWWssH2lFFFFFYWQ1VVVVV2hhhhGUgaGSDSSSSSRSJBBg"
end

puts "Payload size: #{payload.size}"

connection = Faraday.new
headers = { "X-Request-Start" => "t=#{Time.now.to_f.round(3)}",
            "Content-Type" =>  "application/json" }
start_time = Time.now.utc
response = connection.post("http://localhost:3000") do |request|
  request.headers = headers
  request.body = { data: payload }.to_json
end

puts response.status
puts "\e[33m#{response.reason_phrase}\e[0m" if response.status != 200
puts response.body
puts "Duration #{(Time.now.utc - start_time).round(2)} seconds"
