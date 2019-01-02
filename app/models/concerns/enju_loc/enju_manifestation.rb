module EnjuLoc
  module EnjuManifestation
    extend ActiveSupport::Concern

    included do
      has_one :lccn_record_and_manifestation
      has_one :lccn_record, through: :lccn_record_and_manifestation
    end
  end
end

