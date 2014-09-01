require "dotenv"
Dotenv.load

module Collmex
  autoload :Configuration, "collmex/configuration"

  module Api
    autoload :Line,          "collmex/api/line"
    autoload :Login,         "collmex/api/login"
    autoload :Cmxknd,        "collmex/api/cmxknd"
    autoload :Cmxinv,        "collmex/api/cmxinv"
    autoload :Message,       "collmex/api/message"
    autoload :CustomerGet,   "collmex/api/customer_get"
    autoload :AccdocGet,     "collmex/api/accdoc_get"
    autoload :Accdoc,        "collmex/api/accdoc"
    autoload :Cmxord2,       "collmex/api/cmxord2"
    autoload :SalesOrderGet, "collmex/api/sales_order_get"
    autoload :AccbalGet,     "collmex/api/accbal_get"
    autoload :Accbal,        "collmex/api/accbal"
    autoload :NewObjectId,   "collmex/api/new_object_id"
  end

  def self.config
    Configuration.instance
  end

  def self.configure
    yield config
  end
end

require 'collmex/api'
require 'collmex/request'
