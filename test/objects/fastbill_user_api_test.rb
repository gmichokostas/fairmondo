require_relative '../test_helper'

describe FastbillUserAPI do
  let(:user) { FactoryGirl.create(:legal_entity, :paypal_data) }
  let(:api) { FastbillUserAPI.new user }

  describe 'customer administration' do
    # not perfect, result codes are needed from Fastbill, but are there any?
    # can't really test fastbill_delete_customer either
    # but it could be tested by looking at the VCR tapes

    it 'should be able to create a customer from Fastbill' do
      VCR.use_cassette('fastbill/create_customer', record: :none) do
        customer_id = api.fastbill_create_customer
        assert_kind_of(Fixnum, customer_id)

        # teardown
        user.fastbill_id = customer_id
        api.fastbill_delete_customer
      end
    end

    it 'should be able to update a customer at Fastbill' do
      VCR.use_cassette('fastbill/update_customer', record: :none) do
        # setup
        user.fastbill_id = api.fastbill_create_customer

        # user's address changes
        user.standard_address.address_line_1 = 'Dammtorstr. 1'
        user.standard_address.address_line_2 = ''
        user.standard_address.zip   = '20095'
        user.standard_address.city  = 'Hamburg'
        api.fastbill_update_customer

        # teardown
        api.fastbill_delete_customer
      end
    end
  end

  describe 'subscription administration' do
    it 'should be able to create a subscription from Fastbill' do
      VCR.use_cassette('fastbill/create_subscription', record: :none) do
        # setup
        user.fastbill_id = api.fastbill_create_customer

        subscription_id = api.fastbill_create_subscription
        assert_kind_of(Fixnum, subscription_id)

        # teardown
        api.fastbill_delete_customer
      end
    end
  end
end
