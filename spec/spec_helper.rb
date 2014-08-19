require "rspec"
require "awesome_print"
require "vcr"
require "coveralls"
require "pry"

Coveralls.wear!

RSpec.configure do |config|
  config.color = true
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
  config.treat_symbols_as_metadata_keys_with_true_values = true

  config.before do
    Collmex.setup_login_data(
      username:    ENV["COLLMEX_USER"],
      password:    ENV["COLLMEX_PASSWORD"],
      customer_id: ENV["COLLMEX_CUSTOMER_ID"]
    )
  end

  config.after do
    Collmex.reset_login_data
  end
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

require "collmex"
