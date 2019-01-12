class LccnRecord < ApplicationRecord
  belongs_to :manifestation
  validates :body, presence: true, uniqueness: true
end
