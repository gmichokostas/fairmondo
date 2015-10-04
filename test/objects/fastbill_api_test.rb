require_relative '../test_helper'

describe FastbillAPI do
  let(:seller) { FactoryGirl.create(:legal_entity, :paypal_data) }
  let(:business_transaction) { BusinessTransaction.new }
  let(:db_business_transaction) { FactoryGirl.create(:business_transaction, seller: seller) }

  describe '#fastbill_fee' do
  end

  describe '#fastbill_fair' do
  end

  describe '#fastbill_discount' do
  end

  describe '#fastbill_refund_fee' do
  end

  describe '#fastbill_refund_fair' do
  end
end
