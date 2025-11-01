class Order < ApplicationRecord
    validates :email, presence: true,format: { with: URI::MailTo::EMAIL_REGEXP }
    
    # Stock management methods
    def update_stock_on_status_change(old_status, new_status)
        order_details = OrderDetail.where(order_id: id)
        
        order_details.each do |detail|
            item = Item.find_by(id: detail.item_id)
            next unless item
            
            quantity = detail.quantity
            
            # If order was NEW or PAID and now becomes CANCELED, restore stock
            if (old_status == 0 || old_status == 1) && new_status == 2
                item.increase_stock(quantity)
            # If order was CANCELED and now becomes NEW or PAID, decrease stock
            elsif old_status == 2 && (new_status == 0 || new_status == 1)
                if item.has_stock?(quantity)
                    item.decrease_stock(quantity)
                else
                    return false # Not enough stock
                end
            end
        end
        true
    end
    
    # Decrease stock when order is created (status NEW)
    def decrease_stock_on_create
        order_details = OrderDetail.where(order_id: id)
        
        order_details.each do |detail|
            item = Item.find_by(id: detail.item_id)
            next unless item
            
            if item.has_stock?(detail.quantity)
                item.decrease_stock(detail.quantity)
            else
                return false # Not enough stock
            end
        end
        true
    end
    
    # Restore stock when order is destroyed
    def restore_stock_on_destroy
        order_details = OrderDetail.where(order_id: id)
        
        # Only restore stock if order was NEW or PAID (not CANCELED)
        if status_order == 0 || status_order == 1
            order_details.each do |detail|
                item = Item.find_by(id: detail.item_id)
                next unless item
                item.increase_stock(detail.quantity)
            end
        end
    end

    def self.show_all
        find_by_sql("select orders.* , GROUP_CONCAT(items.name || ' - ' || cast(order_details.quantity as varchar) || ' portion / Rp.' || cast(order_details.price as varchar), ' | '  ) as detail from orders left join order_details on orders.id = order_details.order_id left join items on items.id = order_details.item_id group by orders.id ")
    end

    def self.show_all_by_email(email)
        find_by_sql("select orders.* , GROUP_CONCAT(items.name || ' - ' || cast(order_details.quantity as varchar) || ' portion / Rp.' || cast(order_details.price as varchar), ' | '  ) as detail from orders left join order_details on orders.id = order_details.order_id left join items on items.id = order_details.item_id where orders.email = '#{email}' group by orders.id ")
    end

    def self.show_all_by_today(date)
        find_by_sql("select orders.* , GROUP_CONCAT(items.name || ' - ' || cast(order_details.quantity as varchar) || ' portion / Rp.' || cast(order_details.price as varchar), ' | '  ) as detail from orders left join order_details on orders.id = order_details.order_id left join items on items.id = order_details.item_id where DATE(orders.created_at) = '#{date}' group by orders.id ")
    end

    def self.show_all_by_total_price(total,sign)
        find_by_sql("select orders.* , GROUP_CONCAT(items.name || ' - ' || cast(order_details.quantity as varchar) || ' portion / Rp.' || cast(order_details.price as varchar), ' | '  ) as detail from orders left join order_details on orders.id = order_details.order_id left join items on items.id = order_details.item_id where orders.total_price #{sign} #{total} group by orders.id ")
    end

    def self.show_all_by_range_date(date_start,date_end)
        find_by_sql("select orders.* , GROUP_CONCAT(items.name || ' - ' || cast(order_details.quantity as varchar) || ' portion / Rp.' || cast(order_details.price as varchar), ' | '  ) as detail from orders left join order_details on orders.id = order_details.order_id left join items on items.id = order_details.item_id where DATE(orders.created_at) between '#{date_start}' and '#{date_end}' group by orders.id ")
    end

    def self.find_join(id)
        find_by_sql("select orders.* , GROUP_CONCAT(items.name || ' - ' || cast(order_details.quantity as varchar) || ' portion / Rp.' || cast(order_details.price as varchar), ' | '  ) as detail from orders left join order_details on orders.id = order_details.order_id left join items on items.id = order_details.item_id where orders.id = #{id}")
    end

    def self.get_item_order(id)
        find_by_sql("select items.name, items.id, order_details.quantity, order_details.price from order_details inner join orders on orders.id = order_details.order_id inner join items on items.id = order_details.item_id where orders.id = #{id}")
    end

    def self.update_total_price(order_id)
        update_prices = find_by_sql("select SUM(price*quantity) as total_price from order_details where order_id = #{order_id}").first
        order = Order.find_by(id: order_id)
        order.update(total_price: update_prices[:total_price])
    end

end
