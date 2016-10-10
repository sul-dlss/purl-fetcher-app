FactoryGirl.define do
  factory :purl do
    sequence :druid do |n|
      "druid:zz#{n.to_s * 3}yy#{n.to_s * 4}"
    end
  end
end
