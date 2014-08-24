require "singleton"

module Collmex
  #
  # Represents the configuration as an singleton object
  # for your Collmex environment.
  #
  class Configuration
    include Singleton

    DEFAULTS = {
      user:        ENV["COLLMEX_USER"],
      password:    ENV["COLLMEX_PASSWORD"],
      customer_id: ENV["COLLMEX_CUSTOMER_ID"],
      csv_options: { col_sep: ";" }
    }.freeze

    attr_accessor(*DEFAULTS.keys)

    def initialize
      self.class::DEFAULTS.each do |key, val|
        public_send("#{key}=", val)
      end
    end
  end
end
