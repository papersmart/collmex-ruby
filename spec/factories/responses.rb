FactoryGirl.define do
  factory :message, class: "Collmex::Api::Message" do
    trait :success do
      type "S"
    end

    trait :error do
      type "E"
    end
  end
end
