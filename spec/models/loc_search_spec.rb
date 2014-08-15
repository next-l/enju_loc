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
      expect( manifestation.publication_place ).to eq "New York"
      expect( manifestation.creators.size ).to eq 1
      expect( manifestation.creators.first.agent_type.name ).to eq "Person"
      expect( manifestation.creators.first.full_name ).to eq "Weinberger, David, 1950-"
      expect( manifestation.edition_string ).to eq "1st ed."
      expect( manifestation.language.iso_639_2 ).to eq "eng"
      expect( manifestation.date_of_publication.year ).to eq 2007
      expect( manifestation.start_page ).to eq 1
      expect( manifestation.end_page ).to eq 277
      expect( manifestation.height ).to eq 25
      expect( manifestation.note ).to eq "Includes bibliographical references (p. [235]-257) and index."
      expect( manifestation.description ).to eq "Philosopher Weinberger shows how the digital revolution is radically changing the way we make sense of our lives. Human beings constantly collect, label, and organize data--but today, the shift from the physical to the digital is mixing, burning, and ripping our lives apart. In the past, everything had its one place--the physical world demanded it--but now everything has its places: multiple categories, multiple shelves. Everything is suddenly miscellaneous. Weinberger charts the new principles of digital order that are remaking business, education, politics, science, and culture. He examines how Rand McNally decides what information not to include in a physical map (and why Google Earth is winning that battle), how Staples stores emulate online shopping to increase sales, why your children's teachers will stop having them memorize facts, and how the shift to digital music stands as the model for the future.--From publisher description.\nFrom A to Z, Everything Is Miscellaneous will completely reshape the way you think - and what you know - about the world. Includes information on alphabetical order, Amaxon.com, animals, Aristotle, authority, Bettmann Archive, blogs (weblogs), books, broadcasting, British Broadcasting Corporation (BBC), business, card catalog, categories and categorization, clusters, companies, Colon Classification, conversation, Melvil Dewey, Dewey Decimal Classification system, Encyclopaedia Britannica, encyclopedia, essentialism, experts, faceted classification system, first order of order, Flickr.com, Google, Great Books of the Western World, ancient Greeks, health and medical information, identifiers, index, inventory tracking, knowledge, labels, leaf and leaves, libraries, Library of Congress, links, Carolus Linnaeus, lumping and splitting, maps and mapping, marketing, meaning, metadata, multiple listing services (MLS), names of people, neutrality or neutral point of view, New York Public Library, Online Computer Library Center (OCLC), order and organization, people, physical space, everything having place, Plato, race, S.R. Ranganathan, Eleanor Rosch, Joshua Schacter, science, second order of order, simplicity, social constructivism, social knowledge, social networks, sorting,  species, standardization, tags, taxonomies, third order of roder, topical categorization, tree, Uniform Product Code (UPC), users, Jimmy Wales, web, Wikipedia, etc."
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
    
    it "should parse title information properly", :vcr => true do
      manifestation = LocSearch.import_from_sru_response( "2012532441" )
      expect( manifestation.original_title ).to eq "The data journalism handbook"
      expect( manifestation.title_alternative ).to eq "How journalists can use data to improve the news"
    end

    it "should distinguish title information with subject", :vcr => true do
      m = LocSearch.import_from_sru_response( "2008273186" )
      expect( m.original_title ).to eq "Flexible Rails : Flex 3 on Rails 2"
    end

    it "should create multiple series_statements", :vcr => true do
      m = LocSearch.import_from_sru_response( "2012471967" )
      expect( m.series_statements.size ).to eq 2
      RSpec.describe m.series_statements.collect( &:original_title ) do
        it { is_expected.to include( "Pragmatic programmers" ) }
        it { is_expected.to include( "Facets of Ruby series" ) }
      end
    end

    it "should create lcsh subjects only", :vcr => true do
      m = LocSearch.import_from_sru_response( "2011281911" )
      expect( m.subjects.size ).to eq 2
      RSpec.describe m.subjects.collect( &:term ) do
        it { is_expected.to include( "Computer software--Development" ) }
        it { is_expected.to include( "Ruby (Computer program language)" ) }
      end
    end

    it "should support name and title subjects", :vcr => true do
      m = LocSearch.import_from_sru_response( "2013433146" )
      expect( m.subjects.size ).to eq 3
      RSpec.describe m.subjects.collect( &:term ) do
        it { is_expected.to include( "Montgomery, L. M. (Lucy Maud), 1874-1942. Anne of Green Gables" ) }
        it { is_expected.to include( "Montgomery, L. M. (Lucy Maud), 1874-1942--Criticism and interpretation" ) }
        it { is_expected.to include( "Montgomery, L. M. (Lucy Maud), 1874-1942--Influence" ) }
      end
    end

    it "should import note fields", :vcr => true do
      m = LocSearch.import_from_sru_response( "2010526151" )
      expect( m.note ).not_to be_nil
      expect( m.note ).not_to be_empty
      expect( m.note ).to eq %Q["This is a book about the design of user interfaces for search and discovery"--Pref.;\n"January 2010"--T.p. verso.;\nIncludes bibliographical references and index.]
    end

    it "should import e-resource", :vcr => true do
      m = LocSearch.import_from_sru_response( "2005568297" )
      expect( m.carrier_type ).to eq CarrierType.where( :name => "file" ).first
      expect( m.access_address ).to eq "http://portal.acm.org/dl.cfm"
    end

    it "should import audio book", :vcr => true do
      m = LocSearch.import_from_sru_response( "2007576782" ) # RDA metadata
      expect( m.manifestation_content_type ).to eq ContentType.where( :name => "audio" ).first
      pending "carrier type should be changed. cf. next-l/enju_leaf#300"
      expect( m.carrier_type ).to eq CarrierType.where( :name => "CD" ).first
    end

    it "should import serial", :vcr => true do
      m = LocSearch.import_from_sru_response( "00200486" )
      expect( m.original_title ).to eq "Science and technology of advanced materials"
      expect( m.periodical ).not_to be_nil
      expect( m.identifier_contents( :issn ).first ).to eq "14686996"
      expect( m.identifier_contents( :issn_l ).first ).to eq "14686996"
      expect( m.frequency.name ).to eq "bimonthly"
      series_statement = m.series_statements.first
      expect( series_statement.original_title ).to eq "Science and technology of advanced materials"
      expect( series_statement.series_master ).to be_truthy
    end
  end

  context ".search", :vcr => true do
    it "should return a search result", :vcr => true do
      result = LocSearch.search( 'library' )
      expect( result[:total_entries] ).to eq 10000
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

    it "should support pagination" do
      url = LocSearch.make_sru_request_uri( "test", :page => 2 )
      uri = URI.parse( url )
      expect( Hash[uri.query.split(/\&/).collect{|e| e.split(/=/) }] ).to eq( {
	"query" => "test", 
	"version" => "1.1",
	"operation" => "searchRetrieve",
	"maximumRecords" => "10",
	"recordSchema" => "mods",
	"startRecord" => "11",
      } )
    end
  end
end
