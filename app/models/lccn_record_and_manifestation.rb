class LccnRecordAndManifestation < ApplicationRecord
  belongs_to :lccn_record
  belongs_to :manifestation
end

# == Schema Information
#
# Table name: lccn_record_and_manifestations
#
#  id               :bigint(8)        not null, primary key
#  lccn_record_id   :bigint(8)        not null
#  manifestation_id :bigint(8)        not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
