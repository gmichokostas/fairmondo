require_relative '../test_helper'

describe FastbillRefundWorker do
  describe 'Fastbill interaction' do
    let(:seller) { FactoryGirl.create(:legal_entity, :paypal_data) }
    let(:db_business_transaction) { FactoryGirl.create(:business_transaction, seller: seller) }
    let(:fake_api) { stub }

    it 'should call two FastbillAPI methods' do
      fake_api.expects(:fastbill_refund_fee)
      fake_api.expects(:fastbill_refund_fair)
      FastbillAPI.expects(:new).with(db_business_transaction).returns(fake_api)

      FastbillRefundWorker.perform_async(db_business_transaction.id)
    end
  end
end
