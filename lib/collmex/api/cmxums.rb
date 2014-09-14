# http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_umsaetze
module Collmex
  module Api
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
  end
end
