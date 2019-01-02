class LccnRecord < ApplicationRecord
  has_many :lccn_record_and_manifestations
  has_many :manifestations, through: :lccn_record_and_manifestations
end

# == Schema Information
#
# Table name: lccn_records
#
#  id         :bigint(8)        not null, primary key
#  body       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
