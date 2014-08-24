require "simplecov"
SimpleCov.start

require "rspec"
require "awesome_print"
require "vcr"
require "pry"
require "ostruct"
require "collmex"

#Coveralls.wear!

RSpec.configure do |config|
  config.color = true
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
  config.treat_symbols_as_metadata_keys_with_true_values = true
end

def timed(name)
  start = Time.now
  puts "\n[STARTED: #{name}]"
  yield if block_given?
  finish = Time.now
  puts "[FINISHED: #{name} in #{(finish - start) * 1000} milliseconds]"
end

VCR.configure do |c|
  c.allow_http_connections_when_no_cassette = true
  c.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  c.hook_into :webmock
end
