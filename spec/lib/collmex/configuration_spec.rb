require "spec_helper"

describe Collmex::Configuration do
  subject { Collmex.config }

  it { is_expected.to respond_to :user        }
  it { is_expected.to respond_to :password    }
  it { is_expected.to respond_to :customer_id }
  it { is_expected.to respond_to :csv_options }
end
