require "dotenv"
Dotenv.load

module Collmex
  autoload :Configuration, "collmex/configuration"

  def self.config
    Configuration.instance
  end

  def self.configure
    yield config
  end
end

require 'collmex/api'
require 'collmex/request'
