class FastbillAPI
  require 'fastbill-automatic'

  def initialize bt = nil
    if @bt = bt
      @seller  = bt.seller
      @article = bt.article
    end
  end

  # fastbill_fee
  # fastbill_fair
  # fastbill_discount
  # fastbill_refund_fee
  # fastbill_refund_fair
  # Why has this to be split up into fee and fair all the time?
  [:fee, :fair, :discount, :refund_fee, :refund_fair].each do |type|
    define_method "fastbill_#{ type }" do
      unless @bt.send("billed_for_#{ type }")
        Fastbill::Automatic::Subscription.setusagedata(
          subscription_id: @seller.fastbill_subscription_id,
          article_number: article_number_for(type),
          quantity: quantity_for(type),
          unit_price: unit_price_for(type),
          description: description_for(type),
          usage_date: @bt.sold_at.strftime('%Y-%m-%d %H:%M:%S')
        )
        @bt.send("billed_for_#{ type }=", true)
        @bt.save
      end
    end
  end

  private

  def description_for type
    if type == :discount
      "#{ @bt.id } #{ @article.title } (#{ @bt.discount_title })"
    else
      "#{ @bt.id } #{ @article.title } (#{ I18n.t('invoice.' + type.to_s) })"
    end
  end

  def quantity_for type
    if type == :discount
      '1'
    else
      @bt.quantity_bought
    end
  end

  def article_number_for type
    if type == :fair || type == :refund_fair
      11
    elsif type == :fee || type == :refund_fee
      12
    else
      nil
    end
  end

  def unit_price_for type
    case type
    when :fee
      fee_wo_vat
    when :fair
      fair_wo_vat
    when :discount
      discount_wo_vat
    when :refund_fee
      0 - actual_fee_wo_vat
    when :refund_fair
      0 - fair_wo_vat
    end
  end

  # These methods honestly don't belong in this class!!
  # This method calculates the fair percent fee without vat
  def fair_wo_vat
    (@article.calculated_fair_cents.to_f / 100 / 1.19).round(2)
  end

  # This method calculates the fee without vat
  def fee_wo_vat
    (@article.calculated_fee_cents.to_f / 100 / 1.19).round(2)
  end

  # This method calculates the discount without vat
  def discount_wo_vat
    0 - (@bt.discount_value_cents.to_f / 100 / 1.19).round(2)
  end

  # This method calculates the fee without the discount (without vat)
  def actual_fee_wo_vat
    fee = fee_wo_vat
    fee -= discount_wo_vat if @bt.discount
    fee
  end
end
