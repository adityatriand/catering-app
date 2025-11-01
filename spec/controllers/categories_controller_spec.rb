require 'rails_helper'

RSpec.describe CategoriesController, type: :controller do

  describe 'GET #index' do
    it "populates an array of all categories" do
      category1 = create(:category, name: "Main Dishes")
      category2 = create(:category, name: "Desserts")
      get :index
      expect(assigns(:categories).to_a).to include(category1, category2)
    end

    it "renders the :index template" do
      get :index
      expect(response).to render_template :index
    end
  end

  describe 'GET #new' do
    it "assigns a new category to @category" do
      get :new
      expect(assigns(:category)).to be_a_new(Category)
    end

    it "renders the :new template" do
      get :new
      expect(response).to render_template :new
    end
  end

  describe 'GET #edit' do
    it "assigns the requested category to @category" do
      category = create(:category)
      get :edit, params: { id: category }
      expect(assigns(:category)).to eq category
    end

    it "renders the :edit template" do
      category = create(:category)
      get :edit, params: { id: category }
      expect(response).to render_template :edit
    end
  end

  describe 'POST #create' do
    context "with valid attributes" do
      it "saves the new category in the database" do
        expect{
          post :create, params: { category: attributes_for(:category) }
        }.to change(Category, :count).by(1)
      end

      it "redirects to categories#index" do
        post :create, params: { category: attributes_for(:category) }
        expect(response).to redirect_to(categories_url)
      end
    end

    context "with invalid attributes" do
      it "does not save the new category in the database" do
        expect{
          post :create, params: { category: { name: nil } }
        }.not_to change(Category, :count)
      end

      it "re-renders the :new template" do
        post :create, params: { category: { name: nil } }
        expect(response).to render_template :new
      end
    end
  end

  describe 'PATCH #update' do
    before :each do
      @category = create(:category)
    end

    context "with valid attributes" do
      it "locates the requested @category" do
        patch :update, params: { id: @category, category: attributes_for(:category) }
        expect(assigns(:category)).to eq @category
      end

      it "changes @category's attributes" do
        patch :update, params: { id: @category, category: attributes_for(:category, name: 'Updated Category') }
        @category.reload
        expect(@category.name).to eq('Updated Category')
      end

      it "redirects to categories#index" do
        patch :update, params: { id: @category, category: attributes_for(:category) }
        expect(response).to redirect_to categories_url
      end
    end

    context "with invalid attributes" do
      it "does not update the category in the database" do
        original_name = @category.name
        patch :update, params: { id: @category, category: { name: nil } }
        @category.reload
        expect(@category.name).to eq(original_name)
      end

      it "re-renders the :edit template" do
        patch :update, params: { id: @category, category: { name: nil } }
        expect(response).to render_template :edit
      end
    end
  end

  describe 'DELETE #destroy' do
    before :each do
      @category = create(:category)
    end

    it "deletes the category from the database" do
      expect{
        delete :destroy, params: { id: @category }
      }.to change(Category, :count).by(-1)
    end

    it "redirects to categories#index" do
      delete :destroy, params: { id: @category }
      expect(response).to redirect_to categories_url
    end
  end

end

