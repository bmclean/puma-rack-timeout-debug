### Puma Slow Client Debug

Start the server:

    bundle exec puma -C config/puma.rb config.ru

    curl localhost:3000 -I

Response:

    HTTP/1.1 200 OK
    Content-Type: text/html

##### Service timeout example:

When "service timeout" is set to 1 second, but the request will sleep for 2 seconds then the request will time out and an error will be raised.

Start the server:

    EXAMPLE_SLEEP_TIME=2 RACK_TIMEOUT_SERVICE_TIMEOUT=1 bundle exec puma -C config/puma.rb config.ru

    curl localhost:3000 -I

As expected, this times out:

    HTTP/1.1 500 Internal Server Error
    Content-Length: 1253

    #<Rack::Timeout::RequestTimeoutError: Request ran for longer than 1000ms >

##### Wait timeout example:

    RACK_TIMEOUT_WAIT_TIMEOUT=1 EXAMPLE_SLEEP_TIME=2 bundle exec puma -C config/puma.rb config.ru

    curl localhost:3000 -I -X GET --header "X-Request-Start: t=$(ruby -e 'puts Time.now.to_f.round(3)')"

As expected, this times out:

    HTTP/1.1 500 Internal Server Error
    Content-Length: 1270

    #<Rack::Timeout::RequestTimeoutError: Request waited 16ms, then ran for longer than 984ms >
