class ItemsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :render_404
  before_action :set_item, only: %i[ show edit update destroy ]
  before_action :set_category, only: %i[ new edit ]

  # GET /items or /items.json
  def index
    @items = Item.show_all
  end

  # GET /items/1 or /items/1.json
  def show
    @item = Item.find_join(params[:id])
  end

  # GET /items/new
  def new
    @item = Item.new
  end

  # GET /items/1/edit
  def edit
    @current_categories = ItemCategory.get_current_category(params[:id])
    current_categories_id = ItemCategory.where(item_id: params[:id]).map(&:category_id)
    notyet_categories_id =[]
    notyet_categories_name = []

    @categories.each do |category|
      if current_categories_id.include?(category.id) == false
        notyet_categories_id << category.id
        notyet_categories_name << category.name      
      end
    end

    @notyet_categories = notyet_categories_id.zip(notyet_categories_name)
    
  end

  # POST /items or /items.json
  def create
    @item = Item.new(item_params)

    respond_to do |format|
      if @item.save
        if params[:category]
          categories = params[:category]
          categories.each do |category|
            ItemCategory.create(item_id: @item.id, category_id: category)
          end
        end
        format.html { redirect_to item_url(@item), notice: "Item was successfully created." }
        format.json { render :show, status: :created, location: @item }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @item.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /items/1 or /items/1.json
  def update
    respond_to do |format|
      if @item.update(item_params)
        if params[:category] != nil
          categories = params[:category]
          categories.each do |category|
            ItemCategory.update_item_category(params[:id],category)
          end 
        end
        format.html { redirect_to item_url(@item), notice: "Item was successfully updated." }
        format.json { render :show, status: :ok, location: @item }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @item.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /items/1 or /items/1.json
  def destroy
    # Check if item has any order details
    order_details = OrderDetail.where(item_id: params[:id])
    
    if order_details.any?
      # Restore stock for NEW or PAID orders that include this item
      order_details.each do |detail|
        order = Order.find_by(id: detail.order_id)
        # Only restore stock if order status is NEW (0) or PAID (1)
        if order && (order.status_order == 0 || order.status_order == 1)
          @item.increase_stock(detail.quantity)
        end
      end
      
      # Delete all order details for this item
      order_details.destroy_all
    end
    
    # Delete item categories
    item_category = ItemCategory.where(item_id: params[:id])
    item_category.destroy_all

    # Delete the item
    @item.destroy

    respond_to do |format|
      format.html { redirect_to items_url, notice: "Item was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_item
      @item = Item.find(params[:id])
    end

    def set_category
      @categories = Category.all
    end

    # Only allow a list of trusted parameters through.
    def item_params
      params.require(:item).permit(:name, :description, :price, :stock)
    end

    def render_404
      render file: "#{Rails.root}/public/404.html", layout: false, status: 404
    end

end
