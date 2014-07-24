class LineItemGroup < ActiveRecord::Base
  extend Sanitization

  belongs_to :seller, class_name: 'User', foreign_key: 'seller_id', inverse_of: :seller_line_item_groups
  belongs_to :buyer, class_name: 'User', foreign_key: 'buyer_id', inverse_of: :buyer_line_item_groups
  belongs_to :cart, inverse_of: :line_item_groups
  has_many :line_items, dependent: :destroy, inverse_of: :line_item_group
  has_many :articles, through: :line_items
  has_many :business_transactions, inverse_of: :line_item_group
  has_many :payments, through: :business_transactions, inverse_of: :line_item_groups
  belongs_to :transport_address, class_name: 'Address', foreign_key: 'transport_address_id'
  belongs_to :payment_address, class_name: 'Address', foreign_key: 'payment_address_id'
  has_one :rating

  delegate :email, :bank_account_owner, :iban, :bic, :bank_name, :nickname,
           to: :seller, prefix: true

  delegate :email, :nickname,
           to: :buyer, prefix: true
  delegate :value, to: :rating, prefix: true

  auto_sanitize :message

  with_options if: :has_business_transactions? do |bt|
    bt.validates :unified_payment_method, inclusion: { in: proc { |record| record.unified_payments_selectable } }, common_sense: true, presence: true, if: :payment_can_be_unified?

    bt.validates :tos_accepted, acceptance: { allow_nil: false, accept: true }

    bt.validates_each :unified_transport, :unified_payment do |record, attr, value|
      record.errors.add(attr, 'not allowed') if value && !can_be_unified_for?(record,attr)
    end
    bt.validates :transport_address, :payment_address, :buyer, :seller, presence: true
  end

  def transport_can_be_unified?
    articles_with_unified_transport_count = self.line_items.joins(:article).where("articles.unified_transport = ?", true ).count
    @transport_can_be_unified ||= (articles_with_unified_transport_count >= 2)
  end

  def payment_can_be_unified?
     self.articles.count > 1 && unified_payments_selectable.any?
  end

  def unified_payments_selectable
    @unified_payments_selectable ||= ( self.line_items.map{|l| l.article.selectable_payments}.inject(:&) || [] ) #intersection of selectable_payments
  end

  def total_price
    price = Money.new(0)
    self.business_transactions.each do |bt|
      price += bt.total_price
    end
    price
  end

  def self.exportable_attributes
    ['line_item_group_id', 'line_item_group_created_at', 'business_transaction_id', 'business_transaction_quantity_bought', 'article_id', 'article_title', 'article_custom_seller_identifier']
  end

  def export_attrs
    ['id', 'created_at']
  end

  def self.export_mappings
    hash = {}
    column_names.each { |element| hash[element] = "#{name.underscore}_#{element}"}
    return hash
  end

  private
    def self.can_be_unified_for? record, type
      if type == :unified_transport
        record.transport_can_be_unified?
      elsif type == :unified_payment
        record.payment_can_be_unified?
      end
    end

    def has_business_transactions?
      self.business_transactions.any?
    end

end
