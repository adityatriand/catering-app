require 'rails_helper'

RSpec.describe OrdersController, type: :controller do

  describe 'GET #index' do
    it "populates an array of all orders" do
      order1 = create(:order)
      order2 = create(:order)
      get :index
      expect(assigns(:orders)).to be_present
    end

    it "renders the :index template" do
      get :index
      expect(response).to render_template :index
    end

    context "with email filter" do
      it "filters orders by email" do
        email = "test@example.com"
        order = create(:order, email: email)
        create(:order_detail, order: order)
        get :index, params: { email: email }
        expect(assigns(:orders)).to be_present
      end
    end

    context "with today filter" do
      it "filters orders by today" do
        date = Date.current.to_s
        get :index, params: { today: date }
        expect(assigns(:orders)).to be_present
      end
    end
  end

  describe 'GET #show' do
    let(:order) { create(:order) }
    let!(:order_detail) { create(:order_detail, order: order) }

    it "assigns the requested order to @order" do
      get :show, params: { id: order }
      expect(assigns(:order)).to be_present
    end

    it "renders the :show template" do
      get :show, params: { id: order }
      expect(response).to render_template :show
    end
  end

  describe 'GET #new' do
    it "assigns a new order to @order" do
      get :new
      expect(assigns(:order)).to be_a_new(Order)
    end

    it "renders the :new template" do
      get :new
      expect(response).to render_template :new
    end

    it "assigns items to @items" do
      item = create(:item)
      get :new
      expect(assigns(:items)).to include(item)
    end
  end

  describe 'GET #edit' do
    let(:order) { create(:order, status_order: 0) }
    let!(:order_detail) { create(:order_detail, order: order) }

    before do
      get :edit, params: { id: order }
    end

    it "assigns the requested order to @order" do
      expect(assigns(:order)).to eq order
    end

    it "renders the :edit template for NEW orders" do
      expect(response).to render_template :edit
    end

    it "redirects for PAID orders" do
      order.update(status_order: 1)
      get :edit, params: { id: order }
      expect(response).to redirect_to orders_path
    end

    it "redirects for CANCELED orders" do
      order.update(status_order: 2)
      get :edit, params: { id: order }
      expect(response).to redirect_to orders_path
    end
  end

  describe 'POST #create' do
    let(:item1) { create(:item, stock: 50, price: 10000.0) }
    let(:item2) { create(:item, stock: 30, price: 15000.0) }
    let(:valid_params) do
      {
        order: { email: "customer@example.com" },
        item: [item1.id.to_s, item2.id.to_s],
        "quantity_#{item1.id}": "2",
        "quantity_#{item2.id}": "1"
      }
    end

    context "with valid attributes" do
      it "saves the new order in the database" do
        expect{
          post :create, params: valid_params
        }.to change(Order, :count).by(1)
      end

      it "creates order details" do
        expect{
          post :create, params: valid_params
        }.to change(OrderDetail, :count).by(2)
      end

      it "decreases item stock" do
        initial_stock1 = item1.stock
        initial_stock2 = item2.stock
        post :create, params: valid_params
        item1.reload
        item2.reload
        expect(item1.stock).to eq(initial_stock1 - 2)
        expect(item2.stock).to eq(initial_stock2 - 1)
      end

      it "redirects to orders#show" do
        post :create, params: valid_params
        expect(response).to redirect_to(order_path(assigns(:order)))
      end
    end

    context "with invalid email" do
      it "redirects with error message" do
        invalid_params = valid_params.merge(order: { email: "invalid-email" })
        post :create, params: invalid_params
        expect(response).to redirect_to(new_order_path)
      end
    end

    context "with insufficient stock" do
      it "does not create order when stock is insufficient" do
        item1.update(stock: 1)
        expect{
          post :create, params: valid_params
        }.not_to change(Order, :count)
      end

      it "redirects with error message" do
        item1.update(stock: 1)
        post :create, params: valid_params
        expect(response).to redirect_to(new_order_path)
      end
    end

    context "with no items selected" do
      it "redirects when no items are provided" do
        params_without_items = { order: { email: "customer@example.com" } }
        post :create, params: params_without_items
        expect(response).to redirect_to(orders_path)
      end
    end
  end

  describe 'PATCH #update' do
    let(:order) { create(:order, status_order: 0, email: "test@example.com") }
    let(:item) { create(:item, stock: 50, price: 10000.0) }
    let!(:order_detail) { create(:order_detail, order: order, item: item, quantity: 5) }

    before do
      order.decrease_stock_on_create
      order.update(total_price: 50000.0) # Ensure order has total_price
    end

    context "with valid attributes" do
      it "updates order status" do
        patch :update, params: { id: order, order: { status_order: "1", email: order.email } }
        order.reload
        expect(order.status_order).to eq(1)
      end

      it "redirects to order#show" do
        patch :update, params: { id: order, order: { status_order: "1", email: order.email } }
        expect(response).to redirect_to(order_path(order))
      end
    end

    context "when updating order details" do
      it "updates item quantities" do
        # Make sure item has enough stock
        item.update(stock: 50)
        item.reload
        
        update_params = {
          id: order.id,
          order: { status_order: "0", email: order.email },
          item: [item.id.to_s],
          "quantity_#{item.id}": "8"
        }
        patch :update, params: update_params
        order_detail.reload
        expect(order_detail.quantity).to eq(8)
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:order) { create(:order, status_order: 0) }
    let(:item) { create(:item, stock: 50) }
    let!(:order_detail) { create(:order_detail, order: order, item: item, quantity: 5) }

    before do
      order.decrease_stock_on_create
    end

    it "deletes the order from the database" do
      expect{
        delete :destroy, params: { id: order }
      }.to change(Order, :count).by(-1)
    end

    it "restores stock when order is deleted" do
      item.reload
      initial_stock = item.stock
      delete :destroy, params: { id: order }
      item.reload
      expect(item.stock).to eq(initial_stock + 5)
    end

    it "redirects to orders#index" do
      delete :destroy, params: { id: order }
      expect(response).to redirect_to orders_url
    end
  end

end

