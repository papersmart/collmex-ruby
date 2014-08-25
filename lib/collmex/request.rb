require "net/http"
require "uri"

module Collmex
  class Request
    extend Forwardable

    attr_accessor :commands, :http, :debug, :config
    attr_reader   :response, :raw_response

    def self.run(&block)
      new.tap do |request|
        request.instance_eval(&block) if block_given?
        request.execute
      end
    end

    def self.classify(term)
      term.to_s.split("_").map(&:capitalize).join
    end

    def enqueue(command, args = {})
      if command.is_a? Symbol
        add_command Collmex::Api::const_get(self.class.classify(command)).new(args)
      elsif Collmex::Api.is_a_collmex_api_line_obj?(command)
        add_command command
      else
        return false
      end
    end

    def initialize(config = Collmex.config)
      @commands     = []
      @raw_response = {}
      @config       = config

      if config.user.nil? || config.password.nil? || config.customer_id.nil?
        fail "No credentials for Collmex given."
      else
        add_command Collmex::Api::Login.new(
          username: config.user,
          password: config.password
        )
      end
    end

    def add_command(cmd)
      @commands << cmd
      cmd
    end

    def self.uri(customer_id = Collmex.config.customer_id)
      fail "No customer id given." unless customer_id
      URI.parse("https://www.collmex.de/cgi-bin/cgi.exe\?#{customer_id},0,data_exchange")
    end

    def self.header_attributes
      {"Content-Type" => "text/csv"}
    end

    def payload
      @commands.map { |c| c.to_csv }.join
    end

    def parse_response
      @response = raw_response[:array].map { |l| Collmex::Api.parse_line(l) }
    end

    def execute
      @http = Net::HTTP.new(uri.host, uri.port)
      @http.use_ssl = true
      @http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      # Do not blow up on undefined characters in ISO8859-1
      # http://www.collmex.de/faq.html#zeichensatz_import
      encoded_body = payload.encode("ISO-8859-1", undef: :replace)

      response = @http.request_post(uri.request_uri, encoded_body, header_attributes)
      response.body.force_encoding("ISO-8859-1") if response.body.encoding.to_s == "ASCII-8BIT"

      raw_response[:string] = response.body.encode("UTF-8")

      begin
        raw_response[:array] = CSV.parse(raw_response[:string], Collmex.config.csv_options)
      rescue => e
        STDERR.puts "CSV.parse failed with string: #{raw_response[:string]}" if self.debug
        raise e
      end

      parse_response
    end

    private

    def_delegator "self.class", :uri, :uri
    def_delegator "self.class", :header_attributes, :header_attributes
  end
end
