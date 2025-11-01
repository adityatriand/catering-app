FactoryBot.define do
  factory :item do
    name { Faker::Food.dish }
    description { "Delicious food item with great taste" }
    price { 10000.0 }
    stock { 50 }
  end

  factory :invalid_item, parent: :item do
    name { nil }
    description { nil }
    price { 10000.0 }
    stock { nil }
  end

  factory :item_out_of_stock, parent: :item do
    stock { 0 }
  end
end
