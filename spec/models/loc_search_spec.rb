require "spec_helper"

describe LocSearch do
  fixtures :all

  context ".import_from_sru_response" do
    it "should create a valid manifestation", :vcr => true do
      manifestation = LocSearch.import_from_sru_response( "2007012024" )
      expect( manifestation.manifestation_identifier ).to eq("14780655")
      expect( manifestation.original_title ).to eq( "Everything is miscellaneous : the power of the new digital disorder" )
    end
  end
end
