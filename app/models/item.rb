class Item < ApplicationRecord
    validates :name, presence: true, uniqueness: true
    validates :description, presence: true, length: { maximum: 150, too_long: "%{count} characters is the maximum allowed" }
    validates :price, presence: true, numericality: {greater_than_or_equal_to: 0.01}
    validates :stock, presence: true, numericality: {greater_than_or_equal_to: 0}

    # Check if item is in stock
    def in_stock?
        stock > 0
    end

    # Check if requested quantity is available
    def has_stock?(quantity)
        stock >= quantity.to_i
    end

    # Decrease stock by quantity
    def decrease_stock(quantity)
        self.stock -= quantity.to_i
        save
    end

    # Increase stock by quantity
    def increase_stock(quantity)
        self.stock += quantity.to_i
        save
    end

    def self.show_all
        find_by_sql("select items.*, GROUP_CONCAT(categories.name) as category from items left join item_categories on item_id = items.id left join categories on categories.id = category_id group by items.id ")
    end

    def self.find_join(id)
        find_by_sql("select items.*, GROUP_CONCAT(categories.name) as category from items left join item_categories on item_id = items.id left join categories on categories.id = category_id where items.id = #{id} group by items.id ")
    end

end
