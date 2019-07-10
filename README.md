[![Build Status](https://semaphoreci.com/api/v1/projects/1a50e5b7-f96e-4fbe-a7de-7da6feaaeec4/474761/badge.svg)](https://semaphoreci.com/simplybusiness/jimmy)

[![Code Climate](https://codeclimate.com/repos/559a90ab6956802f5b013588/badges/4cd4bb76bd603ced0222/gpa.svg)](https://codeclimate.com/repos/559a90ab6956802f5b013588/feed)

# Jimmy

Jimmy is a middleware to store the Rails logs as one entry per request in JSON format. The log is timestamped, includes request parameters, and may also include application-specific fields such as backoffice username.  Something like this:

```
{"timestamp":"2014-01-24T09:06:59.949Z","duration":0.617041,
 "response_code":200,"remote_address":"127.0.0.1",
 "uri":"/backoffice/?vertical_id=professional","user_agent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10.8; rv:26.0) Gecko/20100101 Firefox/26.0","referer":"http://localhost:3000/admin_users/sign_in",
"query_params":{"vertical_id":["professional"]},
 "request_method":"GET","controller":"xxxx",
 "action":"index","local_address":"10.0.4.195"}
```
(Lines in the real log are not split: I added that for markdown)
Note that the timestamp is always the first entry. so that unix sort(1) can be used to merge logs from nodes in a cluster.

The log is stored in `log/production_json.log`.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'jimmy'
```

And then execute:

    $ bundle

## Usage

In order to allow a Rails application to write JSON logs you need to add Jimmy as middleware
(just after default middleware which captures exception and shows debug screen):

`config.middleware.insert_after ActionDispatch::DebugExceptions, Jimmy::Rails::RequestLogger`

It possible configure the samplers to use via a Rails initializer:

```
Jimmy.configure do |config|
  config.samplers = [Jimmy::Samplers::Time, Jimmy::Samplers::Memory]
end
```

 The available samplers are:

* `Jimmy::Samplers::Time` - it used to store the request duration
* `Jimmy::Samplers::Memory` - it used to store the RSS memory value for the ruby process

As default the only active sampler is `Jimmy::Samplers::Time`

## Configuration

Various configuration options are provided when setting up Jimmy in your Rails application

#### filter_uri

Defaults to `false`. Can be configured in your Rails application's Jimmy initializer with `config.filter_uri = true`. If set to true,
Jimmy will filter any `Rails.application.config.filter_parameters` from the URI query string as well as the query params.

#### logger_stream

Can be used to specify the stream used for the logging output in your Jimmy initializer eg. `config.logger_stream = STDOUT`. Will default
to using the `#file_path` as defined below.

#### file_path

Set the file path of the log output file via `config.file_path = path/to/file.log`. Path will default to `::Rails.root + 'log' + (::Rails.env + '_json.log')`

## Using the logs

### Searching and filtering

Because the log is JSON, you can parse it in any language that
can parse JSON.  Such as Javascript.  `script/json_log_find.js`
is a noddy node.js script which accepts JSON logs on stdin, and
takes command line parameters to find entries matching specified criteria

```
$ cat log/development_json.log | node script/json_log_find.js   \
   '(this.remote_address=="127.0.0.1") && (this.controller)' \
   timestamp local_address uri
{"timestamp":"2014-01-23T17:47:01.871Z","local_address":"10.0.4.195","uri":"/admin_users/sign_in"}
{"timestamp":"2014-01-24T09:06:40.714Z","local_address":"10.0.4.195","uri":"/backoffice/"}
{"timestamp":"2014-01-24T09:06:40.989Z","local_address":"10.0.4.195","uri":"/admin_users/sign_in"}
{"timestamp":"2014-01-24T09:06:48.162Z","local_address":"10.0.4.195","uri":"/admin_users/sign_in"}
{"timestamp":"2014-01-24T09:06:59.141Z","local_address":"10.0.4.195","uri":"/admin_users/sign_in"}
{"timestamp":"2014-01-24T09:06:59.949Z","local_address":"10.0.4.195","uri":"/backoffice/"}
```

### Combining logs from multiple sources

If you have many nodes in a cluster, you can merge logs from them using standard Unix tools : `cat *.log | sort`


## How it works/how to customize the log format

* The default log format is set in `lib/middleware/simple_request_logger.rb` which is an abstract class iplementing a Rack middleware, that knows nothing of Rails.  It is specified in `spec/middleware/simple_request_logger_spec.rb`

* We subclass it in `lib/middleware/rails/request_logger.rb`: this provides implementations of

 * `#stream` that tell it where to send the log
 * `#filter_attributes` that adds the local IP address and filters passwords from parameters

* We add before_filters to `ApplicationController` which logs Rails controller name and action name through `Jimmy::Rails::ControllerRuntime` that is included at runtime via `ActiveSupport`

* If you need other stuff logged in some context, add your own filters that run in that context.  Simples.

## Using the Ruby logger

You can trigger a logger "manually" by using [Ruby::Logger](https://github.com/simplybusiness/jimmy/blob/master/lib/jimmy/ruby/logger.rb). It uses the same configuration as the middleware logger.

Simple usage example:

```ruby
Jimmy::Ruby:Logger.instance.log({message: "Error message"})
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## For maintainers

Use `gem-release` to maintain versions https://github.com/svenfuchs/gem-release.

To update the patch version (e.g. 0.0.1 to 0.0.2), after merging the PR to `master` run:

```
gem bump --tag --release
```

if instead you want to bump the minor version (e.g. 0.0.1 to 0.1.0):

```
gem bump --version minor --tag --release
```

or major version (e.g. 0.0.1 to 1.0.0):

```
gem bump --version major --tag --release
```

## Copyright

Copyright © 2016-2017 Simply Business. See LICENSE for details.
