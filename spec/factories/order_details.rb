FactoryBot.define do
  factory :order_detail do
    association :order
    association :item
    price { 15000.0 }
    quantity { 2 }
  end
end
