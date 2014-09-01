class Collmex::Api::NewObjectId < Collmex::Api::Line
  def self.specification
    [
      { name: :identifier       , type: :string    , fix: "NEW_OBJECT_ID"   },
      { name: :id               , type: :integer                            },
      { name: :temporary_id     , type: :integer                            },
      { name: :line             , type: :integer                            },
    ]
  end
end
