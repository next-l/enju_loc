module EnjuLoc
  module EnjuManifestation
    extend ActiveSupport::Concern

    included do
      has_one :lccn_record
    end
  end
end

