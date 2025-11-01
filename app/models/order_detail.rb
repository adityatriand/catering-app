class OrderDetail < ApplicationRecord
  belongs_to :order
  belongs_to :item
  
  def self.update_item_order(order_id,item_id,quantity)
    order = Order.find_by(id: order_id)
    item = Item.find_by(id: item_id)
    existing_detail = OrderDetail.find_by(order_id: order_id, item_id: item_id)
    
    if existing_detail.nil?
      price = Item.select(:price).where(id: item_id).first
      # Only decrease stock if order is NEW or PAID
      if order && (order.status_order == 0 || order.status_order == 1) && item && quantity.to_i > 0
        if item.has_stock?(quantity.to_i)
          item.decrease_stock(quantity.to_i)
        else
          return false # Insufficient stock
        end
      end
      create(order_id: order_id, item_id: item_id, price: price[:price], quantity: quantity )
      Order.update_total_price(order_id)
    else
      old_qty = existing_detail.quantity.to_i
      new_qty = quantity.to_i
      
      if new_qty == 0
        # Restore stock if removing item and order is NEW or PAID
        if order && (order.status_order == 0 || order.status_order == 1) && item
          item.increase_stock(old_qty)
        end
        destory_order_detail(order_id,item_id)
      elsif new_qty != old_qty && order && item
        # Adjust stock based on quantity change
        if order.status_order == 0 || order.status_order == 1
          quantity_change = new_qty - old_qty
          if quantity_change > 0
            # Increasing quantity - check and decrease stock
            if item.has_stock?(quantity_change)
              item.decrease_stock(quantity_change)
            else
              return false # Insufficient stock
            end
          elsif quantity_change < 0
            # Decreasing quantity - restore stock
            item.increase_stock(quantity_change.abs)
          end
        end
        existing_detail.quantity = quantity.to_i
        existing_detail.save
        Order.update_total_price(order_id)        
      end
    end
    true
  end

  def self.destory_order_detail(order_id,item_id)
    order_detail = OrderDetail.find_by(order_id: order_id, item_id: item_id)
    order_detail&.destroy
  end

end
