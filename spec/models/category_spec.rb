require 'rails_helper'

RSpec.describe Category, type: :model do
  subject(:category) {
    Category.new(
      name: 'Makanan Utama'
    )
  }

  context 'validation for all field' do
    
    it 'is valid with a name' do
      expect(category).to be_valid
    end
    
  end

  context 'validation for name field' do
    
    it 'is invalid without a name' do
      category.name = nil
      category.valid?
      expect(category.errors[:name]).to include("can't be blank")
    end

    it 'is valid with a name' do
      category.name = 'Desserts'
      expect(category).to be_valid
    end
    
  end

end
