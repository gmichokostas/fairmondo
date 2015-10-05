require_relative '../test_helper'
require 'email_spec'

describe RefundMailer do
  include EmailSpec::Helpers
  include EmailSpec::Matchers

  it '#refund_notification' do
    # Setup Fastbill API stub
    fake_api = stub(fastbill_refund_fee: nil, fastbill_refund_fair: nil)
    FastbillAPI.stubs(:new).returns(fake_api)

    refund = FactoryGirl.create :refund, reason: 'not_in_stock'
    mail =  RefundMailer.refund_notification(refund)
    mail.must deliver_to('storno@fairmondo.de')
    mail.must have_subject('[Fairmondo] Rueckerstattung: Transationsnummer: ' + "#{refund.business_transaction.id}")
    mail.must have_body_text(refund.business_transaction.id.to_s)
    mail.must have_body_text(refund.reason)
    mail.must have_body_text(refund.description)
  end
end
