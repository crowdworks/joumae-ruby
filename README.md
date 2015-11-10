# Joumae

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/joumae`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'joumae'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install joumae

## Usage

### CLI

The `joumae` command allows you to run arbitrary commands while locking a named resource:

```
$ joumae --resource-name your-app-servers run -- bash -c "\"echo Deployment started.; sleep 10; echo Deployment finished.\""
```

If you consecutively ran the command twice, the latter one fails because the resource is already locked.

The `joumae` command requires two environment variables to be present:

```
export JOUMAE_API_ENDPOINT="https://yourid.execute-api.ap-northeast-1.amazonaws.com/yourstage/"
export JOUMAE_API_KEY="eyJ0eXAiOiJKV1QiLCJhbGc..."
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/joumae. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

