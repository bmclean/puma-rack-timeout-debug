### Puma Slow Client Debug

Start the server:

    RACK_TIMEOUT_SERVICE_TIMEOUT=15 RACK_TIMEOUT_WAIT_TIMEOUT=30 RACK_TIMEOUT_WAIT_OVERTIME=60 bundle exec puma -C config/puma.rb config.ru

    ruby post.rb

Response:

    200
    Got it!

##### Service timeout example:

When "service timeout" is set to 1 second, but the request will sleep for 2 seconds then the request will time out and an error will be raised.

Start the server:

    EXAMPLE_SLEEP_TIME=2 RACK_TIMEOUT_SERVICE_TIMEOUT=1 RACK_TIMEOUT_WAIT_TIMEOUT=30 RACK_TIMEOUT_WAIT_OVERTIME=60 bundle exec puma -C config/puma.rb config.ru

    ruby post.rb

As expected, this times out:

    500
    An unhandled lowlevel error occurred. The application logs may have details.

    #<Rack::Timeout::RequestTimeoutError: Request waited 15ms, then ran for longer than 1000ms >

##### Wait timeout example:

    EXAMPLE_SLEEP_TIME=3 RACK_TIMEOUT_SERVICE_TIMEOUT=15 RACK_TIMEOUT_WAIT_TIMEOUT=1 RACK_TIMEOUT_WAIT_OVERTIME=1 bundle exec puma -C config/puma.rb config.ru

    ruby post.rb

As expected, this times out:

    500
    An unhandled lowlevel error occurred. The application logs may have details.

    #<Rack::Timeout::RequestTimeoutError: Request waited 13ms, then ran for longer than 1987ms >
