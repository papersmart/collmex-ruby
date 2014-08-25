require "spec_helper"

describe Collmex::Api do

  describe ".allowed_command?" do
    it "returns false for an Array" do
      expect(described_class.allowed_command?([])).to be_falsey
    end

    it "returns true for a Collmex::Api Object" do
      obj = described_class::AccdocGet.new
      expect(described_class.allowed_command?(obj)).to be_truthy
    end
  end

  describe ".stringify_field" do
    tests = [
      { type: :string,      input: "asd",             outcome: "asd" },
      { type: :string,      input: "",                outcome: "" },
      { type: :string,      input: nil,               outcome: "" },

      { type: :integer,     input: nil,               outcome: "" },
      { type: :integer,     input: 2,                 outcome: "2" },
      { type: :integer,     input: 2.2,               outcome: "2" },
      { type: :integer,     input: -2.2,              outcome: "-2" },
      { type: :integer,     input: "-2.2",            outcome: "-2" },

      { type: :int,         input: nil,               outcome: "" },
      { type: :int,         input: 2,                 outcome: "2" },
      { type: :int,         input: 2.2,               outcome: "2" },
      { type: :int,         input: -2.2,              outcome: "-2" },
      { type: :int,         input: "-2.2",            outcome: "-2" },

      { type: :float,       input: nil,               outcome: "" },
      { type: :float,       input: 2.2,               outcome: "2,20" },
      { type: :float,       input: 2,                 outcome: "2,00" },
      { type: :float,       input: "2",               outcome: "2,00" },
      { type: :float,       input: "-2.00",           outcome: "-2,00" },
      { type: :float,       input: -2.00,             outcome: "-2,00" },

      { type: :currency,    input: 2,                 outcome: "0,02" },
      { type: :currency,    input: "2",               outcome: "0,02" },
      { type: :currency,    input: "-2.23",           outcome: "-2,23" },   # <= WARNING
      { type: :currency,    input: "-2,23",           outcome: "-2,23" },   # <= WARNING
      { type: :currency,    input: -2.00,             outcome: "-2,00" },
      { type: :currency,    input: -2.90,             outcome: "-2,90" },
      { type: :currency,    input: -2.999,             outcome: "-3,00" },
      { type: :currency,    input: -102.90,           outcome: "-102,90" },    # <= WARNING
    ]
    tests.each do |test|
      it "should represent #{test[:type]} \"#{test[:input].inspect}\" as \"#{test[:outcome]}\"" do
        expect(described_class.stringify(test[:input],test[:type])).to be === test[:outcome]
      end
    end
  end

  describe ".parse_line" do
    subject { described_class.parse_line(line) }

    context "when given a valid line" do
      context "as an array" do
        let(:line) { described_class::Login.new([12, 34]).to_a }
        it { is_expected.to be_a(described_class::Line) }
      end

      context "as a CSV string" do
        let(:line) { described_class::Login.new([12, 34]).to_csv }
        it { is_expected.to be_a(described_class::Line) }
      end
    end

    context "when given an invalid line" do
      let(:line) { ["OMG", 2, 3, 4, 5, 6] }

      it "throws an error" do
        expect { subject }.to raise_error(RuntimeError,
          "Could not find a subclass of Collmex::Api::Line named \"Omg\""
        )
      end
    end
  end

  describe ".parse_field" do
    tests = [
      { type: :string,      input: "asd",             outcome: "asd" },
      { type: :string,      input: "2",               outcome: "2" },
      { type: :string,      input: "2",               outcome: "2" },
      { type: :string,      input: 2,                 outcome: "2" },
      { type: :string,      input: "-2.3",            outcome: "-2.3" },
      { type: :string,      input:  nil,              outcome: "" },

      { type: :date,        input: nil,               outcome: nil },
      { type: :date,        input: "19851012",        outcome: Date.parse("12.10.1985") },
      { type: :date,        input: "1985/10/12",      outcome: Date.parse("12.10.1985") },
      { type: :date,        input: "1985-10-12",      outcome: Date.parse("12.10.1985") },

      { type: :integer,     input: "2,3",             outcome: 2 },          # <= WARNING
      { type: :integer,     input: "2",               outcome: 2 },
      { type: :integer,     input: "2.2",             outcome: 2 },
      { type: :integer,     input: 2,                 outcome: 2 },
      { type: :integer,     input: 2.2,               outcome: 2 },
      { type: :integer,     input: nil,               outcome: nil },          # <= WARNING

      { type: :int,         input: "2,3",             outcome: 2 },          # <= WARNING
      { type: :int,         input: "2",               outcome: 2 },
      { type: :int,         input: "2.2",             outcome: 2 },
      { type: :int,         input: 2,                 outcome: 2 },
      { type: :int,         input: 2.2,               outcome: 2 },
      { type: :int,         input: nil,               outcome: nil },          # <= WARNING

      { type: :float,       input: "2",               outcome: 2.0 },
      { type: :float,       input: 2,                 outcome: 2.0 },
      { type: :float,       input: "2,0",             outcome: 2.0 },
      { type: :float,       input: "2.0",             outcome: 2.0 },
      { type: :float,       input: 2.0,               outcome: 2.0 },
      { type: :float,       input: "2.2",             outcome: 2.2 },
      { type: :float,       input: 2.2,               outcome: 2.2 },
      { type: :float,       input: "2,3",             outcome: 2.3 },
      { type: :float,       input: "-2,3",            outcome: -2.3 },
      { type: :float,       input: nil,               outcome: nil },

      { type: :currency,    input: "2",               outcome: 2 },
      { type: :currency,    input: 0,                 outcome: 0 },
      { type: :currency,    input: 2,                 outcome: 2 },
      { type: :currency,    input: 2.20,              outcome: 220 },
      { type: :currency,    input: "0",               outcome: 0 },
      { type: :currency,    input: "0000",            outcome: 0 },
      { type: :currency,    input: "2,0",             outcome: 200 },
      { type: :currency,    input: "2,1",             outcome: 210 },
      { type: :currency,    input: "-2,1",            outcome: -210 },
      { type: :currency,    input: "-2.1",            outcome: -210 },
      { type: :currency,    input: "20,00",           outcome: 2000 },
      { type: :currency,    input: "20,12",           outcome: 2012 },
      { type: :currency,    input: "-20,12",          outcome: -2012 },
      { type: :currency,    input: nil,               outcome: nil },
      { type: :currency,    input: "-20.12",          outcome: -2012 },
      { type: :currency,    input: "-20.",            outcome: -2000 },
      { type: :currency,    input: "20.",             outcome: 2000 },
      { type: :currency,    input: ".20",             outcome: 20 },
      { type: :currency,    input: "-,20",            outcome: -20 },
      { type: :currency,    input: ",20",             outcome: 20 },

      { type: :currency,    input: "20,000",          outcome: 2000000 },
      { type: :currency,    input: "123,456",         outcome: 12345600 },
      { type: :currency,    input: "123,456,789",     outcome: 12345678900 },
      { type: :currency,    input: "123.456.789",     outcome: 12345678900 },
      { type: :currency,    input: "23.456.789",      outcome: 2345678900 },
      { type: :currency,    input: "-23.456.000",     outcome: -2345600000},
      { type: :currency,    input: "-23,456,000",     outcome: -2345600000 },

      { type: :currency,    input: "-23,456.00",      outcome: -2345600 },
      { type: :currency,    input: "23,456.13",       outcome: 2345613 },

      { type: :currency,    input: "21,000",          outcome: 2100000 },
      { type: :currency,    input: "12.345,20",       outcome: 1234520 },

    ]
    tests.each_with_index do |t,i|
      it "should parse #{t[:type]} value for \"#{t[:input]}\"" do
        expect(described_class.parse_field( t[:input], t[:type])).to be === t[:outcome]
      end
    end
  end
end

# http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_adressgruppen
describe Collmex::Api::Adrgrp do
  it_behaves_like "an API command" do
    let(:params) { { id: 1 } }
    let(:output) { ["ADRGRP", 1, ""] }
  end
end

# http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Periodische_rechnung
describe Collmex::Api::AboGet do
  it_behaves_like "an API command" do
    let(:params) { { customer_id: 9999 } }
    let(:output) { ["ABO_GET", 9999, 1, "", nil, nil, nil, nil, ""] }
  end
end

# fixme ACCDOC # http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Buchhaltungsbelege
describe Collmex::Api::Accdoc do
  it_behaves_like "an API command" do
    let(:params) { { id: 1, customer_id: 9999 } }
    let(:output) { ["ACCDOC", 1, nil, 1, nil, nil, "", nil, nil, "", nil, nil, 9999, "", nil, "", nil, "", nil, "", "", nil, nil, nil, nil, nil] }
  end
end

# http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Buchhaltungsbelege
describe Collmex::Api::AccdocGet do
  it_behaves_like "an API command" do
    let(:params) { { id: 1, customer_id: 9999 } }
    let(:output) { ["ACCDOC_GET", 1, nil, 1, nil, nil, 9999, nil, nil, nil, nil, "", nil, nil, nil, nil, ""] }
  end
end

# http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Adressen
describe Collmex::Api::AddressGet do
  it_behaves_like "an API command" do
    let(:params) { { id: 1} }
    let(:output) { ["ADDRESS_GET", 1, nil, "", nil, "", nil, nil, "", nil] }
  end
end

# http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Adressgruppen
describe Collmex::Api::AddressGroupsGet do
  it_behaves_like "an API command" do
    let(:output) { ["ADDRESS_GROUPS_GET"] }
  end
end

# TODO http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Stuecklisten
# describe Collmex::Api::BillOfMaterialGet do
# end

# http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_periodische_rechnung
describe Collmex::Api::Cmxabo do
  it_behaves_like "an API command" do
    let(:params) { { customer_id: 9999 } }
    let(:output) { ["ABO_GET", 9999, 1, nil, nil, "", "", nil, nil, nil] }
  end
end

# TODO http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_taetigkeiten
# describe Collmex::Api::Cmxact do
# end

# http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_adressen
describe Collmex::Api::Cmxadr do
  it_behaves_like "an API command" do
    let(:params) { { id: 1 } }
    let(:output) { ["CMXADR", 1, nil, "", "", "", "", "", "", "", "", "", "", nil, "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", nil, nil, nil, 1] }
  end
end

# TODO Url?
describe Collmex::Api::AccbalGet do
  it_behaves_like "an API command" do
    let(:params) { { id: 1 } }
    let(:output) { ["ACCBAL_GET", 1, Date.today.year, nil, nil, nil] }
  end
end

# http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_kunde
describe Collmex::Api::Cmxknd do
  it_behaves_like "an API command" do
    let(:params) { { id: 1 } }
    let(:output) { ["CMXKND", 1, 1, "", "", "", "", "", "", "", "", "", "", nil, "", "", "", "", "", "", "", "", "", "", "", nil, nil, "", "", nil, "", nil, "", nil, "", nil, "", nil, nil, nil, "", nil, "", ""] }
  end
end

# http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_anspr
describe Collmex::Api::Cmxasp do
  it_behaves_like "an API command" do
    let(:params) { { id: 1 } }
    let(:output) { ["CMXASP", 1, nil, "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", nil, nil] }
  end
end

# TODO http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Stuecklisten
# describe Collmex::Api::Cmxbom do
# end

# http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_abw
describe Collmex::Api::Cmxepf do
  it_behaves_like "an API command" do
    let(:params) { { id: 1 } }
    let(:output) { ["CMXEPF", nil, 1, nil, nil, "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", nil, nil] }
  end
end

# http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_rechnungen
describe Collmex::Api::Cmxinv do
  it_behaves_like "an API command" do
    let(:params) { { id: 1, customer_id: 9999 } }
    let(:output) { ["CMXINV", 1, nil, nil, 1, nil, 9999, "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", nil, nil, nil, nil, "", nil, nil, nil, "", "", "", "", nil, nil, nil, nil, "", nil, nil, "", nil, nil, nil, nil, "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", nil, "", "", "", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil] }
  end
end

# http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_kunde
describe Collmex::Api::Cmxknd do
  it_behaves_like "an API command" do
    let(:params) { { id: 1 } }
    let(:output) { ["CMXKND", 1, 1, "", "", "", "", "", "", "", "", "", "", nil, "", "", "", "", "", "", "", "", "", "", "", nil, nil, "", "", nil, "", nil, "", nil, "", nil, "", nil, nil, nil, "", nil, "", ""] }
  end
end

# TODO http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_kontakte
# describe Collmex::Api::Cmxknt do
# end

# http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_lieferant
describe Collmex::Api::Cmxlif do
  it_behaves_like "an API command" do
    let(:params) { { id: 1 } }
    let(:output) { ["CMXLIF", 1, 1, "", "", "", "", "", "", "", "", "", "", nil, "", "", "", "", "", "", "", "", "", "", "", nil, "", "", nil, "", nil, "", "", "", nil] }
  end
end

# TODO http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_lieferantenrechnung
# describe Collmex::Api::Cmxlrn do
# end

# TODO http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_kundenauftraege
# describe Collmex::Api::Cmxord_2 do
# end

# TODO http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_produktionsauftraege
# describe Collmex::Api::Cmxpod do
# end

# TODO http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_produkt
# describe Collmex::Api::Cmxprd do
# end

# http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_preise
describe Collmex::Api::Cmxpri do
  it_behaves_like "an API command" do
    let(:params) { { product_id: 9999 } }
    let(:output) { ["CMXPRI", "9999", 1, nil, nil, nil, nil] }
  end
end

# TODO http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Projekte
# describe Collmex::Api::Cmxprj do
# end

# TOOD http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_lohn
# describe Collmex::Api::Cmxprl do
# end

# http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_angebote
describe Collmex::Api::Cmxqtn do
  it_behaves_like "an API command" do
    let(:params) { { id: 1, customer_id: 9999 } }
    let(:output) { ["CMXQTN", 1, nil, nil, 1, 9999, "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", nil, nil, nil, nil, "", nil, nil, nil, "", "", "", "", nil, nil, nil, nil, nil, nil, "", "", "", nil, nil, nil, nil, "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", nil, "", "", "", nil, nil, nil, nil, nil, nil, nil, nil, nil] }
  end
end

# TODO http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_bestand
# describe Collmex::Api::Cmxstk do
# end

# http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_umsaetze
describe Collmex::Api::Cmxums do
  it_behaves_like "an API command" do
    let(:params) { { customer_id: 9999 } }
    let(:output) { ["CMXUMS", 9999, 1, nil, "", nil, nil, nil, nil, nil, nil, nil, nil, "", nil, nil, "", nil, nil, nil, nil, nil, nil, "", nil, "", "", ""] }
  end
end

# TOOD http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Faellige_Lieferungen
# describe Collmex::Api::CreateDueDeliveries do
# end

# http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Kunden
describe Collmex::Api::CustomerGet do
  it_behaves_like "an API command" do
    let(:params) { { id: 1 } }
    let(:output) { ["CUSTOMER_GET", 1, 1, "", nil, "", nil, nil, nil, nil, nil, "", nil] }
  end
end

# http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Lieferungen
describe Collmex::Api::DeliveryGet do
  it_behaves_like "an API command" do
    let(:params) { { id: 1, customer_id: 9999 } }
    let(:output) { ["DELIVERY_GET", "1", 1, 9999, nil, nil, nil, "", nil, "", nil, nil] }
  end
end

# http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Rechnungen
describe Collmex::Api::InvoiceGet do
  it_behaves_like "an API command" do
    let(:params) { { id: 1, customer_id: 9999 } }
    let(:output) { ["INVOICE_GET", "1", 1, 9999, nil, nil, nil, "", nil, "", nil, nil] }
  end
end

# http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Zahlungen
describe Collmex::Api::InvoicePayment do
  it_behaves_like "an API command" do
    let(:params) { { id: 1 } }
    # TODO ???
    let(:output) { ["CMXKND", nil, 1, "", "", "", "", "", "", "", "", "", "", nil, "", "", "", "", "", "", "", "", "", "", "", nil, nil, "", "", nil, "", nil, "", nil, "", nil, "", nil, nil, nil, "", nil, "", ""] }
    let(:output) { ["INVOICE_PAYMENT", "1", nil, nil, nil, nil, nil, nil] }
  end
end

# http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Zahlungen
describe Collmex::Api::InvoicePaymentGet do
  it_behaves_like "an API command" do
    let(:params) { { id: 1 } }
    let(:output) { ["INVOICE_PAYMENT_GET", 1, "1", nil, ""] }
  end
end

# http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Authentifizierung
describe Collmex::Api::Login do
  it_behaves_like "an API command" do
    let(:params) { { username: 12, password: 34 } }
    let(:output) { ["LOGIN", 12, 34] }
  end
end

# http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Rueckmeldungen
describe Collmex::Api::Message do

  context "Success" do
    it_behaves_like "an API command" do
      let(:params)   { { type: "S" } }
      let(:output)   { ["MESSAGE", "S", nil, "", nil] }

      its(:success?) { should eq(true) }
      its(:result)   { should eq(:success) }
    end
  end

  context "Warning" do
    it_behaves_like "an API command" do
      let(:params)   { { type: "W" } }
      let(:output)   { ["MESSAGE", "W", nil, "", nil] }

      its(:success?) { should eq(false) }
      its(:result)   { should eq(:warning) }
    end
  end

  context "Error" do
    it_behaves_like "an API command" do
      let(:params)   { { type: "E" } }
      let(:output)   { ["MESSAGE", "E", nil, "", nil] }

      its(:success?) { should eq(false) }
      its(:result)   { should eq(:error) }
    end
  end

  context "Undefined" do
    it_behaves_like "an API command" do
      let(:params)   { nil }
      let(:output)   { ["MESSAGE", "", nil, "", nil] }

      its(:success?) { should eq(false) }
      its(:result)   { should eq(:undefined) }
    end
  end
end

# http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Payment
describe Collmex::Api::PaymentConfirmation do
  it_behaves_like "an API command" do
    let(:params) { { customer_order_id: 1 } }
    let(:output) { ["PAYMENT_CONFIRMATION", 1, nil, nil, nil, "", "", ""] }
  end
end

# http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_produktgruppen
describe Collmex::Api::Prdgrp do
  it_behaves_like "an API command" do
    let(:params) { { id: 1 } }
    let(:output) { ["PRDGRP", 1, "", nil] }
  end
end

# http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Produkte
describe Collmex::Api::ProductGet do
  it_behaves_like "an API command" do
    let(:params) { { id: 1 } }
    let(:output) { ["PRODUCT_GET", 1, "1", nil, "", nil, "", nil] }
  end
end

# http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Produktgruppen
describe Collmex::Api::ProductGroupsGet do
  it_behaves_like "an API command" do
    let(:params) { { id: 1 } }
    let(:output) { ["PRODUCT_GROUPS_GET"] }
  end
end

# TODO http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Produktionsauftraege
# describe Collmex::Api::ProductionOrderGet do
# end

# http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Projekte
describe Collmex::Api::ProjectGet do
  it_behaves_like "an API command" do
    let(:params) { { id: 1} }
    let(:output) { ["PROJECT_GET ", 1, 1, nil] }
  end
end

# http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Lieferantenauftraege
describe Collmex::Api::PurchaseOrderGet do
  it_behaves_like "an API command" do
    let(:params) { { id: 1, supplier_id: 9999 } }
    let(:output) { ["PURCHASE_ORDER_GET", "1", 1, 9999, "", nil, "", nil, "", nil] }
  end
end

# http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Angebote
describe Collmex::Api::QuotationGet do
  it_behaves_like "an API command" do
    let(:params) { { id: 1, customer_id: 9999 } }
    let(:output) { ["QUOTATION_GET", "1", 1, 9999, nil, nil, nil, "", nil, ""] }
  end
end

# http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Kundenauftraege
describe Collmex::Api::SalesOrderGet do
  it_behaves_like "an API command" do
    let(:params) { { id: 1, customer_id: 9999 } }
    let(:output) { ["SALES_ORDER_GET", "1", 1, 9999, nil, nil, "", "", nil, "", nil, nil] }
  end
end

# http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Suchmaschinen
describe Collmex::Api::SearchEngineProductsGet do
  it_behaves_like "an API command" do
    let(:params) { { id: 1, customer_id: 9999 } }
    let(:output) { ["SEARCH_ENGINE_PRODUCTS_GET", nil, nil] }
  end
end

# http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Verfuegbarkeit
describe Collmex::Api::StockAvailable do
  it_behaves_like "an API command" do
    let(:params) { { product_id: 1 } }
    let(:output) { ["STOCK_AVAILABLE", "1", 1, nil, "", nil] }
  end
end

# http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Verfuegbarkeit
describe Collmex::Api::StockAvailableGet do
  it_behaves_like "an API command" do
    let(:params) { { product_id: 1 } }
    let(:output) { ["STOCK_AVAILABLE_GET", 1, "1", nil, ""] }
  end
end

# TODO http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Bestandsaenderungen
# describe Collmex::Api::StockChange do
# end

# TODO http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Bestandsaenderungen
# describe Collmex::Api::StockChangeGet do
# end

# http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_sendungsnummer
describe Collmex::Api::TrackingNumber do
  it_behaves_like "an API command" do
    let(:params) { { id: 1} }
    let(:output) { ["TRACKING_NUMBER", nil, "1"] }
  end
end

# http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,api_Lieferanten
describe Collmex::Api::VendorGet do
  it_behaves_like "an API command" do
    let(:params) { { delivery_id: 1 } }
    let(:output) { ["VENDOR_GET", 1, 1, "", nil, "", nil, ""] }
  end
end
