require_relative '../test_helper'
require 'httplog'

describe FastbillAPI do
  describe 'methods' do
    let(:seller) { FactoryGirl.create(:legal_entity, :paypal_data) }
    let(:business_transaction) { BusinessTransaction.new }
    let(:db_business_transaction) { FactoryGirl.create(:business_transaction, seller: seller) }

    describe '::fastbill_chain' do
      it 'should find seller of transaction' do
        api = FastbillAPI.new db_business_transaction
        api.instance_eval('@seller').must_equal seller
      end

      describe 'when seller is an NGO' do
        it 'should not contact Fastbill' do
          stub_post = stub_request(:post, "https://my_email:my_fastbill_api_key@automatic.fastbill.com/api/1.0/api.php")

          user = FactoryGirl.create(:legal_entity, :ngo, :paypal_data)
          bt = FactoryGirl.create(:business_transaction, seller: user)

          api = FastbillAPI.new bt

          api.fastbill_chain
          assert_not_requested(stub_post)
        end
      end

      describe 'when seller is a private user' do
        it 'should not contact Fastbill' do
          stub_post = stub_request(:post, "https://my_email:my_fastbill_api_key@automatic.fastbill.com/api/1.0/api.php")

          user = FactoryGirl.create(:private_user, :paypal_data)
          bt = FactoryGirl.create(:business_transaction, seller: user)

          api = FastbillAPI.new bt

          api.fastbill_chain
          assert_not_requested(stub_post)
        end
      end


      describe 'when seller is not an NGO' do
        describe 'and has Fastbill profile' do
          it 'should not create new Fastbill profile' do
            stub_post = stub_request(:post, "https://my_email:my_fastbill_api_key@automatic.fastbill.com/api/1.0/api.php")

            db_business_transaction # to trigger observers before
            seller.update_attributes(fastbill_id: '1234',
                                     fastbill_subscription_id: '4321')
            api = FastbillAPI.new db_business_transaction
            api.expects(:fastbill_create_customer).never
            api.expects(:fastbill_create_subscription).never
            api.fastbill_chain
          end
        end

        describe 'and has no Fastbill profile' do
          let(:db_business_transaction) { FactoryGirl.create :business_transaction, :clear_fastbill }
          it 'should create new Fastbill profile' do
            stub_post = stub_request(:post, "https://my_email:my_fastbill_api_key@automatic.fastbill.com/api/1.0/api.php")

            db_business_transaction # to trigger observers before
            api = FastbillAPI.new db_business_transaction
            api.expects(:fastbill_create_customer)
            api.expects(:fastbill_create_subscription)
            api.fastbill_chain
          end
        end

        it 'should set usage data for subscription' do
          stub_post = stub_request(:post, "https://my_email:my_fastbill_api_key@automatic.fastbill.com/api/1.0/api.php")

          db_business_transaction # to trigger observers before
          api = FastbillAPI.new db_business_transaction
          Fastbill::Automatic::Subscription.expects(:setusagedata).twice
          api.fastbill_chain
        end
      end

      describe 'article price is 0 Euro' do
        let(:article) { FactoryGirl.create :article, price: Money.new(0) }
        it 'should not call FastbillAPI' do
          api = FastbillAPI.new
          api.expects(:fastbill_chain).never
          FactoryGirl.create :business_transaction, article: article
        end
      end
    end

    describe '::fastbill_discount' do
      it 'should call setusagedata' do
        db_business_transaction # to trigger observers before
        Fastbill::Automatic::Subscription.expects(:setusagedata)
        db_business_transaction.discount = FactoryGirl.create :discount
        api = FastbillAPI.new db_business_transaction
        api.send :fastbill_discount
      end
    end

    describe '::fastbill_refund' do
      it 'should call setusagedata' do
        db_business_transaction # to trigger observers before
        Fastbill::Automatic::Subscription.expects(:setusagedata).twice
        api = FastbillAPI.new db_business_transaction
        api.send :fastbill_refund_fair
        api.send :fastbill_refund_fee
      end
    end

    # describe '::update_profile' do
    #   it 'should call setusagedata' do
    #     Fastbill::Automatic::Customer.expects( :get )
    #     FastbillAPI.update_profile( seller )
    #   end
    # end

    describe '::discount_wo_vat' do
      it 'should receive call' do
        stub_request(:post, "https://my_email:my_fastbill_api_key@automatic.fastbill.com/api/1.0/api.php")
          .to_return(:status => 200, :body => "", :headers => {})

        db_business_transaction.discount = FactoryGirl.create :discount
        api = FastbillAPI.new db_business_transaction
        api.expects(:discount_wo_vat)
        api.fastbill_chain
      end
    end

    describe 'refund' do
      it 'should receive call' do
        FastbillAPI.any_instance.expects(:fastbill_refund_fair)
        FastbillAPI.any_instance.expects(:fastbill_refund_fee)
        FastbillRefundWorker.perform_async(db_business_transaction.id)
      end
    end
  end
end
