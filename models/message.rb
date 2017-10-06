require_relative '../config/environment.rb'

class Message < ActiveRecord::Base
  belongs_to :client
  validates :text, presence: true
  validates :client_id, presence: true

  def sender
    outbound ? "CNYCN" : client.first_name
  end

  def styled_time
    time = Time.now.dst? ? created_at + 1.hour : created_at
    time.in_time_zone('EST').strftime("%l:%M %P")
  end

  def date
    created_at.in_time_zone('EST').strftime("%B %-d, %Y")
  end
end
