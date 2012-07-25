require 'collmex/api'
require 'collmex/request'

module Collmex

  class << self
    attr_accessor :customer_id
    attr_accessor :username
    attr_accessor :password
  end

  self.customer_id  = "000000"
  self.username = "000000"
  self.password = "000000"

    def setup_login_data
      config = YAML.load_file('config/collmex_config.yml')["development"]
      Collmex.username    = config["username"]
      Collmex.password    = config["password"]
      Collmex.customer_id = config["customer_id"]
    end

    def reset_login_data
      Collmex.username    = "000000"
      Collmex.password    = "000000"
      Collmex.customer_id = "000000"
    end
end

