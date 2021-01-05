### Puma 5.0.3+ Slow Client Debug

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
    Duration 19.4 seconds (???)

    #<Rack::Timeout::RequestExpiryError: Request older than 8000ms.>

But wait! The duration of the request was 19.4 seconds. So it wasn't until after Puma had
received the entire body of the POST request before Rack Timeout checked the X-Request-Start
header...

Setting RACK_TIMEOUT_WAIT_OVERTIME=25 allows the payload to be fully received:

    RACK_TIMEOUT_SERVICE_TIMEOUT=1 \
    RACK_TIMEOUT_WAIT_TIMEOUT=3 \
    RACK_TIMEOUT_WAIT_OVERTIME=25 \
    bundle exec puma -C config/puma.rb config.ru

    ruby post.rb

    Payload size: 630000
    200
    Got it!
    Duration 23.61 seconds

    source=rack-timeout wait=23020ms timeout=1000ms service=8ms state=completed at=info

##### What if Puma's first_data_timeout is smaller than wait_time + wait_overtime? 6 < (3 + 5)

    FIRST_DATA_TIMEOUT=6 \
    RACK_TIMEOUT_SERVICE_TIMEOUT=1 \
    RACK_TIMEOUT_WAIT_TIMEOUT=3 \
    RACK_TIMEOUT_WAIT_OVERTIME=5 \
    bundle exec puma -C config/puma.rb config.ru

The response is 408 - Request Timeout. Rack Timeout isn't given a chance to fire.

    Payload size: 630000
    408
    Request Timeout
    Duration 9.04 seconds

##### What if Puma's first_data_timeout is equal to wait_time + wait_overtime? 8 = (3 + 5)

    FIRST_DATA_TIMEOUT=8 \
    RACK_TIMEOUT_SERVICE_TIMEOUT=1 \
    RACK_TIMEOUT_WAIT_TIMEOUT=3 \
    RACK_TIMEOUT_WAIT_OVERTIME=5 \
    bundle exec puma -C config/puma.rb config.ru

The response is still 408 - Request Timeout.

    Payload size: 630000
    408
    Request Timeout
    Duration 12.88 seconds

##### What if Puma's first_data_timeout is slightly greater than wait_time + wait_overtime? 10 > (3 + 5)

    FIRST_DATA_TIMEOUT=10 \
    RACK_TIMEOUT_SERVICE_TIMEOUT=1 \
    RACK_TIMEOUT_WAIT_TIMEOUT=3 \
    RACK_TIMEOUT_WAIT_OVERTIME=5 \
    bundle exec puma -C config/puma.rb config.ru

The response is still a 408 - Request Timeout.

    Payload size: 630000
    408
    Request Timeout
    Duration 18.69 seconds

##### What if Puma's first_data_timeout is greater than wait_time + wait_overtime? 25 > (3 + 5)

Note: I kept increasing first_data_timeout until the 408s stopped. It needed to be large enough
for Puma to receive the entire body of the slow client POST.

    FIRST_DATA_TIMEOUT=25 \
    RACK_TIMEOUT_SERVICE_TIMEOUT=1 \
    RACK_TIMEOUT_WAIT_TIMEOUT=3 \
    RACK_TIMEOUT_WAIT_OVERTIME=5 \
    bundle exec puma -C config/puma.rb config.ru

Now Rack Timeout is working again:

    Payload size: 630000
    500
    Internal Server Error
    An unhandled lowlevel error occurred. The application logs may have details.
    Duration 20.06 seconds

    #<Rack::Timeout::RequestExpiryError: Request older than 8000ms.>

###### !! Remember to stop the network throttle !!

    throttle --stop --localhost

###### Conclusion

When using Rack Timeout with Puma versions 5.0.3+ the `RACK_TIMEOUT_WAIT_TIMEOUT` and 
`RACK_TIMEOUT_WAIT_OVERTIME` variables don't really work for slow requests. Configuring Puma with a
large enough `first_data_timeout` will allow Rack Timeout to fire. But if the entire client payload
has already been received by your application what is the point in timing out the request?