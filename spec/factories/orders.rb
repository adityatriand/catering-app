FactoryBot.define do
  factory :order do
    email { Faker::Internet.email }
    status_order { 0 } # NEW
    total_price { 15000.0 }

    factory :paid_order do
      status_order { 1 } # PAID
    end

    factory :canceled_order do
      status_order { 2 } # CANCELED
    end
  end
end
