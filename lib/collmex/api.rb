require "csv"

module Collmex
  module Api
    # Check if a given object is a Collmex::Api object
    def self.is_a_collmex_api_line_obj?(obj)
      !!obj.class.name.index("Collmex::Api")
    end

    # Check if a Line class exists for the given class name
    def self.line_class_exists?(class_name)
      klass = Collmex::Api.const_get(class_name)
      return klass.is_a?(Class)
    rescue NameError
      return false
    end

    def self.parse_line(line)
      if line.is_a?(Array) and line.first.is_a?(String)
        identifier = line.first.split("_").map{ |s| s.downcase.capitalize }.join
        if self.line_class_exists?(identifier)
          Collmex::Api.const_get(identifier).new(line)
        else
          fail "Could not find a Collmex::Api::Line class for \"#{identifier}\""
        end
      elsif line.is_a?(String) && parsed_line = CSV.parse_line(line, Collmex.config.csv_options)
        identifier = parsed_line.first.split("_").map{ |s| s.downcase.capitalize }.join
        if self.line_class_exists?(identifier)
          Collmex::Api.const_get(identifier).new(parsed_line)
        else
          fail "Could not find a Collmex::Api::Line class for \"#{identifier}\""
        end
      else
        fail "Could not find a Collmex::Api::Line class for \"#{identifier}\" (\"#{line.first}\")"
      end
    end

    # Given a field's content, we parse it here and return
    # a typecasted object
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

    # Given a string we want to handle as currency, we parse it to get
    # the Euro-cents as integer.
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

    # given an object, convert it to a string according to the collmex api.
    def self.stringify(data, type)
      return "" if data.nil?
      case type
      when :integer  then data.to_i.to_s
      when :string   then data
      when :float    then sprintf("%.2f", data).gsub('.', ',')
      when :currency then stringify_currency(data)
      when :date     then data.strftime("%Y%m%d")
      end
    end

    # given an object we want to treat as currency, convert it to a string
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
        elsif data.is_a?(String) && parsed = CSV.parse_line(data, Collmex.config.csv_options)
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
        array = []
        self.class.specification.each do |spec|
          array << Collmex::Api.stringify(@hash[spec[:name]], spec[:type])
        end
        CSV.generate_line(array, Collmex.config.csv_options)
      end

      def to_h
        @hash
      end

      # given an object we want to treat as currency, convert it to a string
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
end

require "collmex/api/line"
require "collmex/api/login"
require "collmex/api/cmxknd"
require "collmex/api/message"
require "collmex/api/customer_get"
require "collmex/api/accdoc_get"
require "collmex/api/accdoc"
require "collmex/api/cmxord2"
require "collmex/api/sales_order_get"
require "collmex/api/accbal_get"
require "collmex/api/accbal"

module Collmex
  module Api
    # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_adressgruppen
    class Adrgrp < Line
      def self.specification
        [
          { name: :identifier  , type: :string  , fix: "ADRGRP" },
          { name: :id          , type: :integer                 },
          { name: :description , type: :string                  }
        ]
      end
    end

    # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Periodische_rechnung
    class AboGet < Line
      def self.specification
        [
          { name: :identifier         , type: :string  , fix: "ABO_GET" },
          { name: :customer_id        , type: :integer                  },
          { name: :company_id         , type: :integer , default: 1     },
          { name: :product_id         , type: :string                   },
          { name: :next_invoice_from  , type: :date                     },
          { name: :next_invoice_to    , type: :date                     },
          { name: :only_valid         , type: :integer                  },
          { name: :only_changed       , type: :integer                  },
          { name: :system_name        , type: :string                   }
        ]
      end
    end

    class Accdoc < Line # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Buchhaltungsbelege
      def self.specification
        [
          { name: :identifier        , type: :string  , fix: "ACCDOC" },
          { name: :company_id        , type: :integer , default: 1    },
          { name: :business_year     , type: :integer                 },
          { name: :id                , type: :integer                 },
          { name: :date              , type: :date                    },
          { name: :accounted_date    , type: :date                    },
          { name: :test              , type: :string                  },
          { name: :position_id       , type: :integer                 },
          { name: :account_id        , type: :integer                 },
          { name: :account_name      , type: :string                  },
          { name: :should_have       , type: :integer                 },
          { name: :amount            , type: :currency                },
          { name: :customer_id       , type: :integer                 },
          { name: :customer_name     , type: :string                  },
          { name: :provider_id       , type: :integer                 },
          { name: :provider_name     , type: :string                  },
          { name: :asset_id          , type: :integer                 },
          { name: :asset_name        , type: :string                  },
          { name: :canceled_accdoc   , type: :integer                 },
          { name: :cost_center       , type: :string                  },
          { name: :invoice_id        , type: :string                  },
          { name: :customer_order_id , type: :integer                 },
          { name: :journey_id        , type: :integer                 },
          { name: :belongs_to_id     , type: :integer                 },
          { name: :belongs_to_year   , type: :integer                 },
          { name: :belongs_to_pos    , type: :integer                 }
        ]
      end
    end

    # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Buchhaltungsbelege
    class AccdocGet < Line
      def self.specification
        [
          { name: :identifier    , type: :string  , fix: "ACCDOC_GET" },
          { name: :company_id    , type: :integer , default: 1        },
          { name: :business_year , type: :integer                     },
          { name: :id            , type: :integer                     },
          { name: :account_id    , type: :integer                     },
          { name: :cost_unit     , type: :integer                     },
          { name: :customer_id   , type: :integer                     },
          { name: :provider_id   , type: :integer                     },
          { name: :asset_id      , type: :integer                     },
          { name: :invoice_id    , type: :integer                     },
          { name: :journey_id    , type: :integer                     },
          { name: :text          , type: :string                      },
          { name: :date_start    , type: :date                        },
          { name: :date_end      , type: :date                        },
          { name: :cancellation  , type: :integer                     },
          { name: :changed_only  , type: :integer                     },
          { name: :system_name   , type: :string                      }
        ]
      end
    end

    # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Adressen
    class AddressGet < Line
      def self.specification
        [
          { name: :identifier       , type: :string  , fix: "ADDRESS_GET" },
          { name: :id               , type: :integer                      },
          { name: :type             , type: :integer                      },
          { name: :text             , type: :string                       },
          { name: :due_to_review    , type: :integer                      },
          { name: :zipcode          , type: :string                       },
          { name: :address_group_id , type: :integer                      },
          { name: :changed_only     , type: :integer                      },
          { name: :system_name      , type: :string                       },
          { name: :contact_id       , type: :integer                      }
        ]
      end
    end

    # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Adressgruppen
    class AddressGroupsGet < Line
      def self.specification
        [
          { name: :identifier , type: :string , fix: "ADDRESS_GROUPS_GET" }
        ]
      end
    end

    # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_periodische_rechnung
    class Cmxabo < Line
      def self.specification
        [
          { name: :identifier          , type: :string  , fix: "ABO_GET" },
          { name: :customer_id         , type: :integer                  },
          { name: :company_id          , type: :integer , default: 1     },
          { name: :valid_from          , type: :date                     },
          { name: :valid_to            , type: :date                     },
          { name: :product_id          , type: :string                   },
          { name: :product_description , type: :string                   },
          { name: :customized_price    , type: :currency                 },
          { name: :interval            , type: :integer                  },
          { name: :next_invoice        , type: :date                     }
        ]
      end
    end

    # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_adressen
    class Cmxadr < Line
      def self.specification
        [
          { name: :identifier          , type: :string  , fix: "CMXADR" },
          { name: :id                  , type: :integer                 },
          { name: :type                , type: :integer                 },
          { name: :salutation          , type: :string                  },
          { name: :title               , type: :string                  },
          { name: :firstname           , type: :string                  },
          { name: :lastname            , type: :string                  },
          { name: :company             , type: :string                  },
          { name: :department          , type: :string                  },
          { name: :street              , type: :string                  },
          { name: :zipcode             , type: :string                  },
          { name: :city                , type: :string                  },
          { name: :annotation          , type: :string                  },
          { name: :inactive            , type: :integer                 },
          { name: :country             , type: :string                  },
          { name: :phone               , type: :string                  },
          { name: :fax                 , type: :string                  },
          { name: :email               , type: :string                  },
          { name: :account_number      , type: :string                  },
          { name: :bank_account_number , type: :string                  },
          { name: :iban                , type: :string                  },
          { name: :bic                 , type: :string                  },
          { name: :bank_name           , type: :string                  },
          { name: :tax_id              , type: :string                  },
          { name: :vat_id              , type: :string                  },
          { name: :reserved            , type: :string                  },
          { name: :phone_2             , type: :string                  },
          { name: :skype_voip          , type: :string                  },
          { name: :url                 , type: :string                  },
          { name: :account_owner       , type: :string                  },
          { name: :review_at           , type: :date                    },
          { name: :address_group_id    , type: :integer                 },
          { name: :agent_id            , type: :integer                 },
          { name: :company_id          , type: :integer , default: 1    }
        ]
      end
    end

    # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_anspr
    class Cmxasp < Line
      def self.specification
        [
          { name: :identifier       , type: :string  , fix: "CMXASP" },
          { name: :id               , type: :integer                 },
          { name: :type             , type: :integer                 },
          { name: :salutation       , type: :string                  },
          { name: :title            , type: :string                  },
          { name: :firstname        , type: :string                  },
          { name: :lastname         , type: :string                  },
          { name: :company          , type: :string                  },
          { name: :department       , type: :string                  },
          { name: :street           , type: :string                  },
          { name: :zipcode          , type: :string                  },
          { name: :city             , type: :string                  },
          { name: :country          , type: :string                  },
          { name: :phone            , type: :string                  },
          { name: :phone_2          , type: :string                  },
          { name: :fax              , type: :string                  },
          { name: :skype_voip       , type: :string                  },
          { name: :email            , type: :string                  },
          { name: :annotation       , type: :string                  },
          { name: :url              , type: :string                  },
          { name: :no_mailings      , type: :integer                 },
          { name: :address_group_id , type: :integer                 }
        ]
      end
    end

    # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_abw
    class Cmxepf < Line
      def self.specification
        [
          { name: :identifier       , type: :string  , fix: "CMXEPF" },
          { name: :customer_id      , type: :integer                 },
          { name: :company_id       , type: :integer , default: 1    },
          { name: :document_type    , type: :integer                 },
          { name: :output_media     , type: :integer                 },
          { name: :salutation       , type: :string                  },
          { name: :title            , type: :string                  },
          { name: :firstname        , type: :string                  },
          { name: :lastname         , type: :string                  },
          { name: :company          , type: :string                  },
          { name: :department       , type: :string                  },
          { name: :street           , type: :string                  },
          { name: :zipcode          , type: :string                  },
          { name: :city             , type: :string                  },
          { name: :country          , type: :string                  },
          { name: :phone            , type: :string                  },
          { name: :phone_2          , type: :string                  },
          { name: :fax              , type: :string                  },
          { name: :skype_voip       , type: :string                  },
          { name: :email            , type: :string                  },
          { name: :annotation       , type: :string                  },
          { name: :url              , type: :string                  },
          { name: :no_mailings      , type: :integer                 },
          { name: :address_group_id , type: :integer                 }
        ]
      end
    end

    # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_rechnungen
    class Cmxinv < Line
      def self.specification
        [
          { name: :identifier                         , type: :string  , fix: "CMXINV" },
          { name: :id                                 , type: :integer                 },
          { name: :position_id                        , type: :integer                 },
          { name: :type                               , type: :integer                 },
          { name: :company_id                         , type: :integer , default: 1    },
          { name: :customer_order_id                  , type: :integer                 },
          { name: :customer_id                        , type: :integer                 },
          { name: :customer_salutation                , type: :string                  },
          { name: :customer_title                     , type: :string                  },
          { name: :customer_firstname                 , type: :string                  },
          { name: :customer_lastname                  , type: :string                  },
          { name: :customer_company                   , type: :string                  },
          { name: :customer_department                , type: :string                  },
          { name: :customer_street                    , type: :string                  },
          { name: :customer_zipcode                   , type: :string                  },
          { name: :customer_city                      , type: :string                  },
          { name: :customer_country                   , type: :string                  },
          { name: :customer_phone                     , type: :string                  },
          { name: :customer_phone_2                   , type: :string                  },
          { name: :customer_fax                       , type: :string                  },
          { name: :customer_email                     , type: :string                  },
          { name: :customer_account_number            , type: :string                  },
          { name: :customer_bank_account_number       , type: :string                  },
          { name: :customer_alternative_account_owner , type: :string                  },
          { name: :customer_iban                      , type: :string                  },
          { name: :customer_bic                       , type: :string                  },
          { name: :customer_bank_name                 , type: :string                  },
          { name: :customer_vat_id                    , type: :string                  },
          { name: :reserved                           , type: :integer                 },
          { name: :date                               , type: :date                    },
          { name: :price_date                         , type: :date                    },
          { name: :terms_of_payment                   , type: :integer                 },
          { name: :currency                           , type: :string                  },
          { name: :price_group_id                     , type: :integer                 },
          { name: :discount_group_id                  , type: :integer                 },
          { name: :discount_final                     , type: :integer                 },
          { name: :discount_reason                    , type: :string                  },
          { name: :text                               , type: :string                  },
          { name: :text_conclusion                    , type: :string                  },
          { name: :internal_memo                      , type: :string                  },
          { name: :deleted                            , type: :integer                 },
          { name: :language                           , type: :integer                 },
          { name: :operator_id                        , type: :integer                 },
          { name: :agent_id                           , type: :integer                 },
          { name: :system_name                        , type: :string                  },
          { name: :status                             , type: :integer                 },
          { name: :discount_final_2                   , type: :currency                },
          { name: :discount_reason_2                  , type: :string                  },
          { name: :delivery_type                      , type: :integer                 },
          { name: :delivery_costs                     , type: :currency                },
          { name: :cod_fee                            , type: :currency                },
          { name: :supply_and_service_date            , type: :date                    },
          { name: :delivery_terms                     , type: :string                  },
          { name: :delivery_terms_additions           , type: :string                  },
          { name: :delivery_address_salutation        , type: :string                  },
          { name: :delivery_address_title             , type: :string                  },
          { name: :delivery_address_firstname         , type: :string                  },
          { name: :delivery_address_lastname          , type: :string                  },
          { name: :delivery_address_company           , type: :string                  },
          { name: :delivery_address_department        , type: :string                  },
          { name: :delivery_address_street            , type: :string                  },
          { name: :delivery_address_zipcode           , type: :string                  },
          { name: :delivery_address_city              , type: :string                  },
          { name: :delivery_address_country           , type: :string                  },
          { name: :delivery_address_phone             , type: :string                  },
          { name: :delivery_address_phone_2           , type: :string                  },
          { name: :delivery_address_fax               , type: :string                  },
          { name: :delivery_address_email             , type: :string                  },
          { name: :item_category                      , type: :integer                 },
          { name: :product_id                         , type: :string                  },
          { name: :product_description                , type: :string                  },
          { name: :quantity_unit                      , type: :string                  },
          { name: :order_quantity                     , type: :float                   },
          { name: :product_price                      , type: :currency                },
          { name: :amount_price                       , type: :float                   },
          { name: :position_discount                  , type: :currency                },
          { name: :position_value                     , type: :currency                },
          { name: :product_type                       , type: :integer                 },
          { name: :tax_classification                 , type: :integer                 },
          { name: :tax_abroad                         , type: :integer                 },
          { name: :customer_order_position            , type: :integer                 },
          { name: :revenue_element                    , type: :integer                 }
        ]
      end
    end

    # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_kunde
    class Cmxknd < Line
      def self.specification
        [
          { name: :identifier                     , type: :string  , fix: "CMXKND" },
          { name: :id                             , type: :integer                 },
          { name: :company_id                     , type: :integer , default: 1    },
          { name: :salutation                     , type: :string                  },
          { name: :title                          , type: :string                  },
          { name: :firstname                      , type: :string                  },
          { name: :lastname                       , type: :string                  },
          { name: :company                        , type: :string                  },
          { name: :department                     , type: :string                  },
          { name: :street                         , type: :string                  },
          { name: :zipcode                        , type: :string                  },
          { name: :city                           , type: :string                  },
          { name: :annotation                     , type: :string                  },
          { name: :inactive                       , type: :integer                 },
          { name: :country                        , type: :string                  },
          { name: :phone                          , type: :string                  },
          { name: :fax                            , type: :string                  },
          { name: :email                          , type: :string                  },
          { name: :account_number                 , type: :string                  },
          { name: :bank_account_number            , type: :string                  },
          { name: :iban                           , type: :string                  },
          { name: :bic                            , type: :string                  },
          { name: :bank_name                      , type: :string                  },
          { name: :tax_id                         , type: :string                  },
          { name: :vat_id                         , type: :string                  },
          { name: :payment_condition              , type: :integer                 },
          { name: :discount_group_id              , type: :integer                 },
          { name: :delivery_terms                 , type: :string                  },
          { name: :delivery_terms_additions       , type: :string                  },
          { name: :output_media                   , type: :integer                 },
          { name: :account_owner                  , type: :string                  },
          { name: :address_group_id               , type: :integer                 },
          { name: :ebay_member                    , type: :string                  },
          { name: :price_group_id                 , type: :integer                 },
          { name: :currency                       , type: :string                  },
          { name: :agent_id                       , type: :integer                 },
          { name: :cost_unit                      , type: :string                  },
          { name: :due_to_review                  , type: :date                    },
          { name: :delivery_block                 , type: :integer                 },
          { name: :construction_services_provider , type: :integer                 },
          { name: :delivery_id_at_customer        , type: :string                  },
          { name: :output_language                , type: :integer                 },
          { name: :email_cc                       , type: :string                  },
          { name: :phone_2                        , type: :string                  }
        ]
      end
    end

    class Cmxlif < Line # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_lieferant
      def self.specification
        [
          { name: :identifier               , type: :string  , fix: "CMXLIF" },
          { name: :id                       , type: :integer                 },
          { name: :company_id               , type: :integer , default: 1    },
          { name: :salutation               , type: :string                  },
          { name: :title                    , type: :string                  },
          { name: :firstname                , type: :string                  },
          { name: :lastname                 , type: :string                  },
          { name: :company                  , type: :string                  },
          { name: :department               , type: :string                  },
          { name: :street                   , type: :string                  },
          { name: :zipcode                  , type: :string                  },
          { name: :city                     , type: :string                  },
          { name: :annotation               , type: :string                  },
          { name: :inactive                 , type: :integer                 },
          { name: :country                  , type: :string                  },
          { name: :phone                    , type: :string                  },
          { name: :fax                      , type: :string                  },
          { name: :email                    , type: :string                  },
          { name: :account_number           , type: :string                  },
          { name: :bank_account_number      , type: :string                  },
          { name: :iban                     , type: :string                  },
          { name: :bic                      , type: :string                  },
          { name: :bank_name                , type: :string                  },
          { name: :tax_id                   , type: :string                  },
          { name: :vat_id                   , type: :string                  },
          { name: :payment_condition        , type: :integer                 },
          { name: :delivery_terms           , type: :string                  },
          { name: :delivery_terms_additions , type: :string                  },
          { name: :output_media             , type: :integer                 },
          { name: :account_owner            , type: :string                  },
          { name: :address_group_id         , type: :integer                 },
          { name: :customer_id_at_supplier  , type: :string                  },
          { name: :currency                 , type: :string                  },
          { name: :phone_2                  , type: :string                  },
          { name: :output_language          , type: :integer                 }
        ]
      end
    end

    # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_preise
    class Cmxpri < Line
      def self.specification
        [
          { name: :identifier     , type: :string  , fix: "CMXPRI" },
          { name: :product_id     , type: :string                  },
          { name: :company_id     , type: :integer , default: 1    },
          { name: :price_group_id , type: :integer                 },
          { name: :valid_from     , type: :date                    },
          { name: :valid_to       , type: :date                    },
          { name: :product_price  , type: :currency                }
        ]
      end
    end

    # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_angebote
    class Cmxqtn < Line
      def self.specification
        [
          { name: :identifier                         , type: :string  , fix: "CMXQTN" },
          { name: :id                                 , type: :integer                 },
          { name: :position_id                        , type: :integer                 },
          { name: :type                               , type: :integer                 },
          { name: :company_id                         , type: :integer , default: 1    },
          { name: :customer_id                        , type: :integer                 },
          { name: :customer_salutation                , type: :string                  },
          { name: :customer_title                     , type: :string                  },
          { name: :customer_firstname                 , type: :string                  },
          { name: :customer_lastname                  , type: :string                  },
          { name: :customer_company                   , type: :string                  },
          { name: :customer_department                , type: :string                  },
          { name: :customer_street                    , type: :string                  },
          { name: :customer_zipcode                   , type: :string                  },
          { name: :customer_city                      , type: :string                  },
          { name: :customer_country                   , type: :string                  },
          { name: :customer_phone                     , type: :string                  },
          { name: :customer_phone_2                   , type: :string                  },
          { name: :customer_fax                       , type: :string                  },
          { name: :customer_email                     , type: :string                  },
          { name: :customer_account_number            , type: :string                  },
          { name: :customer_bank_account_number       , type: :string                  },
          { name: :customer_alternative_account_owner , type: :string                  },
          { name: :customer_iban                      , type: :string                  },
          { name: :customer_bic                       , type: :string                  },
          { name: :customer_bank_name                 , type: :string                  },
          { name: :customer_vat_id                    , type: :string                  },
          { name: :reserved_1                         , type: :integer                 },
          { name: :date                               , type: :date                    },
          { name: :price_date                         , type: :date                    },
          { name: :terms_of_payment                   , type: :integer                 },
          { name: :currency                           , type: :string                  },
          { name: :price_group_id                     , type: :integer                 },
          { name: :discount_group_id                  , type: :integer                 },
          { name: :discount_final                     , type: :integer                 },
          { name: :discount_reason                    , type: :string                  },
          { name: :text                               , type: :string                  },
          { name: :text_conclusion                    , type: :string                  },
          { name: :internal_memo                      , type: :string                  },
          { name: :deleted                            , type: :integer                 },
          { name: :rejected_at                        , type: :date                    },
          { name: :language                           , type: :integer                 },
          { name: :operator_id                        , type: :integer                 },
          { name: :agent_id                           , type: :integer                 },
          { name: :discount_final_2                   , type: :currency                },
          { name: :discount_reason_2                  , type: :string                  },
          { name: :reserved_2                         , type: :string                  },
          { name: :reserved_3                         , type: :string                  },
          { name: :delivery_type                      , type: :integer                 },
          { name: :delivery_costs                     , type: :currency                },
          { name: :cod_fee                            , type: :currency                },
          { name: :supply_and_service_date            , type: :date                    },
          { name: :delivery_terms                     , type: :string                  },
          { name: :delivery_terms_additions           , type: :string                  },
          { name: :delivery_address_salutation        , type: :string                  },
          { name: :delivery_address_title             , type: :string                  },
          { name: :delivery_address_firstname         , type: :string                  },
          { name: :delivery_address_lastname          , type: :string                  },
          { name: :delivery_address_company           , type: :string                  },
          { name: :delivery_address_department        , type: :string                  },
          { name: :delivery_address_street            , type: :string                  },
          { name: :delivery_address_zipcode           , type: :string                  },
          { name: :delivery_address_city              , type: :string                  },
          { name: :delivery_address_country           , type: :string                  },
          { name: :delivery_address_phone             , type: :string                  },
          { name: :delivery_address_phone_2           , type: :string                  },
          { name: :delivery_address_fax               , type: :string                  },
          { name: :delivery_address_email             , type: :string                  },
          { name: :item_category                      , type: :integer                 },
          { name: :product_id                         , type: :string                  },
          { name: :product_description                , type: :string                  },
          { name: :quantity_unit                      , type: :string                  },
          { name: :order_quantity                     , type: :float                   },
          { name: :product_price                      , type: :currency                },
          { name: :amount_price                       , type: :float                   },
          { name: :position_discount                  , type: :currency                },
          { name: :position_value                     , type: :currency                },
          { name: :product_type                       , type: :integer                 },
          { name: :tax_classification                 , type: :integer                 },
          { name: :tax_abroad                         , type: :integer                 },
          { name: :revenue_element                    , type: :integer                 }
        ]
      end
    end

    # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_umsaetze
    class Cmxums < Line
      def self.specification
        [
          { name: :identifier                , type: :string   , fix: "CMXUMS" },
          { name: :customer_id               , type: :integer                  },
          { name: :company_id                , type: :integer  , default: 1    },
          { name: :invoice_date              , type: :date                     },
          { name: :invoice_id                , type: :string                   },
          { name: :net_amount_full_vat       , type: :currency                 },
          { name: :tax_value_full_vat        , type: :currency                 },
          { name: :net_amount_reduced_vat    , type: :currency                 },
          { name: :tax_value_reduced_vat     , type: :currency                 },
          { name: :intra_community_delivery  , type: :currency                 },
          { name: :export                    , type: :currency                 },
          { name: :account_id_no_vat         , type: :integer                  },
          { name: :net_amount_no_vat         , type: :currency                 },
          { name: :currency                  , type: :string                   },
          { name: :contra_account            , type: :integer                  },
          { name: :invoice_type              , type: :integer                  },
          { name: :text                      , type: :string                   },
          { name: :terms_of_payment          , type: :integer                  },
          { name: :account_id_full_vat       , type: :integer                  },
          { name: :account_id_reduced_vat    , type: :integer                  },
          { name: :reserved_1                , type: :integer                  },
          { name: :reserved_2                , type: :integer                  },
          { name: :cancellation              , type: :integer                  },
          { name: :final_invoice             , type: :string                   },
          { name: :type                      , type: :integer                  },
          { name: :system_name               , type: :string                   },
          { name: :offset_against_invoice_id , type: :string                   },
          { name: :cost_unit                 , type: :string                   }
        ]
      end
    end

    # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Kunden
    class CustomerGet < Line
      def self.specification
        [
          { name: :identifier        , type: :string  , fix: "CUSTOMER_GET" },
          { name: :id                , type: :integer                       },
          { name: :company_id        , type: :integer , default: 1          },
          { name: :text              , type: :string                        },
          { name: :due_to_review     , type: :integer                       },
          { name: :zip_code          , type: :string                        },
          { name: :address_group_id  , type: :integer                       },
          { name: :price_group_id    , type: :integer                       },
          { name: :discount_group_id , type: :integer                       },
          { name: :agent_id          , type: :integer                       },
          { name: :only_changed      , type: :integer                       },
          { name: :system_name       , type: :string                        },
          { name: :inactive          , type: :integer                       }
        ]
      end
    end

    # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Lieferungen
    class DeliveryGet < Line
      def self.specification
        [
          { name: :identifier        , type: :string  , fix: "DELIVERY_GET" },
          { name: :id                , type: :string                        },
          { name: :company_id        , type: :integer , default: 1          },
          { name: :customer_id       , type: :integer                       },
          { name: :date_start        , type: :date                          },
          { name: :date_end          , type: :date                          },
          { name: :sent_only         , type: :integer                       },
          { name: :return_format     , type: :string                        },
          { name: :only_changed      , type: :integer                       },
          { name: :system_name       , type: :string                        },
          { name: :paperless         , type: :integer                       },
          { name: :customer_order_id , type: :integer                       }
        ]
      end
    end

    # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Rechnungen
    class InvoiceGet < Line
      def self.specification
        [
          { name: :identifier       , type: :string  , fix: "INVOICE_GET" },
          { name: :id               , type: :string                       },
          { name: :company_id       , type: :integer , default: 1         },
          { name: :customer_id      , type: :integer                      },
          { name: :date_start       , type: :date                         },
          { name: :date_end         , type: :date                         },
          { name: :sent_only        , type: :integer                      },
          { name: :return_format    , type: :string                       },
          { name: :only_changed     , type: :integer                      },
          { name: :system_name      , type: :string                       },
          { name: :system_name_only , type: :integer                      },
          { name: :paperless        , type: :integer                      }
        ]
      end
    end

    # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Zahlungen
    class InvoicePayment < Line
      def self.specification
        [
          { name: :identifier      , type: :string   , fix: "INVOICE_PAYMENT" },
          { name: :id              , type: :string                            },
          { name: :date            , type: :date                              },
          { name: :amount_paid     , type: :currency                          },
          { name: :amount_reduced  , type: :currency                          },
          { name: :business_year   , type: :integer                           },
          { name: :accdoc_id       , type: :integer                           },
          { name: :accdoc_position , type: :integer                           }
        ]
      end
    end

    # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Zahlungen
    class InvoicePaymentGet < Line
      def self.specification
        [
          { name: :identifier   , type: :string  , fix: "INVOICE_PAYMENT_GET" },
          { name: :company_id   , type: :integer , default: 1                 },
          { name: :id           , type: :string                               },
          { name: :changed_only , type: :integer                              },
          { name: :system_name  , type: :string                               }
        ]
      end
    end

    # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Authentifizierung
    class Login < Line
      def self.specification
        [
          { name: :identifier , type: :string  , fix: "LOGIN" },
          { name: :username   , type: :integer                },
          { name: :password   , type: :integer                }
        ]
      end
    end

    # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Rueckmeldungen
    class Message < Line
      def self.specification
        [
          { name: :identifier , type: :string  , fix: "MESSAGE" },
          { name: :type       , type: :string                   },
          { name: :id         , type: :integer                  },
          { name: :text       , type: :string                   },
          { name: :line       , type: :integer                  }
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

    # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Payment
    class PaymentConfirmation < Line
      def self.specification
        [
          { name: :identifier            , type: :string   , fix: "PAYMENT_CONFIRMATION" },
          { name: :customer_order_id     , type: :integer                                },
          { name: :date                  , type: :date                                   },
          { name: :amount                , type: :currency                               },
          { name: :fee                   , type: :currency                               },
          { name: :currency              , type: :string                                 },
          { name: :paypal_email          , type: :string                                 },
          { name: :paypal_transaction_id , type: :string                                 }
        ]
      end
    end

    # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_produktgruppen
    class Prdgrp < Line
      def self.specification
        [
          { name: :identifier               , type: :string  , fix: "PRDGRP" },
          { name: :id                       , type: :integer                 },
          { name: :description              , type: :string                  },
          { name: :generic_product_group_id , type: :integer                 }
        ]
      end
    end

    # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Produkte
    class ProductGet < Line
      def self.specification
        [
          { name: :identifier      , type: :string  , fix: "PRODUCT_GET" },
          { name: :company_id      , type: :integer , default: 1         },
          { name: :id              , type: :string                       },
          { name: :group           , type: :integer                      },
          { name: :price_group_id  , type: :string                       },
          { name: :changed_only    , type: :integer                      },
          { name: :system_name     , type: :string                       },
          { name: :website_id      , type: :integer                      }
        ]
      end
    end

    # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Produktgruppen
    class ProductGroupsGet < Line
      def self.specification
        [
          { name: :identifier , type: :string , fix: "PRODUCT_GROUPS_GET" }
        ]
      end
    end

    # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Projekte
    class ProjectGet < Line
      def self.specification
        [
          { name: :identifier  , type: :string  , fix: "PROJECT_GET " },
          { name: :id          , type: :integer                       },
          { name: :company_id  , type: :integer , default: 1          },
          { name: :customer_id , type: :integer                       }
        ]
      end
    end

    # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Lieferantenauftraege
    class PurchaseOrderGet < Line
      def self.specification
        [
          { name: :identifier    , type: :string  , fix: "PURCHASE_ORDER_GET" },
          { name: :id            , type: :string                              },
          { name: :company_id    , type: :integer , default: 1                },
          { name: :supplier_id   , type: :integer                             },
          { name: :product_id    , type: :string                              },
          { name: :sent_only     , type: :integer                             },
          { name: :return_format , type: :string                              },
          { name: :only_changed  , type: :integer                             },
          { name: :system_name   , type: :string                              },
          { name: :paperless     , type: :integer                             }
        ]
      end
    end

    # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Angebote
    class QuotationGet < Line
      def self.specification
        [
          { name: :identifier    , type: :string  , fix: "QUOTATION_GET" },
          { name: :id            , type: :string                         },
          { name: :company_id    , type: :integer , default: 1           },
          { name: :customer_id   , type: :integer                        },
          { name: :date_start    , type: :date                           },
          { name: :date_end      , type: :date                           },
          { name: :paperless     , type: :integer                        },
          { name: :return_format , type: :string                         },
          { name: :only_changed  , type: :integer                        },
          { name: :system_name   , type: :string                         }
        ]
      end
    end

    # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Kundenauftraege
    class SalesOrderGet < Line
      def self.specification
        [
          { name: :identifier       , type: :string  , fix: "SALES_ORDER_GET" },
          { name: :id               , type: :string                           },
          { name: :company_id       , type: :integer , default: 1             },
          { name: :customer_id      , type: :integer                          },
          { name: :date_start       , type: :date                             },
          { name: :date_end         , type: :date                             },
          { name: :id_at_customer   , type: :string                           },
          { name: :return_format    , type: :string                           },
          { name: :only_changed     , type: :integer                          },
          { name: :system_name      , type: :string                           },
          { name: :system_name_only , type: :integer                          },
          { name: :paperless        , type: :integer                          }
        ]
      end
    end

    # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Suchmaschinen
    class SearchEngineProductsGet < Line
      def self.specification
        [
          { name: :identifier    , type: :string  , fix: "SEARCH_ENGINE_PRODUCTS_GET" },
          { name: :website_id    , type: :integer                                     },
          { name: :return_format , type: :integer                                     }
        ]
      end
    end

    # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Verfuegbarkeit
    class StockAvailable < Line
      def self.specification
        [
          { name: :identifier         , type: :string  , fix: "STOCK_AVAILABLE" },
          { name: :product_id         , type: :string                           },
          { name: :company_id         , type: :integer , default: 1             },
          { name: :amount             , type: :integer                          },
          { name: :quantity_unit      , type: :string                           },
          { name: :replenishment_time , type: :integer                          }
        ]
      end
    end

    # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Verfuegbarkeit
    class StockAvailableGet < Line
      def self.specification
        [
          { name: :identifier   , type: :string  , fix: "STOCK_AVAILABLE_GET" },
          { name: :company_id   , type: :integer , default: 1                 },
          { name: :product_id   , type: :string                               },
          { name: :changed_only , type: :integer                              },
          { name: :system_name  , type: :string                               }
        ]
      end
    end

    # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_sendungsnummer
    class TrackingNumber < Line
      def self.specification
        [
          { name: :identifier  , type: :string  , fix: "TRACKING_NUMBER" },
          { name: :delivery_id , type: :integer                          },
          { name: :id          , type: :string                           }
        ]
      end
    end

    # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Lieferanten
    class VendorGet < Line
      def self.specification
        [
          { name: :identifier    , type: :string  , fix: "VENDOR_GET" },
          { name: :delivery_id   , type: :integer                     },
          { name: :company_id    , type: :integer , default: 1        },
          { name: :text          , type: :string                      },
          { name: :due_to_review , type: :integer                     },
          { name: :zip_code      , type: :string                      },
          { name: :only_changed  , type: :integer                     },
          { name: :system_name   , type: :string                      }
        ]
      end
    end
  end
end
