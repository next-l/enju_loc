require "spec_helper"

describe LocSearch do
  fixtures :all

  context ".import_from_sru_response" do
    it "should create a valid manifestation", :vcr => true do
      manifestation = LocSearch.import_from_sru_response( "2007012024" )
      expect( manifestation.manifestation_identifier ).to eq("14780655")
      expect( manifestation.original_title ).to eq( "Everything is miscellaneous : the power of the new digital disorder" )
      expect( manifestation.manifestation_content_type.name ).to eq "text"
      expect( manifestation.carrier_type.name ).to eq "print"
      expect( manifestation.publishers.size ).to eq 1
      expect( manifestation.publishers.first.full_name ).to eq "Times Books"
      expect( manifestation.edition_string ).to eq "1st ed."
      expect( manifestation.language.iso_639_2 ).to eq "eng"
      expect( manifestation.start_page ).to eq 1
      expect( manifestation.end_page ).to eq 277
      expect( manifestation.height ).to eq 25
      expect( manifestation.statement_of_responsibility ).to eq "David Weinberger."
      expect( manifestation.subjects.size ).to eq 6
      expect( manifestation.subjects.first.subject_heading_type.name ).to eq "lcsh"
      expect( manifestation.subjects.first.subject_type.name ).to eq "concept"
      RSpec.describe manifestation.subjects.collect( &:term ) do
        it { is_expected.to include( "Knowledge management" ) }
        it { is_expected.to include( "Information technology--Management" ) }
        it { is_expected.to include( "Information technology--Social aspects" ) }
        it { is_expected.to include( "Personal information management" ) }
        it { is_expected.to include( "Information resources management" ) }
        it { is_expected.to include( "Order" ) }
      end
      expect( manifestation.classifications.size ).to eq 1
      classification = manifestation.classifications.first
      expect( classification.classification_type.name ).to eq "ddc"
      expect( classification.category ).to eq "303.48"
      expect( manifestation.identifier_contents("isbn").first ).to eq "9780805080438"
      expect( manifestation.identifier_contents("lccn").first ).to eq "2007012024"
    end
  end
end
