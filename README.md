[![Build Status](https://semaphoreci.com/api/v1/projects/1a50e5b7-f96e-4fbe-a7de-7da6feaaeec4/474761/badge.svg)](https://semaphoreci.com/simplybusiness/jimmy)

# Jimmy

Jimmy is a middleware to store the Rails logs as one entry per request in JSON format.

## Example

```json
{  
   "timestamp":"2014-01-24T09:06:59.949Z",
   "duration":0.617041,
   "response_code":200,
   "remote_address":"127.0.0.1",
   "uri":"/backoffice/?vertical_id=professional",
   "user_agent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10.8; rv:26.0) Gecko/20100101 Firefox/26.0",
   "referer":"http://localhost:3000/admin_users/sign_in",
   "query_params":{  
      "vertical_id":[  
         "professional"
      ]
   },
   "request_method":"GET",
   "controller":"xxxx",
   "action":"index",
   "local_address":"10.0.4.195"
}
```

* Lines in the real log are not split: added for readability
* Note that the timestamp is always the first entry - unix `sort(1)` can be used to merge logs from nodes in a cluster.

The log is stored in `log/production_json.log`.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'jimmy'
```

And then execute:

```bash
bundle
```

Add Jimmy as middleware:

```ruby
# config/application.rb

config.middleware.insert_after ActionDispatch::DebugExceptions, Jimmy::Rails::RequestLogger
```

## Configuration

```ruby
# config/initializers/jimmy.rb

Jimmy.configure do |config|
  config.samplers              = [Jimmy::Samplers::Time, Jimmy::Samplers::Memory]
  config.filter_uri            = true
  config.logger_stream         = STDOUT
  config.file_path             = 'log/json_formatted.log'
  config.additional_context    = ->(env) { { username: env['REMOTE_USER'] } }
  config.browser_csv_file_path = Rails.root.join('data', 'browsers.csv')
end
```

#### `samplers`

* `Jimmy::Samplers::Time` - used to store the request duration
* `Jimmy::Samplers::Memory` - used to store the RSS memory value for the Ruby process

Example: `config.samplers = [Jimmy::Samplers::Time, Jimmy::Samplers::Memory]`

Default: `Jimmy::Samplers::Time`

#### `filter_uri`

If `true`, Jimmy will filter any `Rails.application.config.filter_parameters` from the URI query string as well as the query params.

Example: `config.filter_uri = true`

Default: `false`

#### `logger_stream`

Can be used to specify the stream used for the logging output.

Example: `config.logger_stream = STDOUT`. 

Default: `#file_path` as below.

#### `file_path`

Set the file path of the log output file.

Example: `config.file_path = 'path/to/file.log'`.

Default: `::Rails.root + 'log' + (::Rails.env + '_json.log')`

#### `additional_context`

Set additional attributes to be logged. Should be an object that responds to `#call` with one argument - the `env`.

Example: `config.additional_context = ->(env) { { username: env['REMOTE_USER'] } }`

Default: `->(_) { {} }`

#### `browser_csv_file_path`

* File path of a CSV that stores browser data for user agents
* This is used to add browser data to every request.
* User agent data comes from [WhatIsMyBrowser](https://developers.whatismybrowser.com/useragents/database/)
* It should have columns named:

```
user_agent,simple_software_string,simple_sub_description_string,simple_operating_platform_string,software,software_name,software_name_code,software_version,software_version_full,operating_system,operating_system_name,operating_system_name_code,operating_system_version,operating_system_version_full,operating_system_flavour,operating_system_flavour_code,operating_system_frameworks,operating_platform,operating_platform_code,operating_platform_vendor_name,software_type,software_sub_type,software_type_specific,hardware_type,hardware_sub_type,hardware_sub_sub_type,hardware_type_specific,layout_engine_name,layout_engine_version,extra_info,extra_info_dict,capabilities,detected_addons
```

**Example**

* `HTTP_USER_AGENT` is `Mozilla/5.0 (iPad; CPU OS 8_4 like Mac OS X) AppleWebKit/600.1.4 (KHTML, like Gecko) Version/8.0 Mobile/12H143 Safari/600.1.4`
* The browser details are looked up and merged into the log entry:
```ruby
  'browser' => {
    'capabilities' => [],
    'detected_addons' => [],
    'extra_info' => {},
    'extra_info_dict' => { 'Mobile Build' => '12H143' },
    'hardware_sub_sub_type' => nil,
    'hardware_sub_type' => 'tablet',
    'hardware_type' => 'mobile',
    'hardware_type_specific' => nil,
    'layout_engine_name' => 'WebKit',
    'layout_engine_version' => ['600', '1', '4'],
    'operating_platform' => 'iPad',
    'operating_platform_code' => nil,
    'operating_platform_vendor_name' => 'Apple',
    'operating_system' => 'iOS 8.4',
    'operating_system_flavour' => nil,
    'operating_system_flavour_code' => nil,
    'operating_system_frameworks' => [],
    'operating_system_name' => 'iOS',
    'operating_system_name_code' => 'ios',
    'operating_system_version' => '8.4',
    'operating_system_version_full' => '8.4',
    'simple_operating_platform_string' => 'Apple iPad',
    'simple_software_string' => 'Safari 8 on iOS 8.4',
    'simple_sub_description_string' => nil,
    'software' => 'Safari 8',
    'software_name' => 'Safari',
    'software_name_code' => 'safari',
    'software_sub_type' => 'web-browser',
    'software_type' => 'browser',
    'software_type_specific' => nil,
    'software_version' => '8',
    'software_version_full' => '8.0',
    'user_agent' => 'Mozilla/5.0 (iPad; CPU OS 8_4 like Mac OS X) AppleWebKit/600.1.4 (KHTML, like Gecko) Version/8.0 Mobile/12H143 Safari/600.1.4'
  }
```

Default: `'data/common_browsers.csv'` See this file for examples.

## Using the logs

### Searching and filtering

* Because the log is JSON, you can parse it in any language that can parse JSON.
* `script/json_log_find.js` is a noddy node.js script which accepts JSON logs on stdin, and takes command line parameters to find entries matching specified criteria

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

* The default log format is set in `lib/middleware/simple_request_logger.rb` which is an abstract class implementing a Rack middleware that knows nothing of Rails.  It is specified in `spec/middleware/simple_request_logger_spec.rb`
* We subclass it in `lib/middleware/rails/request_logger.rb`: this provides implementations of:
 * `#stream` that tell it where to send the log
 * `#filter_attributes` that adds the local IP address and filters passwords from parameters
* We add `before_filter`s to `ApplicationController` which logs Rails controller name and action name through `Jimmy::Rails::ControllerRuntime` that is included at runtime via `ActiveSupport`
* If you need other data logged in some context, add your own filters that run in that context.

## Using the Ruby logger

You can trigger a logger "manually" by using [Ruby::Logger](https://github.com/simplybusiness/jimmy/blob/master/lib/jimmy/ruby/logger.rb). It uses the same configuration as the middleware logger.

Simple usage example:

```ruby
Jimmy::Ruby:Logger.instance.log({ message: 'Error message' })
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Edit `./lib/jimmy/version.rb` and bump the version
6. Create new Pull Request

## Copyright

Copyright © 2016-2019 Simply Business. See LICENSE for details.
