require 'rails_helper'

RSpec.describe Order, type: :model do
  subject(:order) {
    Order.new(
      email: 'test@gmail.com',
      status_order: 0,
      total_price: 15000.0
    )
  }

  context 'validation for all field' do
    
    it 'is valid with an email, status_order, and total_price' do
      expect(order).to be_valid
    end

  end

  context 'validation for email field' do

    it 'is invalid without email' do
      order.email = nil
      order.valid?
      expect(order.errors[:email]).to include("can't be blank")
    end 

    it 'is invalid if use wrong format email' do
      order.email = "invalid-email"
      order.valid?
      expect(order.errors[:email]).not_to be_empty
    end

    it 'is valid with proper email format' do
      order.email = "test@example.com"
      expect(order).to be_valid
    end

  end

  context 'stock management methods' do
    
    describe '#decrease_stock_on_create' do
      let(:item1) { create(:item, stock: 50) }
      let(:item2) { create(:item, stock: 30) }
      let(:order) { create(:order) }

      before do
        create(:order_detail, order: order, item: item1, quantity: 10)
        create(:order_detail, order: order, item: item2, quantity: 5)
      end

      it 'decreases stock for all order items' do
        order.decrease_stock_on_create
        item1.reload
        item2.reload
        expect(item1.stock).to eq(40)
        expect(item2.stock).to eq(25)
      end

      it 'returns true when stock is available' do
        expect(order.decrease_stock_on_create).to be true
      end

      it 'returns false when insufficient stock' do
        item1.update(stock: 5)
        expect(order.decrease_stock_on_create).to be false
      end
    end

    describe '#restore_stock_on_destroy' do
      let(:item1) { create(:item, stock: 30) }
      let(:item2) { create(:item, stock: 20) }
      let(:order) { create(:order, status_order: 0) }

      before do
        create(:order_detail, order: order, item: item1, quantity: 10)
        create(:order_detail, order: order, item: item2, quantity: 5)
        order.decrease_stock_on_create
      end

      it 'restores stock for NEW orders' do
        item1.reload
        item2.reload
        initial_stock1 = item1.stock
        initial_stock2 = item2.stock
        
        order.restore_stock_on_destroy
        item1.reload
        item2.reload
        
        expect(item1.stock).to eq(initial_stock1 + 10)
        expect(item2.stock).to eq(initial_stock2 + 5)
      end

      it 'restores stock for PAID orders' do
        order.update(status_order: 1)
        item1.reload
        item2.reload
        initial_stock1 = item1.stock
        initial_stock2 = item2.stock
        
        order.restore_stock_on_destroy
        item1.reload
        item2.reload
        
        expect(item1.stock).to eq(initial_stock1 + 10)
        expect(item2.stock).to eq(initial_stock2 + 5)
      end

      it 'does not restore stock for CANCELED orders' do
        order.update(status_order: 2)
        item1.reload
        item2.reload
        initial_stock1 = item1.stock
        initial_stock2 = item2.stock
        
        order.restore_stock_on_destroy
        item1.reload
        item2.reload
        
        expect(item1.stock).to eq(initial_stock1)
        expect(item2.stock).to eq(initial_stock2)
      end
    end

    describe '#update_stock_on_status_change' do
      let(:item) { create(:item, stock: 50) }
      let(:order) { create(:order, status_order: 0) }

      before do
        create(:order_detail, order: order, item: item, quantity: 10)
        order.decrease_stock_on_create
      end

      it 'restores stock when changing from NEW to CANCELED' do
        item.reload
        initial_stock = item.stock
        
        order.update_stock_on_status_change(0, 2)
        item.reload
        
        expect(item.stock).to eq(initial_stock + 10)
      end

      it 'restores stock when changing from PAID to CANCELED' do
        order.update(status_order: 1)
        item.reload
        initial_stock = item.stock
        
        order.update_stock_on_status_change(1, 2)
        item.reload
        
        expect(item.stock).to eq(initial_stock + 10)
      end

      it 'decreases stock when changing from CANCELED to NEW' do
        order.update(status_order: 2)
        order.update_stock_on_status_change(0, 2)
        item.reload
        initial_stock = item.stock
        
        order.update_stock_on_status_change(2, 0)
        item.reload
        
        expect(item.stock).to eq(initial_stock - 10)
      end

      it 'decreases stock when changing from CANCELED to PAID' do
        order.update(status_order: 2)
        order.update_stock_on_status_change(0, 2)
        item.reload
        initial_stock = item.stock
        
        order.update_stock_on_status_change(2, 1)
        item.reload
        
        expect(item.stock).to eq(initial_stock - 10)
      end

      it 'returns false when insufficient stock for CANCELED to NEW/PAID' do
        order.update(status_order: 2)
        order.update_stock_on_status_change(0, 2)
        item.update(stock: 5)
        
        result = order.update_stock_on_status_change(2, 0)
        expect(result).to be false
      end

      it 'does not change stock when status change does not affect stock' do
        item.reload
        initial_stock = item.stock
        
        order.update_stock_on_status_change(0, 1)
        item.reload
        
        expect(item.stock).to eq(initial_stock)
      end
    end

  end

end
