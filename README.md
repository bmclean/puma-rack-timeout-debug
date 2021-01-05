### Puma 4.3.7 Slow Client Debug

Using Puma, Rack Timeout and Faraday.

Also see https://github.com/bmclean/puma-rails-timeout-debug for a Rails example.

Based on https://github.com/schneems/rack_timeout_demos

Start the server:

    RACK_TIMEOUT_SERVICE_TIMEOUT=15 \
    RACK_TIMEOUT_WAIT_TIMEOUT=30 \
    RACK_TIMEOUT_WAIT_OVERTIME=60 \
    bundle exec puma -C config/puma.rb config.ru

    ruby post.rb

Response:

    Payload size: 630000
    200
    Got it!
    Duration 0.02 seconds

##### Service timeout example:

When "service timeout" is set to 1 second, but the request will sleep for 2 seconds then the request will time out and an error will be raised.

Start the server:

    EXAMPLE_SLEEP_TIME=2 \
    RACK_TIMEOUT_SERVICE_TIMEOUT=1 \
    RACK_TIMEOUT_WAIT_TIMEOUT=30 \
    RACK_TIMEOUT_WAIT_OVERTIME=60 \
    bundle exec puma -C config/puma.rb config.ru

    ruby post.rb

As expected, this times out:

    Payload size: 630000
    500
    Internal Server Error
    An unhandled lowlevel error occurred. The application logs may have details.
    Duration 1.02 seconds

    #<Rack::Timeout::RequestTimeoutError: Request waited 15ms, then ran for longer than 1000ms >

##### Wait timeout example:

Start the server:

    EXAMPLE_SLEEP_TIME=3 \
    RACK_TIMEOUT_SERVICE_TIMEOUT=15 \
    RACK_TIMEOUT_WAIT_TIMEOUT=1 \
    RACK_TIMEOUT_WAIT_OVERTIME=1 \
    bundle exec puma -C config/puma.rb config.ru

    ruby post.rb

As expected, this times out:

    Payload size: 630000
    500
    Internal Server Error
    An unhandled lowlevel error occurred. The application logs may have details.
    Duration 2.01 seconds

    #<Rack::Timeout::RequestTimeoutError: Request waited 13ms, then ran for longer than 1987ms >

##### Wait timeout with link conditioner examples:

The time between when a request is fully received and when rack starts handling it is called 
the wait time. A request's start time, and from that its wait time, is through the availability 
of the X-Request-Start HTTP header.

Relying on X-Request-Start is less than ideal, as it computes the time since the request started 
being received by the web server, rather than the time the request finished being received by the 
web server. That poses a problem for lengthy requests, such as when the client has a slow upload 
speed such as a mobile device.

As a concession to these shortcomings, for requests that have a body present, we allow some 
additional wait time on top of wait_timeout. This aims to make up for time lost to long 
uploads. This extra time is called wait_overtime.

Throttle lets you simulate slow network connections on Linux and Mac OS X:   

    npm install @sitespeed.io/throttle -g

Start the network throttle:

    throttle --profile 3gslow --localhost

Throttle will use sudo so your user will need sudo rights.

Start the server:

    RACK_TIMEOUT_SERVICE_TIMEOUT=1 \
    RACK_TIMEOUT_WAIT_TIMEOUT=3 \
    RACK_TIMEOUT_WAIT_OVERTIME=5 \
    bundle exec puma -C config/puma.rb config.ru

    ruby post.rb

We have 3 seconds of wait_time plus 5 seconds of wait_overtime.
This request (using the 3gslow throttle) exceeds 8 seconds, so we see:

    Payload size: 630000
    500
    Internal Server Error
    An unhandled lowlevel error occurred. The application logs may have details.
    Duration 18.39 seconds

    source=rack-timeout wait=17820ms timeout=8000ms state=expired at=error    
    #<Rack::Timeout::RequestExpiryError: Request older than 8000ms.>

Setting RACK_TIMEOUT_WAIT_OVERTIME=25 allows the payload to be fully received:

    RACK_TIMEOUT_SERVICE_TIMEOUT=1 \
    RACK_TIMEOUT_WAIT_TIMEOUT=3 \
    RACK_TIMEOUT_WAIT_OVERTIME=25 \
    bundle exec puma -C config/puma.rb config.ru

    ruby post.rb

    Payload size: 630000
    200
    Got it!
    Duration 20.97 seconds

    source=rack-timeout wait=18608ms timeout=1000ms service=6ms state=completed at=info

##### What if Puma's first_data_timeout is smaller than wait_time + wait_overtime? 6 < (3 + 5)

    FIRST_DATA_TIMEOUT=6 \
    RACK_TIMEOUT_SERVICE_TIMEOUT=1 \
    RACK_TIMEOUT_WAIT_TIMEOUT=3 \
    RACK_TIMEOUT_WAIT_OVERTIME=5 \
    bundle exec puma -C config/puma.rb config.ru

The response is a rack timeout.

    Payload size: 630000
    500
    Internal Server Error
    An unhandled lowlevel error occurred. The application logs may have details.
    Duration 19.51 seconds

    source=rack-timeout wait=15917ms timeout=8000ms state=expired at=error
    #<Rack::Timeout::RequestExpiryError: Request older than 8000ms.>

##### What if Puma's first_data_timeout is equal to wait_time + wait_overtime? 8 = (3 + 5)

    FIRST_DATA_TIMEOUT=8 \
    RACK_TIMEOUT_SERVICE_TIMEOUT=1 \
    RACK_TIMEOUT_WAIT_TIMEOUT=3 \
    RACK_TIMEOUT_WAIT_OVERTIME=5 \
    bundle exec puma -C config/puma.rb config.ru

The response is a rack timeout.

    Payload size: 630000
    500
    Internal Server Error
    An unhandled lowlevel error occurred. The application logs may have details.
    Duration 22.45 seconds

    source=rack-timeout wait=18237ms timeout=8000ms state=expired at=error
    #<Rack::Timeout::RequestExpiryError: Request older than 8000ms.>

##### What if Puma's first_data_timeout is slightly greater than wait_time + wait_overtime? 10 > (3 + 5)

    FIRST_DATA_TIMEOUT=10 \
    RACK_TIMEOUT_SERVICE_TIMEOUT=1 \
    RACK_TIMEOUT_WAIT_TIMEOUT=3 \
    RACK_TIMEOUT_WAIT_OVERTIME=5 \
    bundle exec puma -C config/puma.rb config.ru

The response is a rack timeout.

    Payload size: 630000
    500
    Internal Server Error
    An unhandled lowlevel error occurred. The application logs may have details.
    Duration 20.42 seconds

    source=rack-timeout wait=19823ms timeout=8000ms state=expired at=error
    #<Rack::Timeout::RequestExpiryError: Request older than 8000ms.>

##### What if Puma's first_data_timeout is greater than wait_time + wait_overtime? 25 > (3 + 5)

    FIRST_DATA_TIMEOUT=25 \
    RACK_TIMEOUT_SERVICE_TIMEOUT=1 \
    RACK_TIMEOUT_WAIT_TIMEOUT=3 \
    RACK_TIMEOUT_WAIT_OVERTIME=5 \
    bundle exec puma -C config/puma.rb config.ru

The response is a rack timeout.

    Payload size: 630000
    500
    Internal Server Error
    An unhandled lowlevel error occurred. The application logs may have details.
    Duration 22.0 seconds

    source=rack-timeout wait=18261ms timeout=8000ms state=expired at=error
    #<Rack::Timeout::RequestExpiryError: Request older than 8000ms.>

###### !! Remember to stop the network throttle !!

    throttle --stop --localhost
