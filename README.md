### Puma Slow Client Debug

Using Puma, Rack Timeout and Faraday.

Start the server:

    RACK_TIMEOUT_SERVICE_TIMEOUT=15 \
    RACK_TIMEOUT_WAIT_TIMEOUT=30 \ 
    RACK_TIMEOUT_WAIT_OVERTIME=60 \
    bundle exec puma -C config/puma.rb config.ru

    ruby post.rb

Response:

    200
    Got it!

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

    500
    An unhandled lowlevel error occurred. The application logs may have details.

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

    500
    An unhandled lowlevel error occurred. The application logs may have details.

    #<Rack::Timeout::RequestTimeoutError: Request waited 13ms, then ran for longer than 1987ms >

##### Wait timeout with link conditioner example:

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
    RACK_TIMEOUT_WAIT_TIMEOUT=5 \
    RACK_TIMEOUT_WAIT_OVERTIME=8 \
    bundle exec puma -C config/puma.rb config.ru

    ruby post.rb

We have 5 seconds of wait_time plus 8 seconds of wait_overtime.
This request (using the 3gslow throttle) exceeds 13 seconds, so we see:

    #<Rack::Timeout::RequestExpiryError: Request older than 13000ms.>

Setting RACK_TIMEOUT_WAIT_OVERTIME=20 allows the payload to be fully received:

    source=rack-timeout id=16a5369d-c196-45e4-879e-667db3902dcb wait=23000ms timeout=1000ms service=6ms state=completed at=info

!! Remember to stop the network throttle !!

    throttle --stop --localhost
