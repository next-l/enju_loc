require "spec_helper"
#require "rails_helper"

describe LocSearch do
  context ".import_from_sru_response" do
    it "should create a valid manifestation", :vcr => true do
      manifestation = LocSearch.import_from_sru_response( "2007012024" )
      expect( manifestation.manifestation_identifier ).to eq("14780655")
    end
  end
end
