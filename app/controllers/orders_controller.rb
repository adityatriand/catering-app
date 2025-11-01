class OrdersController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :render_404
  before_action :set_order, only: %i[ edit update destroy ]
  before_action :set_item, only: %i[ new edit ]
  before_action :set_status, only: %i[ index ]


  # GET /orders or /orders.json
  def index
    if params[:email]
      @orders = Order.show_all_by_email(params[:email])
    elsif params[:today]
      @orders = Order.show_all_by_today(params[:today])
    elsif params[:total_price]
      @orders = Order.show_all_by_total_price(params[:total_price], params[:sign])
    elsif params[:date_start]
      @orders = Order.show_all_by_range_date(params[:date_start], params[:date_end])
    else
      @orders = Order.show_all
    end
  end

  # GET /orders/1 or /orders/1.json
  def show
    @order = Order.find_join(params[:id])
    if @order[0][:id] == nil
      render_404
    end
  end

  # GET /orders/new
  def new
    @order = Order.new
  end

  # GET /orders/1/edit
  def edit
    @item_orders = Order.get_item_order(params[:id])
    if @order[:status_order] == 0
      current_items_order_id = OrderDetail.where(order_id: params[:id]).map(&:item_id)
      notyet_items_order_id =[]
      notyet_items_name = []
      notyet_items_price = []
  
      @items.each do |item|
        if current_items_order_id.include?(item.id) == false
          notyet_items_order_id << item.id
          notyet_items_name << item.name
          notyet_items_price << item.price 
        end
      end
  
      @notyet_item_orders = notyet_items_order_id.zip(notyet_items_name, notyet_items_price)
    else
      redirect_to orders_path, notice: "Order cannot edit because it's already PAID / CANCELED"
    end
  end

  # POST /orders or /orders.json
  def create
    @total_price = 0
    email = params[:order][:email]
    if valid_email?(email)
      @order_items = params[:item]
      if !@order_items.nil?
        # Validate stock availability before creating order
        stock_error = []
        @order_items.each do |order_item|
          item = Item.find_by(id: order_item)
          quantity = params["quantity_"+order_item].to_i
          
          if item.nil?
            stock_error << "Item not found"
          elsif quantity <= 0
            stock_error << "#{item.name}: Quantity must be greater than 0"
          elsif !item.has_stock?(quantity)
            stock_error << "#{item.name}: Insufficient stock. Available: #{item.stock}, Requested: #{quantity}"
          end
        end
        
        if stock_error.any?
          redirect_to new_order_path, alert: stock_error.join(". ")
          return
        end
        
        @order = Order.create(email: email, status_order: 0)
        @order_items.each do |order_item|
            price_item = Item.select(:price).where(id: order_item).first
            quantity = params["quantity_"+order_item]
            @total_price = @total_price + (price_item[:price] * quantity.to_f)
            new_order_detail = OrderDetail.new(order_id: @order.id, item_id: order_item, price: price_item[:price], quantity: quantity.to_i)
            new_order_detail.save
        end      
        @order.total_price = @total_price
        
        # Decrease stock after order is created
        if @order.save
          unless @order.decrease_stock_on_create
            @order.restore_stock_on_destroy
            @order.destroy
            redirect_to new_order_path, alert: "Insufficient stock. Order was not created."
            return
          end
        end
      end
      respond_to do |format|
        if @order_items.nil?
          format.html { redirect_to orders_path, notice: "Unsucessfully process. Order must have 1 item order" }
        elsif @order.save
          format.html { redirect_to order_url(@order), notice: "Order was successfully created." }
          format.json { render :show, status: :created, location: @order }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @order.errors, status: :unprocessable_entity }
        end
      end
    else
      redirect_to new_order_path, notice: "Unsucessfully process. Use Email Valid"
    end
  end

  # PATCH/PUT /orders/1 or /orders/1.json
  def update
    old_status = @order.status_order
    new_status = params[:order][:status_order].to_i
    @order.email = params[:order][:email]
    
    # Validate stock if status is changing or items are being updated
    if old_status != new_status || params[:item] != nil
      # If changing status, handle stock accordingly
      if old_status != new_status
        unless @order.update_stock_on_status_change(old_status, new_status)
          redirect_to edit_order_path(@order), alert: "Cannot change order status: Insufficient stock."
          return
        end
      end
      
      # If updating items, validate stock
      if params[:item] != nil && (new_status == 0 || new_status == 1)
        stock_error = []
        params[:item].each do |item_id|
          item = Item.find_by(id: item_id)
          quantity = params["quantity_"+item_id].to_i
          
          if item.nil?
            stock_error << "Item not found"
          elsif quantity <= 0
            # Quantity 0 is allowed (to remove item)
            next
          else
            # Check current order detail to see if we're increasing quantity
            existing_detail = OrderDetail.find_by(order_id: params[:id], item_id: item_id)
            current_quantity = existing_detail ? existing_detail.quantity : 0
            quantity_change = quantity - current_quantity
            
            if quantity_change > 0 && !item.has_stock?(quantity_change)
              stock_error << "#{item.name}: Insufficient stock. Available: #{item.stock}, Additional needed: #{quantity_change}"
            end
          end
        end
        
        if stock_error.any?
          # Restore stock if status was changed
          if old_status != new_status
            @order.update_stock_on_status_change(new_status, old_status)
            @order.status_order = old_status
            @order.save
          end
          redirect_to edit_order_path(@order), alert: stock_error.join(". ")
          return
        end
      end
    end
    
    @order.status_order = new_status
    respond_to do |format|
      if @order.save
        if params[:item] != nil
          # Update order details
          item_orders = params[:item]
          stock_update_errors = []
          item_orders.each do |item|
            quantity = params["quantity_"+item].to_i
            unless OrderDetail.update_item_order(params[:id],item,quantity)
              item_obj = Item.find_by(id: item)
              stock_update_errors << "#{item_obj ? item_obj.name : 'Item'}: Insufficient stock"
            end
          end
          
          if stock_update_errors.any?
            redirect_to edit_order_path(@order), alert: stock_update_errors.join(". ")
            return
          end
        end
        @order2 = OrderDetail.find_by(order_id: params[:id])
        if @order2.nil?
          order = Order.find_by(id: params[:id])
          order.restore_stock_on_destroy
          order.destroy
          format.html { redirect_to orders_path, notice: "Order was successfully destroyed." }
        else
          format.html { redirect_to order_url(@order), notice: "Order was successfully updated." }
          format.json { render :show, status: :ok, location: @order }
        end
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /orders/1 or /orders/1.json
  def destroy
    # Restore stock before destroying order
    @order.restore_stock_on_destroy
    order_detail = OrderDetail.where(order_id: params[:id])
    order_detail.destroy_all  
    @order.destroy

    respond_to do |format|
      format.html { redirect_to orders_url, notice: "Order was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_order
      @order = Order.find(params[:id])
    end

    def set_item
      @items = Item.all
      # Filter out items with 0 stock for new orders
      @available_items = @items.select { |item| item.stock > 0 } if action_name == 'new'
    end

    # Only allow a list of trusted parameters through.
    def order_params
      params.require(:order).permit(:email, :status_order, :total_price)
    end

    def render_404
      render file: "#{Rails.root}/public/404.html", layout: false, status: 404
    end

    def valid_email?(email)
      valid_email = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
      email =~ valid_email
    end


    def set_status
      current_datetime = DateTime.current.localtime
      orders = Order.all

      orders.each do |order|
        date_order = order.created_at.localtime
        order_time = Time.parse(date_order.strftime('%H:%M:%S'))
        current_time = Time.parse(current_datetime.strftime('%H:%M:%S'))
        if current_time.hour > 16 
          if date_order.to_date == current_datetime.to_date
            if order_time.hour < 17  && order.status_order == 0
              update_status = Order.find(order.id)
              old_status = update_status.status_order
              update_status.status_order = 2
              if update_status.save
                # Restore stock when order is automatically canceled
                update_status.update_stock_on_status_change(old_status, 2)
              end
            end
          else
            tommorow_date_order = date_order.days_since(1)
            if tommorow_date_order.to_date == current_datetime.to_date
              if order.status_order == 0
                update_status = Order.find(order.id)
                old_status = update_status.status_order
                update_status.status_order = 2
                if update_status.save
                  # Restore stock when order is automatically canceled
                  update_status.update_stock_on_status_change(old_status, 2)
                end
              end
            end
          end
        end
      end

    end
end
