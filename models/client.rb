require_relative '../config/environment.rb'

class Client < ActiveRecord::Base
  has_many :messages
  validates :first_name, presence: true
  validates :phone_number, presence: true

  def formatted_phone
    digits = phone_number.split('')
    "(#{digits[0..2].join('')}) #{digits[3..5].join('')}-#{digits[6..10].join('')}"
  end

  def unread_messages
    messages.where(read_at: nil).count > 0
  end
end
