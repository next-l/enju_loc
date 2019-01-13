class LccnRecord < ApplicationRecord
  belongs_to :manifestation
  validates :body, presence: true, uniqueness: true
end

# == Schema Information
#
# Table name: lccn_records
#
#  id               :bigint(8)        not null, primary key
#  body             :string           not null
#  manifestation_id :bigint(8)        not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#