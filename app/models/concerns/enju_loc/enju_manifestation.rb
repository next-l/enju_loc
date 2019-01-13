module EnjuLoc
  module EnjuManifestation
    extend ActiveSupport::Concern

    included do
      has_one :lccn_record
      string :lccn do
        lccn_record.try(:body)
      end
    end
  end
end

