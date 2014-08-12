require "spec_helper"

describe LocSearch do
  fixtures :all

  context ".import_from_sru_response" do
    it "should create a valid manifestation", :vcr => true do
      manifestation = LocSearch.import_from_sru_response( "2007012024" )
      expect( manifestation.manifestation_identifier ).to eq "14780655"
      expect( manifestation.original_title ).to eq "Everything is miscellaneous : the power of the new digital disorder"
      expect( manifestation.manifestation_content_type.name ).to eq "text"
      expect( manifestation.carrier_type.name ).to eq "print"
      expect( manifestation.publishers.size ).to eq 1
      expect( manifestation.publishers.first.full_name ).to eq "Times Books"
      expect( manifestation.creators.size ).to eq 1
      expect( manifestation.creators.first.agent_type.name ).to eq "Person"
      expect( manifestation.creators.first.full_name ).to eq "Weinberger, David, 1950-"
      expect( manifestation.edition_string ).to eq "1st ed."
      expect( manifestation.language.iso_639_2 ).to eq "eng"
      expect( manifestation.date_of_publication.year ).to eq 2007
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
    
    it "should parse title information properly" do
      manifestation = LocSearch.import_from_sru_response( "2012532441" )
      expect( manifestation.original_title ).to eq "The data journalism handbook"
      expect( manifestation.title_alternative ).to eq "How journalists can use data to improve the news"
    end

    it "should distinguish title information with subject" do
      m = LocSearch.import_from_sru_response( "2008273186" )
      expect( m.original_title ).to eq "Flexible Rails : Flex 3 on Rails 2"
    end
  end

  context ".make_sru_request_uri" do
    it "should construct a valid uri" do
      url = LocSearch.make_sru_request_uri( "test" )
      uri = URI.parse( url )
      expect( Hash[uri.query.split(/\&/).collect{|e| e.split(/=/) }] ).to eq( {
	"query" => "test", 
	"version" => "1.1",
	"operation" => "searchRetrieve",
	"maximumRecords" => "10",
	"recordSchema" => "mods"
      } )
    end
  end
end
