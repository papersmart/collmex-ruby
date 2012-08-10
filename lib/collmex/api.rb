require "csv"

module Collmex
  module Api

    def self.is_a_collmex_api_line_obj? obj
      obj.class.name =~ /Collmex\:\:Api/
    end
    
    def self.line_class_exists?(class_name)
      klass = Collmex::Api.const_get(class_name)
      return klass.is_a?(Class)
    rescue NameError
      return false
    end

    def self.parse_line(line)
      if line.is_a?(Array) and line.first.is_a?(String)
        identifyer = line.first.split("_").map{ |s| s.downcase.capitalize }.join
        if self.line_class_exists?(identifyer)
          Collmex::Api.const_get(identifyer).new(line)
        else
          raise "Could not find a Collmex::Api::Line class for \"#{identifyer}\""
        end
      elsif line.is_a?(String) && parsed_line = CSV.parse_line(line, Collmex.csv_opts)
        identifyer = parsed_line.first.split("_").map{ |s| s.downcase.capitalize }.join
        if self.line_class_exists?(identifyer)
          Collmex::Api.const_get(identifyer).new(parsed_line)
        else
          raise "Could not find a Collmex::Api::Line class for \"#{identifyer}\""
        end
      else
        raise "Could not parse a Collmex::Api Line from #{line.inspect}"
      end
    end

    def self.parse_field(value, type, opts = nil)
      case type
        when :string    then value.to_s
        when :date      then Date.parse(value.to_s) unless value.nil?
        when :int       then value.to_i unless value.nil?
        when :integer   then value.to_i unless value.nil?
        when :float     then value.to_s.gsub(',','.').to_f unless value.nil?
        when :currency  then Collmex::Api.parse_currency(value) unless value.nil?
      end
    end

    def self.parse_currency(str)
      str = str.to_s
      case str
      when /\A-?\d*[\,|.]\d{0,2}\z/ then (str.gsub(',','.').to_f * 100).to_i
      when /\A-?\d+\z/ then str.to_i
      when /\A-?((\d){1,3})*([\.]\d{3})+([,]\d{2})\z/ then (str.gsub('.','').gsub(',','.').to_f * 100).to_i
      when /\A-?((\d){1,3})*([\,]\d{3})+([.]\d{2})\z/ then (str.gsub(',','').to_f * 100).to_i
      when /\A-?((\d){1,3})*([\.\,]\d{3})+\z/ then str.gsub(',','').gsub('.','').to_i * 100
      else str.to_i
      end
    end

    def self.stringify(data, type)
      case type
      when :integer then (data.nil?)? data.to_s : data.to_i.to_s
      when :string then data.to_s
      when :float then sprintf("%.2f",data).gsub('.',',')
      when :currency then Collmex::Api.stringify_currency(data)
      when :date then data.strftime("%Y%m%d") unless data.nil?
      end
    end
        
    def self.stringify_currency(data)
      case
      when data.is_a?(Integer) then sprintf("%.2f",(data.to_f / 100)).gsub('.',',')
      when data.is_a?(Float) then sprintf("%.2f",(data.to_f)).gsub('.',',')
      when data.is_a?(String) 
        int = self.parse_currency(data) 
        sprintf("%.2f",(int.to_f / 100)).gsub('.',',')
      else data
      end
    end
  end
end


module Collmex
  module Api
    class Line

      def self.specification
        {}
      end

      def self.default_hash
        hash = {}
        self.specification.each_with_index do |field_spec, index| 
          if field_spec.has_key? :fix
            hash[field_spec[:name]] = field_spec[:fix]
          elsif field_spec.has_key? :default
            hash[field_spec[:name]] = field_spec[:default]
          else
            hash[field_spec[:name]] = Collmex::Api.parse_field(nil, field_spec[:type])
          end
        end
        hash
      end

      def self.hashify(data)
        hash = self.default_hash
        fields_spec = self.specification

        if data.is_a? Array
          fields_spec.each_with_index do |field_spec, index| 
            if !data[index].nil? && !field_spec.has_key?(:fix)
              hash[field_spec[:name]] = Collmex::Api.parse_field(data[index], field_spec[:type]) 
            end
          end
        elsif data.is_a? Hash
          fields_spec.each_with_index do |field_spec, index|
            if data.key?(field_spec[:name]) && !field_spec.has_key?(:fix)
              hash[field_spec[:name]] = Collmex::Api.parse_field(data[field_spec[:name]], field_spec[:type]) 
            end
          end
        elsif data.is_a?(String) && parsed = CSV.parse_line(data,Collmex.csv_opts)
          fields_spec.each_with_index do |field_spec, index| 
            if !data[index].nil? && !field_spec.has_key?(:fix)
              hash[field_spec[:name]] = Collmex::Api.parse_field(parsed[index], field_spec[:type]) 
            end
          end
        end
        hash
      end


      def initialize(arg = nil) 
        #puts self.class.name 
        @hash = self.class.default_hash
        @hash = @hash.merge(self.class.hashify(arg)) if !arg.nil?
        if self.class.specification.empty? && self.class.name.to_s != "Collmex::Api::Line"
          raise "#{self.class.name} has no specification"
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
        array = []
        self.class.specification.each do |spec|
          array << Collmex::Api.stringify(@hash[spec[:name]], spec[:type])
        end
        CSV.generate_line(array, Collmex.csv_opts)
      end

      def to_h
        @hash
      end


    end
  end
end


module Collmex
  module Api

    class Login < Line
      def self.specification
        [
            { name: :identifier       , type: :string    , fix: "LOGIN"            },
            { name: :username         , type: :integer                             },
            { name: :password         , type: :integer                             }
        ]
      end
    end

    class AccdocGet < Line # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Buchhaltungsbelege
      def self.specification
        [
            { name: :identifier       , type: :string    , fix: "ACCDOC_GET"      },
            { name: :company_id       , type: :integer   , default: 1             },
            { name: :business_year    , type: :integer                            },
            { name: :id               , type: :integer                            },
            { name: :account_id       , type: :integer                            },
            { name: :cost_unit        , type: :integer                            },
            { name: :customer_id      , type: :integer                            },
            { name: :provider_id      , type: :integer                            },
            { name: :asset_id         , type: :integer                            },
            { name: :invoice_id       , type: :integer                            },
            { name: :journey_id       , type: :integer                            },
            { name: :text             , type: :string                             },
            { name: :date_start       , type: :date                               },
            { name: :date_end         , type: :date                               },
            { name: :cancellation     , type: :integer                            },
            { name: :changed_only     , type: :integer                            },
            { name: :system_name      , type: :string                             },
        ]
      end
    end

    class Accdoc < Line # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Buchhaltungsbelege
      def self.specification
        [
            { name: :identifier        , type: :string    , fix: "ACCDOC"         },
            { name: :company_id        , type: :integer   , default: 1            },
            { name: :business_year     , type: :integer                           },
            { name: :id                , type: :integer                           },
            { name: :date              , type: :date                              },
            { name: :accounted_date    , type: :date                              },
            { name: :test              , type: :string                            },
            { name: :position_id       , type: :integer                           },
            { name: :account_id        , type: :integer                           },
            { name: :account_name      , type: :string                            },
            { name: :should_have       , type: :integer                           },
            { name: :amount            , type: :currency                          },
            { name: :customer_id       , type: :integer                           },
            { name: :customer_name     , type: :string                            },
            { name: :provider_id       , type: :integer                           },
            { name: :provider_name     , type: :string                            },
            { name: :asset_id          , type: :integer                           },
            { name: :asset_name        , type: :string                            },
            { name: :canceled_accdoc   , type: :integer                           },
            { name: :cost_unit         , type: :string                            },
            { name: :invoice_id        , type: :string                            },
            { name: :customer_order_id , type: :integer                           },
            { name: :journey_id        , type: :integer                           },
            { name: :belongs_to_id     , type: :integer                           },
            { name: :belongs_to_year   , type: :integer                           },
            { name: :belongs_to_pos    , type: :integer                           },
        ]
      end
    end

    class InvoicePaymentGet < Line # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Zahlungen
      def self.specification
        [
            { name: :identifier       , type: :string    , fix: "INVOICE_PAYMENT_GET" },
            { name: :company_id       , type: :integer   , default: 1             },
            { name: :id               , type: :string                             },
            { name: :changed_only     , type: :integer                            },
            { name: :system_name      , type: :string                             },
        ]
      end
    end

    class InvoicePayment < Line # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Zahlungen
      def self.specification
        [
            { name: :identifier       , type: :string    , fix: "INVOICE_PAYMENT" },
            { name: :id               , type: :string                             },
            { name: :date             , type: :date                               },
            { name: :amount_paid      , type: :currency                           },
            { name: :amount_reduced   , type: :currency                           },
            { name: :business_year    , type: :integer                            },
            { name: :accdoc_id        , type: :integer                            },
            { name: :accdoc_position  , type: :integer                            },
        ]
      end
    end

    class ProductGet < Line # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Produkte
      def self.specification
        [
            { name: :identifier          , type: :string    , fix: "PRODUCT_GET"  },
            { name: :company_id          , type: :integer   , default: 1          },
            { name: :id                  , type: :string                          },
            { name: :group               , type: :integer                         },
            { name: :price_group         , type: :string                          },
            { name: :changed_only        , type: :integer                         },
            { name: :system_name         , type: :string                          },
            { name: :website_id          , type: :integer                         },
        ]
      end
    end

    class ProductGroupsGet < Line # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Produktgruppen
      def self.specification
        [
            { name: :identifier          , type: :string    , fix: "PRODUCT_GROUPS_GET"  },
        ]
      end
    end

    class StockAvailableGet < Line # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Verfuegbarkeit
      def self.specification
        [
            { name: :identifier       , type: :string    , fix: "STOCK_AVAILABLE_GET" },
            { name: :company_id       , type: :integer   , default: 1             },
            { name: :product_id       , type: :string                             },
            { name: :changed_only     , type: :integer                            },
            { name: :system_name      , type: :string                             },
        ]
      end
    end

    class StockAvailable < Line # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Verfuegbarkeit
      def self.specification
        [
            { name: :identifier         , type: :string    , fix: "STOCK_AVAILABLE" },
            { name: :product_id         , type: :string                             },
            { name: :company_id         , type: :integer   , default: 1             },
            { name: :amount             , type: :integer                            },
            { name: :quantity_unit      , type: :string                             },
            { name: :replenishment_time , type: :integer                            },
        ]
      end
    end

    class CustomerGet < Line # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Kunden
      def self.specification
        [
            { name: :identifier       , type: :string    , fix: "CUSTOMER_GET"    },
            { name: :id               , type: :integer                            },
            { name: :company_id       , type: :integer   , default: 1             },
            { name: :searchtext       , type: :string                             },
            { name: :due_to_review    , type: :integer                            },
            { name: :zip_code         , type: :string                             },
            { name: :address_group    , type: :integer                            },
            { name: :price_group      , type: :integer                            },
            { name: :discount_group   , type: :integer                            },
            { name: :agent            , type: :integer                            },
            { name: :only_changed     , type: :integer                            },
            { name: :system_name      , type: :string                             },
            { name: :inactive         , type: :integer                            },
        ]
      end
    end

    class QuotationGet < Line # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Angebote
      def self.specification
        [
            { name: :identifier       , type: :string    , fix: "QUOTATION_GET"   },
            { name: :id               , type: :integer                            },
            { name: :company_id       , type: :integer   , default: 1             },
            { name: :customer_id      , type: :integer                            },
            { name: :date_start       , type: :date                               },
            { name: :date_end         , type: :date                               },
            { name: :paperless        , type: :integer                            },
            { name: :return_format    , type: :string                             },
            { name: :only_changed     , type: :integer                            },
            { name: :system_name      , type: :string                             },
        ]
      end
    end

    class SalesOrderGet < Line # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Kundenauftraege
      def self.specification
        [
            { name: :identifier       , type: :string    , fix: "SALES_ORDER_GET" },
            { name: :id               , type: :integer                            },
            { name: :company_id       , type: :integer   , default: 1             },
            { name: :customer_id      , type: :integer                            },
            { name: :date_start       , type: :date                               },
            { name: :date_end         , type: :date                               },
            { name: :customer_sales_order_id, type: :string                       },
            { name: :return_format    , type: :string                             },
            { name: :only_changed     , type: :integer                            },
            { name: :system_name      , type: :string                             },
            { name: :system_name_only , type: :integer                            },
            { name: :paperless        , type: :integer                            },
        ]
      end
    end

    class PaymentConfirmation < Line # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Payment
      def self.specification
        [
            { name: :identifier        , type: :string    , fix: "PAYMENT_CONFIRMATION"          },
            { name: :customer_order_id , type: :integer                            },
            { name: :date              , type: :date                               },
            { name: :amount            , type: :currency                           },
            { name: :fee               , type: :currency                           },
            { name: :currency          , type: :string                             },
            { name: :paypal_email      , type: :string                             },
            { name: :paypal_transaction_id , type: :string                         },
        ]
      end
    end

    class InvoiceGet < Line # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Rechnungen
      def self.specification
        [
            { name: :identifier       , type: :string    , fix: "INVOICE_GET"     },
            { name: :id               , type: :string                            },
            { name: :company_id       , type: :integer   , default: 1             },
            { name: :customer_id      , type: :integer                            },
            { name: :date_start       , type: :date                               },
            { name: :date_end         , type: :date                               },
            { name: :sent_only        , type: :integer                            },
            { name: :return_format    , type: :string                             },
            { name: :only_changed     , type: :integer                            },
            { name: :system_name      , type: :string                             },
            { name: :system_name_only , type: :integer                            },
            { name: :paperless        , type: :integer                            },
        ]
      end
    end

    class DeliveryGet < Line # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Lieferungen
      def self.specification
        [
            { name: :identifier       , type: :string    , fix: "DELIVERY_GET"    },
            { name: :id               , type: :string                             },
            { name: :company_id       , type: :integer   , default: 1             },
            { name: :customer_id      , type: :integer                            },
            { name: :date_start       , type: :date                               },
            { name: :date_end         , type: :date                               },
            { name: :sent_only        , type: :integer                            },
            { name: :return_format    , type: :string                             },
            { name: :only_changed     , type: :integer                            },
            { name: :system_name      , type: :string                             },
            { name: :paperless        , type: :integer                            },
            { name: :sales_order_id   , type: :integer                            },
        ]
      end
    end

    class Cmxknd < Line # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_kunde
      def self.specification
          [
            { name: :identifier       , type: :string    , fix: "CMXKND"          },
            { name: :id               , type: :integer                            },
            { name: :company_id       , type: :integer   , default: 1             },
            { name: :salutation       , type: :string                             },
            { name: :title            , type: :string                             },
            { name: :firstname        , type: :string                             },
            { name: :lastname         , type: :string                             },
            { name: :company          , type: :string                             },
            { name: :department       , type: :string                             },
            { name: :street           , type: :string                             },
            { name: :zipcode          , type: :string                             },
            { name: :city             , type: :string                             },
            { name: :annotation       , type: :string                             },
            { name: :inactive         , type: :integer                            },
            { name: :country          , type: :string                             },
            { name: :phone            , type: :string                             },
            { name: :fax              , type: :string                             },
            { name: :email            , type: :string                             },
            { name: :account_id       , type: :string                             },
            { name: :blz              , type: :string                             },
            { name: :iban             , type: :string                             },
            { name: :bic              , type: :string                             },
            { name: :bank_name        , type: :string                             },
            { name: :vat_id           , type: :string                             },
            { name: :payment_condition, type: :integer                            },
            { name: :discount_group   , type: :integer                            },
            { name: :deliver_conditions, type: :string                            },
            { name: :deliver_conditions_additions, type: :string                  },
            { name: :output_media     , type: :integer                            },
            { name: :account_owner    , type: :string                             },
            { name: :address_group    , type: :integer                            },
            { name: :ebay_member      , type: :string                             },
            { name: :price_group      , type: :integer                            },
            { name: :currency         , type: :string                             },
            { name: :agent            , type: :integer                            },
            { name: :cost_unit        , type: :string                             },
            { name: :due_to_review    , type: :date                               },
            { name: :delivery_block   , type: :integer                            },
            { name: :construction_services_provider , type: :integer              },
            { name: :account_id_at_customer, type: :string                        },
            { name: :output_language  , type: :integer                            },
            { name: :email_cc         , type: :string                             },
            { name: :phone_2          , type: :string                             },
          ]
      end
    end

    class Message < Line
      def self.specification
          [
            { name: :identifier       , type: :string    , fix: "MESSAGE"         },
            { name: :type             , type: :string                             },
            { name: :id               , type: :integer                            },
            { name: :text             , type: :string                             },
            { name: :line             , type: :integer                            },
          ]
      end


      def success?
        if @hash.has_key?(:type) && !@hash[:type].empty? && @hash[:type] == "S"
          true
        else
          false
        end
      end

      def result
        if @hash.has_key?(:type) && !@hash[:type].empty?
          case @hash[:type]
          when "S" then :success
          when "W" then :warning
          when "E" then :error
          else :undefined
          end
        else
          :undefined
        end
      end
    end

  end
end
