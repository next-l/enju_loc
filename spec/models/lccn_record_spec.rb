require 'rails_helper'

RSpec.describe LccnRecord, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
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