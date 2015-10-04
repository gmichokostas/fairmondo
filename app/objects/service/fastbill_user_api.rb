class FastbillUserAPI
  require 'fastbill-automatic'

  def initialize user
    @user = user
  end

  # Returns Fastbill customer id
  def fastbill_create_customer
    Fastbill::Automatic::Customer.create(customer_attributes).customer_id
  end

  # Updates existing profile
  def fastbill_update_customer
    customer = Fastbill::Automatic::Customer.get(customer_id: @user.fastbill_id).first
    customer.update_attributes(customer_attributes) if customer
  end

  # Deletes Fastbill profile
  def fastbill_delete_customer
    if @user.fastbill_id
      Fastbill::Automatic::Customer.delete(@user.fastbill_id.to_s)
    end
  end

  # Returns subscription id
  def fastbill_create_subscription
    unless @user.fastbill_subscription_id
      subscription = Fastbill::Automatic::Subscription.create(
        article_number: '10',
        customer_id: @user.fastbill_id,
        next_event: Time.now.end_of_month.strftime('%Y-%m-%d %H:%M:%S')
      )
      subscription.subscription_id
    end
  end

  private

  def customer_attributes
    attributes = {
      customer_type: 'business',
      organization: @user.standard_address_company_name.present? ?
                    @user.standard_address_company_name : @user.nickname,
      salutation: @user.standard_address_title,
      first_name: @user.standard_address_first_name,
      last_name: @user.standard_address_last_name,
      address: @user.standard_address_address_line_1,
      address_2: @user.standard_address_address_line_2,
      zipcode: @user.standard_address_zip,
      city: @user.standard_address_city,
      country_code: 'DE',
      language_code: 'DE',
      email: @user.email,
      currency_code: 'EUR',
      payment_type: '1', # bank transfer
      # payment_type: '2', # direct debit - please activate as soon as approval of the bank is available
      show_payment_notice: '1',
      bank_name: @user.bank_name,
      bank_code: @user.bank_code,
      bank_account_number: @user.bank_account_number,
      bank_account_owner: @user.bank_account_owner
    }
    if @user.fastbill_id
      attributes[:customer_id] = @user.fastbill_id
    else
      attributes[:customer_number] = @user.id
    end
    attributes
  end
end
