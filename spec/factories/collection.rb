FactoryBot.define do
  factory :collection do
    sequence :druid do |n|
      "druid:yy#{n.to_s * 3}xx#{n.to_s * 4}"
    end
  end
end
