#   Copyright (c) 2012-2015, Fairmondo eG.  This file is
#   licensed under the GNU Affero General Public License version 3 or later.
#   See the COPYRIGHT file for details.

require_relative '../test_helper'

describe CategoriesController do
  let(:category) { FactoryGirl.create(:category) }

  describe 'GET ::index' do
    describe 'for non-signed-in users' do
      it 'should allow access and show some categories' do
        get :index
        assert_response :success
      end
    end

    describe "GET 'id_index'" do
      it 'should allow access and show some categories' do
        get :id_index
        assert_response :success
      end
    end
  end

  describe 'GET select_category' do
    it 'should allow to select a category' do
      get :select_category, id: category.id, object_name: 'article'
      assert_response :success
    end
  end

  describe "GET 'show'" do
    it 'should show a category when format is html' do
      get :show, id: category.id
      assert_response :success
    end

    it 'should show a category when format is json' do
      get :show, id: category.id, format: :json
      assert_response :success
    end

    it 'should rescue an Faraday::ConnectionFailed error' do
      Chewy::Query.any_instance.stubs(:to_a).raises(Faraday::ConnectionFailed.new('test'))
      get :show, id: category.id, article_search_form: { q: 'foobar' }
      assert_response :success
    end

    it 'should rescue an Faraday::TimeoutError error' do
      Chewy::Query.any_instance.stubs(:to_a).raises(Faraday::TimeoutError.new('test'))
      get :show, id: category.id, article_search_form: { q: 'foobar' }
      assert_response :success
    end

    it 'should rescue an Faraday::ClientError error' do
      Chewy::Query.any_instance.stubs(:to_a).raises(Faraday::ClientError.new('test'))
      get :show, id: category.id, article_search_form: { q: 'foobar' }
      assert_response :success
    end

    describe 'search' do
      setup do
        ArticlesIndex.reset!
        @electronic_category = Category.find_by_name!('Elektronik')
        @hardware_category = Category.find_by_name!('Hardware')
        @software_category = Category.find_by_name!('Software')

        @ngo_article = FactoryGirl.create(:article, :index_article, price_cents: 1, title: 'ngo article thing', content: 'super thing', created_at: 4.days.ago)
        @second_hand_article = FactoryGirl.create(:second_hand_article, :index_article, price_cents: 2, title: 'muscheln', categories: [@software_category], content: 'muscheln am meer', created_at: 3.days.ago)
        @hardware_article = FactoryGirl.create(:second_hand_article, :index_article, :simple_fair, :simple_ecologic, :simple_small_and_precious, :with_ngo, price_cents: 3, title: 'muscheln 2', categories: [@hardware_category], content: 'abc', created_at: 2.days.ago)
        @no_second_hand_article = FactoryGirl.create :no_second_hand_article, :index_article, price_cents: 4, title: 'muscheln 3', categories: [@hardware_category], content: 'cde'
      end

      it "should find the article in category 'Hardware' when filtering for 'Hardware'" do
        get :show, id: @hardware_category.id
        @controller.instance_variable_get(:@articles).map { |a| a.id.to_i }.sort.must_equal [@no_second_hand_article, @hardware_article].map(&:id).sort
      end

      it "should find the article in category 'Hardware' when filtering for the ancestor 'Elektronik'" do
        get :show, id: @electronic_category.id
        @controller.instance_variable_get(:@articles).map { |a| a.id.to_i }.sort.must_equal [@no_second_hand_article, @hardware_article, @second_hand_article].map(&:id).sort
      end

      it 'should ignore the category_id field and always search in the given category' do
        get :show, id: @hardware_category.id, article_search_form: { category_id: @software_category.id }
        @controller.instance_variable_get(:@articles).map { |a| a.id.to_i }.sort.must_equal [@no_second_hand_article, @hardware_article].map(&:id).sort
      end

      context "and searching for 'muscheln'" do
        it 'should chain both filters' do
          get :show, id: @hardware_category.id, article_search_form: { q: 'muscheln' }
          @controller.instance_variable_get(:@articles).map { |a| a.id.to_i }.sort.must_equal [@hardware_article, @no_second_hand_article].map(&:id).sort
        end

        context 'and filtering for condition' do
          it 'should chain all filters' do
            get :show, id: @hardware_category.id, article_search_form: { q: 'muscheln', condition: :old }
            @controller.instance_variable_get(:@articles).map { |a| a.id.to_i }.must_equal [@hardware_article].map(&:id)
          end
        end
      end
    end
  end
end
