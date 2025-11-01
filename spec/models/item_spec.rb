require 'rails_helper'

RSpec.describe Item, type: :model do
  subject(:item) {
    Item.new(
      name: 'Nasi Uduk',
      description: 'Betawi style steamed rice cooked in coconut milk. Delicious!',
      price: 15000.0,
      stock: 50
    )
  }

  context 'validation for all field' do
    
    it 'is valid with a name, a description, a price, and stock' do
      expect(item).to be_valid
    end

  end

  context 'validation for name field' do
    
    it 'is invalid without a name' do
      item.name = nil
      item.valid?
      expect(item.errors[:name]).to include("can't be blank")
    end

    it "is invalid with a duplicate name" do 
      item1 = Item.create(
        name: "Nasi Uduk",
        description: "Betawi style steamed rice cooked in coconut milk. Delicious!",
        price: 10000.0,
        stock: 50
      )
      
      item2 = Item.new(
        name: "Nasi Uduk",
        description: "Just with a different description.",
        price: 10000.0,
        stock: 30
      )
  
      item2.valid?
      
      expect(item2.errors[:name]).to include("has already been taken")
    end
    
  end

  context 'validation for description field' do
    
    it 'is invalid without a description' do
      item.description = nil
      item.valid?
      expect(item.errors[:description]).to include("can't be blank")
    end

    it 'is invalid if description more than 150 character' do
      item.description = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Curabitur ante magna, rutrum in euismod non, porta et elit. Sed ac quam lorem. Duis quis sed Lorem."
      item.valid?
      expect(item.errors[:description]).to include("150 characters is the maximum allowed")
    end
    
  end

  context 'validation for price field' do
    
    it 'is invalid if accept non numeric values for price field' do
      item.price = "10s"
      item.valid?
      expect(item.errors[:price]).to include("is not a number")
    end

    it 'is invalid if price less than 0.01' do
      item.price = 0
      item.valid?
      expect(item.errors[:price]).to include("must be greater than or equal to 0.01")
    end
    
  end

  context 'validation for stock field' do
    
    it 'is invalid without stock' do
      item.stock = nil
      item.valid?
      expect(item.errors[:stock]).to include("can't be blank")
    end

    it 'is invalid if stock is negative' do
      item.stock = -1
      item.valid?
      expect(item.errors[:stock]).to include("must be greater than or equal to 0")
    end

    it 'is valid with stock of 0' do
      item.stock = 0
      expect(item).to be_valid
    end
    
  end

  context 'stock management methods' do
    
    describe '#in_stock?' do
      it 'returns true when stock is greater than 0' do
        item.stock = 10
        expect(item.in_stock?).to be true
      end

      it 'returns false when stock is 0' do
        item.stock = 0
        expect(item.in_stock?).to be false
      end
    end

    describe '#has_stock?' do
      before do
        item.stock = 50
        item.save
      end

      it 'returns true when requested quantity is available' do
        expect(item.has_stock?(30)).to be true
      end

      it 'returns true when requested quantity equals stock' do
        expect(item.has_stock?(50)).to be true
      end

      it 'returns false when requested quantity exceeds stock' do
        expect(item.has_stock?(51)).to be false
      end
    end

    describe '#decrease_stock' do
      before do
        item.stock = 50
        item.save
      end

      it 'decreases stock by the specified quantity' do
        item.decrease_stock(10)
        item.reload
        expect(item.stock).to eq(40)
      end

      it 'saves the item after decreasing stock' do
        item.decrease_stock(5)
        item.reload
        expect(item.stock).to eq(45)
      end
    end

    describe '#increase_stock' do
      before do
        item.stock = 50
        item.save
      end

      it 'increases stock by the specified quantity' do
        item.increase_stock(10)
        item.reload
        expect(item.stock).to eq(60)
      end

      it 'saves the item after increasing stock' do
        item.increase_stock(5)
        item.reload
        expect(item.stock).to eq(55)
      end
    end
    
  end

end
