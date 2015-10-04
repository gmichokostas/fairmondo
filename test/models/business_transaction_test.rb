#
#
# == License:
# Fairmondo - Fairmondo is an open-source online marketplace.
# Copyright (C) 2013 Fairmondo eG
#
# This file is part of Fairmondo.
#
# Fairmondo is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# Fairmondo is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Fairmondo.  If not, see <http://www.gnu.org/licenses/>.
#
require_relative '../test_helper'

class BusinessTransactionTest < ActiveSupport::TestCase
  subject { BusinessTransaction.new }
  let(:business_transaction) { FactoryGirl.create :business_transaction }
  describe 'attributes' do
    it { subject.must_respond_to :selected_transport }
    it { subject.must_respond_to :selected_payment }
    it { subject.must_respond_to :id }
    it { subject.must_respond_to :created_at }
    it { subject.must_respond_to :updated_at }
    it { subject.must_respond_to :article_id }
    it { subject.must_respond_to :state }

    it { subject.must_respond_to :sold_at }
    it { subject.must_respond_to :purchase_emails_sent }
    it { subject.must_respond_to :discount_id }
    it { subject.must_respond_to :discount_value_cents }
    it { subject.must_respond_to :billed_for_fair }
    it { subject.must_respond_to :billed_for_fee }
    it { subject.must_respond_to :billed_for_discount }
    it { subject.must_respond_to :refunded_fee }
    it { subject.must_respond_to :refunded_fair }
  end

  describe 'associations' do
    it { subject.must belong_to :article }
    it { subject.must belong_to :line_item_group }
  end

  describe 'enumerization' do # I asked for clarification on how to do this: https://github.com/brainspec/enumerize/issues/136 - maybe comment back in when we have a positive response.
    should enumerize(:selected_transport).in(:pickup, :type1, :type2, :bike_courier)
    should enumerize(:selected_payment).in(:bank_transfer, :cash, :paypal, :cash_on_delivery, :invoice, :voucher)
  end

  describe '#billable?' do
    let(:business_transaction) { FactoryGirl.build_stubbed(:business_transaction) }

    it 'returns true if seller is billable' do
      User.any_instance.stubs(:billable?).returns(true)
      assert_equal true, business_transaction.billable?
    end

    it 'returns false if seller is not billable' do
      User.any_instance.stubs(:billable?).returns(false)
      assert_equal false, business_transaction.billable?
    end

    it 'returns false if article price is 0' do
      article = FactoryGirl.create(:article, price_cents: 0)
      User.any_instance.stubs(:billable?).returns(true)
      bt = FactoryGirl.build_stubbed(:business_transaction, article: article)
      assert_equal false, bt.billable?
    end
  end

  describe '#bill!' do
    let(:seller_with_profile) { FactoryGirl.create(:legal_entity, :fastbill, :paypal_data) }
    let(:seller_wo_profile) { FactoryGirl.create(:legal_entity, :paypal_data) }
    let(:fake_api) { stub(fastbill_fee: nil, fastbill_fair: nil) }
    let(:fake_user_api) { stub(fastbill_create_customer: nil, fastbill_create_subscription: nil) }

    it 'creates a Fastbill profile first if necessary' do
      bt = FactoryGirl.create(:business_transaction, seller: seller_wo_profile)
      # Not really ideal to bring up FastbillUserAPI here?
      FastbillAPI.expects(:new).returns(fake_api)
      FastbillUserAPI.expects(:new).returns(fake_user_api)
      bt.bill!
    end

    it 'does not create a profile if it already exists' do
      bt = FactoryGirl.create(:business_transaction, seller: seller_with_profile)
      seller_with_profile.expects(:create_fastbill_profile!).never
      FastbillAPI.expects(:new).with(bt).returns(fake_api)
      bt.bill!
    end

    it 'does bill if the transaction is billable' do
      bt = FactoryGirl.create(:business_transaction, seller: seller_with_profile)
      fake_api.expects(:fastbill_fee)
      fake_api.expects(:fastbill_fair)
      fake_api.expects(:fastbill_discount).never
      FastbillAPI.expects(:new).with(bt).returns(fake_api)
      bt.bill!
    end

    it 'does bill discount additionally if bt is discounted' do
      discount = FactoryGirl.create(:discount)
      bt = FactoryGirl.create(:business_transaction,
                              seller: seller_with_profile, discount: discount)
      fake_api.expects(:fastbill_fee)
      fake_api.expects(:fastbill_fair)
      fake_api.expects(:fastbill_discount)
      FastbillAPI.expects(:new).with(bt).returns(fake_api)
      bt.bill!
    end

    it 'does not bill if the transaction is not billable' do
      bt = BusinessTransaction.new
      bt.expects(:billable?).once.returns(false)
      FastbillAPI.expects(:new).never
      bt.bill!
    end
  end
end
