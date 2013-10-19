require "enju_loc/engine"
require "enju_loc/loc_search.rb"

module EnjuLoc
  module ActsAsMethods
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def enju_loc_search
        include EnjuLoc::LocSearch
      end
    end
  end

  class RecordNotFound < StandardError; end
end
