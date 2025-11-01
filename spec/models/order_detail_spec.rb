require 'rails_helper'

RSpec.describe OrderDetail, type: :model do
  let(:item) { create(:item, stock: 50, price: 15000.0) }
  let(:order) { create(:order) }
  let(:order_detail) { create(:order_detail, order: order, item: item, quantity: 5, price: 15000.0) }

  context 'associations' do
    it 'belongs to an order' do
      expect(order_detail.order).to eq(order)
    end

    it 'belongs to an item' do
      expect(order_detail.item).to eq(item)
    end
  end

  context 'validations' do
    it 'is valid with valid attributes' do
      expect(order_detail).to be_valid
    end
  end

  context 'class methods' do
    describe '.update_item_order' do
      context 'when creating a new order detail' do
        let(:new_order) { create(:order, status_order: 0) }
        let(:new_item) { create(:item, stock: 50, price: 10000.0) }

        it 'creates a new order detail' do
          expect {
            OrderDetail.update_item_order(new_order.id, new_item.id, 10)
          }.to change(OrderDetail, :count).by(1)
        end

        it 'decreases stock when order status is NEW' do
          initial_stock = new_item.stock
          OrderDetail.update_item_order(new_order.id, new_item.id, 10)
          new_item.reload
          expect(new_item.stock).to eq(initial_stock - 10)
        end

        it 'decreases stock when order status is PAID' do
          new_order.update(status_order: 1)
          initial_stock = new_item.stock
          OrderDetail.update_item_order(new_order.id, new_item.id, 10)
          new_item.reload
          expect(new_item.stock).to eq(initial_stock - 10)
        end

        it 'does not decrease stock when order status is CANCELED' do
          new_order.update(status_order: 2)
          initial_stock = new_item.stock
          OrderDetail.update_item_order(new_order.id, new_item.id, 10)
          new_item.reload
          expect(new_item.stock).to eq(initial_stock)
        end

        it 'returns false when insufficient stock' do
          new_item.update(stock: 5)
          result = OrderDetail.update_item_order(new_order.id, new_item.id, 10)
          expect(result).to be false
        end

        it 'does not decrease stock when quantity is 0' do
          initial_stock = new_item.stock
          OrderDetail.update_item_order(new_order.id, new_item.id, 0)
          new_item.reload
          expect(new_item.stock).to eq(initial_stock)
        end

        it 'updates order total price' do
          expect(Order).to receive(:update_total_price).with(new_order.id)
          OrderDetail.update_item_order(new_order.id, new_item.id, 10)
        end
      end

      context 'when updating an existing order detail' do
        let(:existing_order) { create(:order, status_order: 0) }
        let(:existing_item) { create(:item, stock: 50, price: 10000.0) }
        let!(:existing_detail) { create(:order_detail, order: existing_order, item: existing_item, quantity: 5) }

        before do
          existing_order.decrease_stock_on_create
        end

        it 'updates quantity when changed' do
          OrderDetail.update_item_order(existing_order.id, existing_item.id, 8)
          existing_detail.reload
          expect(existing_detail.quantity).to eq(8)
        end

        it 'decreases stock when quantity increases' do
          existing_item.reload
          initial_stock = existing_item.stock
          OrderDetail.update_item_order(existing_order.id, existing_item.id, 8)
          existing_item.reload
          expect(existing_item.stock).to eq(initial_stock - 3)
        end

        it 'increases stock when quantity decreases' do
          existing_item.reload
          initial_stock = existing_item.stock
          OrderDetail.update_item_order(existing_order.id, existing_item.id, 3)
          existing_item.reload
          expect(existing_item.stock).to eq(initial_stock + 2)
        end

        it 'restores stock and deletes detail when quantity is 0' do
          existing_item.reload
          initial_stock = existing_item.stock
          OrderDetail.update_item_order(existing_order.id, existing_item.id, 0)
          existing_item.reload
          expect(existing_item.stock).to eq(initial_stock + 5)
          expect(OrderDetail.find_by(id: existing_detail.id)).to be_nil
        end

        it 'returns false when insufficient stock for increase' do
          existing_item.update(stock: 2)
          result = OrderDetail.update_item_order(existing_order.id, existing_item.id, 10)
          expect(result).to be false
        end

        it 'does not change stock when order is CANCELED' do
          existing_order.update(status_order: 2)
          existing_item.reload
          initial_stock = existing_item.stock
          OrderDetail.update_item_order(existing_order.id, existing_item.id, 8)
          existing_item.reload
          expect(existing_item.stock).to eq(initial_stock)
        end

        it 'does not change detail when quantity is the same' do
          expect {
            OrderDetail.update_item_order(existing_order.id, existing_item.id, 5)
          }.not_to change { existing_detail.reload.quantity }
        end
      end
    end

    describe '.destory_order_detail' do
      let(:test_order) { create(:order) }
      let(:test_item) { create(:item) }
      let!(:test_detail) { create(:order_detail, order: test_order, item: test_item) }

      it 'destroys the order detail' do
        expect {
          OrderDetail.destory_order_detail(test_order.id, test_item.id)
        }.to change(OrderDetail, :count).by(-1)
      end

      it 'does not raise error when order detail does not exist' do
        expect {
          OrderDetail.destory_order_detail(999, 999)
        }.not_to raise_error
      end
    end
  end

end
