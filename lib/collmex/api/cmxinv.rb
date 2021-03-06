# http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_rechnungen
module Collmex
  module Api
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
  end
end
