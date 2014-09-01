module Collmex
  module Api
    class Line

      # Holds the specification of the line object
      def self.specification
        fail NotImplementedError, "Missing specification."
      end

      # Return an empty default-hash of the line.
      def self.default_hash
        hash = {}
        specification.each_with_index do |field_spec, index|
          if field_spec.key? :fix
            hash[field_spec[:name]] = field_spec[:fix]
          elsif field_spec.key? :default
            hash[field_spec[:name]] = field_spec[:default]
          else
            hash[field_spec[:name]] = Collmex::Api.parse_field(nil, field_spec[:type])
          end
        end
        hash
      end

      # returns a hash of the line that inherits from the default_hash but gets
      # filled with its contents.
      def self.hashify(data)
        hash = default_hash

        if data.is_a?(Array) || data.is_a?(String) && data = CSV.parse_line(data, Collmex.config.csv_options)
          specification.each_with_index do |field_spec, index|
            if !data[index].nil? && !field_spec.key?(:fix)
              hash[field_spec[:name]] = Collmex::Api.parse_field(data[index], field_spec[:type])
            end
          end
        elsif data.is_a? Hash
          specification.each_with_index do |field_spec, index|
            if data.key?(field_spec[:name]) && !field_spec.key?(:fix)
              hash[field_spec[:name]] = Collmex::Api.parse_field(data[field_spec[:name]], field_spec[:type])
            end
          end
        end
        hash
      end

      def initialize(arg = nil)
        @hash = self.class.default_hash
        @hash = @hash.merge(self.class.hashify(arg)) if !arg.nil?
        if self.class.specification.empty? && self.class.name.to_s != "Collmex::Api::Line"
          fail "#{self.class.name} has no specification"
        end
      end

      def to_a
        array = []
        self.class.specification.each do |spec|
          array << @hash[spec[:name]]
        end
        array
      end

      def to_stringified_array
        array = []
        self.class.specification.each do |spec|
          array << Collmex::Api.stringify(@hash[spec[:name]], spec[:type])
        end
        array
      end

      def to_csv
        CSV.generate_line(to_stringified_array, Collmex.config.csv_options)
      end

      def to_h
        @hash
      end

      def message
        to_h[:text]
      end
    end
  end
end
