require "faraday"
require "json"

connection = Faraday.new
headers = { "X-Request-Start" => "t=#{Time.now.to_f.round(3)}",
            "Content-Type" =>  "application/json" }
response = connection.get("http://localhost:3000") do |request|
  request.headers = headers
end

puts response.status
puts "\e[33m#{response.reason_phrase}\e[0m" if response.status != 200
puts response.body
