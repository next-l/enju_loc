module EnjuLoc
  module LocSearch
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def loc_search(query, options = {})
        options = {}.merge(options)
        doc = nil
        results = {}
        startrecord = options[:idx].to_i
        if startrecord == 0
          startrecord = 1
        end
        url = LOC_SRU_BASEURL + "?operation=searchRetrieve&version=1.1&=query=#{ URI.escape(query) }"
        cont = open( url ){|io| io.read }
        parser = LibXML::XML::Parser.string( cont )
        doc = parser.parse
      end

      def import_record_from_loc_isbn(options)
        #if options[:isbn]
          lisbn = Lisbn.new(options[:isbn])
          raise EnjuLoc::InvalidIsbn unless lisbn.valid?
        #end

        manifestation = Manifestation.find_by_isbn(lisbn.isbn)
        return manifestation.first if manifestation.present?

        doc = return_xml(lisbn.isbn)
        raise EnjuLoc::RecordNotFound unless doc
        import_record_from_loc(doc)
      end

      NS = {"mods"=>"http://www.loc.gov/mods/v3"}
      def import_record_from_loc( doc )
        record_identifier = doc.at( '//mods:recordInfo/mods:recordIdentifier', NS ).try(:content)
        loc_identifier = Identifier.where(:body => record_identifier, :identifier_type_id => IdentifierType.where(:name => 'loc_identifier').first_or_create.id).first
        return loc_identifier.manifestation if loc_identifier

        publishers = []
        doc.xpath('//mods:publisher',NS).each do |publisher|
          publishers << {
            :full_name => publisher.content,
            #:agent_identifier => publisher.attributes["about"].try(:content)
          }
        end

        creators = get_creators(doc)

        # title
        titles = get_titles(doc)

        # date of publication
        date = get_date_of_publication(doc)

        language = Language.where(:iso_639_2 => get_language(doc)).first
        if language
          language_id = language.id
        else
          language_id = 1
        end

        isbn = Lisbn.new(doc.at('/mods:mods/mods:identifier[@type="isbn"]',NS).try(:content).to_s).try(:isbn)
        lccn = StdNum::LCCN.normalize(doc.at('/mods:mods/mods:identifier[@type="lccn"]',NS).try(:content).to_s)
        issn = StdNum::ISSN.normalize(doc.at('/mods:mods/mods:identifier[@type="issn"]',NS).try(:content).to_s)
        issn_l = StdNum::ISSN.normalize(doc.at('/mods:mods/mods:identifier[@type="issn-l"]',NS).try(:content).to_s)

	types = get_carrier_and_content_types( doc )
	content_type = types[ :content_type ]
	carrier_type = types[ :carrier_type ]

	record_identifier = doc.at('//mods:recordInfo/mods:recordIdentifier',NS).try(:content)
        description = doc.xpath('//mods:abstract',NS).collect(&:content).join("\n")
        edition_string = doc.at('//mods:edition',NS).try(:content)
        extent = get_extent(doc)
	note = get_note(doc)
        frequency = get_frequency(doc)
	issuance = doc.at('//mods:issuance',NS).try(:content)
	is_serial = true if issuance == "serial"
        statement_of_responsibility = get_statement_of_responsibility(doc)
	access_address = get_access_address(doc)
	publication_place = get_publication_place(doc)

        manifestation = nil
        Agent.transaction do
	  creator_agents = Agent.import_agents(creators)
          publisher_agents = Agent.import_agents(publishers)

          manifestation = Manifestation.new(
            :manifestation_identifier => record_identifier,
            :original_title => titles[:original_title],
            :title_alternative => titles[:title_alternative],
            :language_id => language_id,
            :pub_date => date,
            :description => description,
	    :edition_string => edition_string,
            :statement_of_responsibility => statement_of_responsibility,
            :start_page => extent[:start_page],
            :end_page => extent[:end_page],
            :height => extent[:height],
	    :access_address => access_address,
	    :note => note,
	    :publication_place => publication_place,
	    :periodical => is_serial,
          )
          identifier = {}
          if isbn
            identifier[:isbn] = Identifier.new(:body => isbn)
            identifier[:isbn].identifier_type = IdentifierType.where(:name => 'isbn').first_or_create
          end
          if loc_identifier
            identifier[:loc_identifier] = Identifier.new(:body => loc_identifier)
            identifier[:loc_identifier].identifier_type = IdentifierType.where(:name => 'loc_identifier').first_or_create
          end
          if lccn
            identifier[:lccn] = Identifier.new(:body => lccn)
            identifier[:lccn].identifier_type = IdentifierType.where(:name => 'lccn').first_or_create
          end
          if issn
            identifier[:issn] = Identifier.new(:body => issn)
            identifier[:issn].identifier_type = IdentifierType.where(:name => 'issn').first_or_create
          end
          if issn_l
            identifier[:issn_l] = Identifier.new(:body => issn_l)
            identifier[:issn_l].identifier_type = IdentifierType.where(:name => 'issn_l').first_or_create
          end
          manifestation.carrier_type = carrier_type if carrier_type
          manifestation.manifestation_content_type = content_type if content_type
	  manifestation.frequency = frequency if frequency
          if manifestation.save
            identifier.each do |k, v|
              manifestation.identifiers << v if v.valid?
            end
            manifestation.publishers << publisher_agents
	    manifestation.creators << creator_agents
	    create_subject_related_elements(doc, manifestation)
            create_series_statement(doc, manifestation)
	    if is_serial
              create_series_master(doc, manifestation)
	    end
          end
        end
        return manifestation
      end

      private
      def create_subject_related_elements(doc, manifestation)
	subjects = get_subjects(doc)
	classifications = get_classifications(doc)
	if defined?(EnjuSubject)
          subject_heading_type = SubjectHeadingType.where(:name => 'lcsh').first_or_create
          subjects.each do |term|
            subject = Subject.where(:term => term[:term]).first
            unless subject
              subject = Subject.new(term)
              subject.subject_heading_type = subject_heading_type
              subject.subject_type = SubjectType.where(:name => 'concept').first_or_create
            end
            manifestation.subjects << subject
          end
          if classifications
            classification_type = ClassificationType.where(:name => 'ddc').first_or_create
	    classifications.each do |ddc|
              classification = Classification.where(:category => ddc).first
	      unless classification
                classification = Classification.new(:category => ddc)
                classification.classification_type = classification_type
	      end
              manifestation.classifications << classification if classification.valid?
            end
          end
	end
      end

      def create_series_statement(doc, manifestation)
        doc.xpath('//mods:relatedItem[@type="series"]/mods:titleInfo/mods:title',NS).each do |series|
          series_title = title = series.try(:content)
          if title
            series_title = title.split(';')[0].strip
          end
          if series_title
            series_statement = SeriesStatement.where(:original_title => series_title).first_or_create
            if series_statement.try(:save)
              manifestation.series_statements << series_statement
            end
          end
        end
      end
      
      def create_series_master(doc, manifestation)
        titles = get_titles(doc)
	series_statement = SeriesStatement.new(
	  :original_title => titles[:original_title],
	  :title_alternative => titles[:title_alternative],
	  :series_master => true,
	)
	if series_statement.try(:save)
	  manifestation.series_statements << series_statement
	end
      end

      def get_titles(doc)
	original_title = ""
	title_alternatives = []
	doc.xpath('//mods:mods/mods:titleInfo',NS).each do |e|
	  type = e.attributes["type"].try(:content)
	  case type
	  when "alternative", "translated", "abbreviated", "uniform"
	    title_alternatives << e.at('./mods:title',NS).content
	  else
	    nonsort = e.at('./mods:nonSort',NS).try(:content)
	    original_title << nonsort if nonsort
	    original_title << e.at('./mods:title',NS).try(:content)
	    subtitle = e.at('./mods:subTitle',NS).try(:content)
	    original_title << " : #{ subtitle }" if subtitle
	    partnumber = e.at('./mods:partNumber',NS).try(:content)
	    partname = e.at('./mods:partName',NS).try(:content)
	    partname = [ partnumber, partname ].compact.join( ": " )
	    original_title << ". #{ partname }" unless partname.blank?
	  end
	end
	{ :original_title => original_title, :title_alternative => title_alternatives.join( " ; " ) }
      end

      def get_language(doc)
	language = doc.at('//mods:language/mods:languageTerm[@authority="iso639-2b"]',NS).try(:content)
      end

      def get_access_address(doc)
	access_address = nil
	url = doc.at('//mods:location/mods:url',NS)
	if url
	  usage = url.attributes["usage"].try(:content)
	  case usage
	  when "primary display", "primary"
	    access_address = url.try(:content)
	  end
	end
	access_address
      end

      def get_publication_place(doc)
	place = doc.at('//mods:originInfo/mods:place/mods:placeTerm[@type="text"]',NS).try(:content)
      end

      def get_extent(doc)
        extent = doc.at('//mods:extent',NS).try(:content)
        value = {:start_page => nil, :end_page => nil, :height => nil}
        if extent
          extent = extent.split(';')
          page = extent[0].try(:strip)
          if page =~ /(\d+)\s*(p|page)/
            value[:start_page] = 1
            value[:end_page] = $1.dup.to_i
          end
          height = extent[1].try(:strip)
          if height =~ /(\d+)\s*cm/
            value[:height] = $1.dup.to_i
          end
        end
        value
      end

      def get_statement_of_responsibility(doc)
	note = doc.at('//mods:note[@type="statement of responsibility"]',NS).try(:content)
	if note.blank?
	  note = get_creators(doc).map{|e| e[:full_name] }.join( " ; " )
	end
	note
      end
      def get_note(doc)
        notes = []
	doc.xpath('//mods:note',NS).each do |note|
	  type = note.attributes['type'].try(:content)
	  next if type == "statement of responsibility"
	  note_s = note.try( :content )
	  notes << note_s unless note_s.blank?
	end
	if notes.empty?
	  nil
	else
	  notes.join( ";\n" )
	end
      end
      def get_date_of_publication(doc)
        dates = []
	doc.xpath('//mods:dateIssued',NS).each do |pub_date|
	  pub_date = pub_date.content.sub( /\A[cp]/, '' )
          next unless pub_date =~ /^\d+(-\d\d?){0,2}$/
          date = pub_date.split('-')
          if date[0] and date[1]
            dates << sprintf("%04d-%02d", date[0], date[1])
          else
            dates << pub_date
	  end
        end
	dates.compact.first
      end

      # derived from marcfrequency: http://www.loc.gov/standards/valuelist/marcfrequency.html
      MARCFREQUENCY = [
        "Continuously updated",
        "Daily",
        "Semiweekly",
        "Three times a week",
        "Weekly",
        "Biweekly",
        "Three times a month",
        "Semimonthly",
        "Monthly",
        "Bimonthly",
        "Quarterly",
        "Three times a year",
        "Semiannual",
        "Annual",
        "Biennial",
        "Triennial",
        "Completely irregular",
      ]
      def get_frequency(doc)
        frequencies = []
	doc.xpath('//mods:frequency',NS).each do |freq|
	  frequency = freq.try(:content)
	  MARCFREQUENCY.each do |freq_regex|
	    if /\A(#{freq_regex})/ =~ frequency
	      frequency_name = freq_regex.downcase.gsub( /\s+/, "_" )
	      frequencies << Frequency.where( :name => frequency_name ).first
	    end
	  end
	end
	frequencies.compact.first
      end

      def get_creators(doc)
	creators = []
        doc.xpath('/mods:mods/mods:name',NS).each do |creator|
	  creators << {
	    :full_name => creator.xpath('./mods:namePart',NS).collect(&:content).join( ", " ),
	  }
        end
	creators.uniq
      end

      # TODO:only LCSH-based parsing...
      def get_subjects(doc)
	subjects = []
	doc.xpath('//mods:subject[@authority="lcsh"]',NS).each do |s|
	  subject = []
	  s.xpath('./*',NS).each do |subelement|
	    type = subelement.name
	    case subelement.name
	    when "topic", "geographic", "genre", "temporal"
	      subject << { :type => type , :term => subelement.try(:content) }
	    when "titleInfo"
	      subject << { :type => type, :term => subelement.at('./mods:title',NS).try(:content) }
	    when "name"
	      name = subelement.xpath('./mods:namePart',NS).map{|e| e.try(:content) }.join( ", " )
	      subject << { :type => type, :term => name }
	    end
	  end
	  next if subject.compact.empty?
	  if subject.size > 1 and subject[0][:type] == "name" and subject[1][:type] == "titleInfo"
	    subject[0..1] = { :term => subject[0..1].map{|e|e[:term]}.join( ". " ) }
	  end
	  subjects << {
	    :term => subject.map{|e|e[:term]}.compact.join( "--" )
	  }
	end
	subjects
      end

      # TODO:support only DDC.
      def get_classifications(doc)
	classifications = []
	doc.xpath('//mods:classification[@authority="ddc"]',NS).each do|c|
	  ddc = c.content
	  if ddc
	    classifications << ddc.split(/[^\d\.]/).first.try(:strip)
	  end
	end
	classifications.compact
      end

      def get_carrier_and_content_types(doc)
        carrier_type = content_type = nil
        doc.xpath('//mods:form',NS).each do |e|
          authority = e.attributes['authority'].try(:content)
	  case authority
	  when "gmd"
	    case e.content
	    when "electronic resource"
	      carrier_type = CarrierType.where(:name => 'online_resource').first
	    when "videorecording", "motion picture", "game"
              content_type = ContentType.where(:name => 'two_dimensional_moving_image').first
	    when "sound recording"
              content_type = ContentType.where(:name => 'performed_music').first
	    when "graphic", "picture"
	      content_type = ContentType.where(:name => 'still_image').first
	    #TODO: Enju needs more specific mappings...
	    when "art original",
	    	 "microscope slides",
	    	 "art reproduction",
	    	 "model",
	    	 "chart",
	    	 "diorama",
	    	 "realia",
	    	 "filmstrip",
	    	 "slide",
	    	 "flash card",
	    	 "technical drawing",
	    	 "toy",
	    	 "kit",
	    	 "transparency",
	    	 "microform"
	      content_type = ContentType.where(:name => 'other').first
	    end
	  when "marcsmd" # cf.http://www.loc.gov/standards/valuelist/marcsmd.html
	    case e.content
            when "text", "large print", "regular print", "text in looseleaf binder"
              carrier_type = CarrierType.where(:name => 'volume').first
              content_type = ContentType.where(:name => 'text').first
	    when "braille"
              carrier_type = CarrierType.where(:name => 'volume').first
              content_type = ContentType.where(:name => 'tactile_text').first
	    when "videodisc"
              carrier_type = CarrierType.where(:name => 'videodisc').first
              content_type = ContentType.where(:name => 'two_dimensional_moving_image').first
	    when "videorecording", "videocartridge", "videocassette", "videoreel"
              carrier_type = CarrierType.where(:name => 'other').first
              content_type = ContentType.where(:name => 'two_dimensional_moving_image').first
	    when "electronic resource"
	      carrier_type = CarrierType.where(:name => 'online_resource').first
	    when "chip cartridge", "computer optical disc cartridge", "magnetic disk", "magneto-optical disc", "optical disc", "remote", "tape cartridge", "tape cassette", "tape reel"
	      #carrier_type = CarrierType.where(:name => 'other').first
	    when "motion picture", "film cartridge", "film cassette", "film reel"
              content_type = ContentType.where(:name => 'two_dimensional_moving_image').first
	    when "sound recording", "cylinder", "roll", "sound cartridge", "sound cassette","sound-tape reel", "sound-track film", "wire recording" 
	      content_type = ContentType.where(:name => 'performed_music').first
	    when "sound disc"
	      content_type = ContentType.where(:name => 'performed_music').first
	      carrier_type = CarrierType.where(:name => 'audio_disc').first
	    when "nonprojected graphic", "chart", "collage", "drawing", "flash card", "painting", "photomechanical print", "photonegative", "photoprint", "picture", "print", "technical drawing", "projected graphic", "filmslip", "filmstrip cartridge", "filmstrip roll", "other filmstrip type ", "slide", "transparency"
              content_type = ContentType.where(:name => 'still_image').first
	    when "tactile material", "braille", "tactile, with no writing system"
	      content_type = ContentType.where(:name => 'tactile_text').first
	    #TODO: Enju needs more specific mappings...
	    when "globe",
	    	 "celestial globe",
		 "earth moon globe",
		 "planetary or lunar globe",
		 "terrestrial globe",
		 "map",
		 "atlas",
		 "diagram",
		 "map",
		 "model",
		 "profile",
		 "remote-sensing image",
		 "section",
		 "view",
		 "microform",
		 "aperture card",
		 "microfiche",
		 "microfiche cassette",
		 "microfilm cartridge",
		 "microfilm cassette",
		 "microfilm reel",
		 "microopaque",
		 "combination",
		 "moon"
              content_type = ContentType.where(:name => 'other').first
	    end
	  when "marcform" # cf. http://www.loc.gov/standards/valuelist/marcform.html
	    case e.content
	    when "print", "large print"
              carrier_type = CarrierType.where(:name => 'volume').first
              content_type = ContentType.where(:name => 'text').first
	    when "electronic"
              carrier_type = CarrierType.where(:name => 'online_resource').first
	    when "braille"
	      content_type = ContentType.where(:name => 'tactile_text').first
	    #TODO: Enju needs more specific mappings...
	    when "microfiche", "microfilm"
	      content_type = ContentType.where(:name => 'other').first
	    end
	  end
	end
        doc.xpath('//mods:genre',NS).each do |e|
          authority = e.attributes['authority'].try(:content)
	  case authority
	  when "rdacontent"
	    content_type = ContentType.where(:name => e.content.gsub(/\W+/, "_")).first
	    content_type = ContentType.where(:name => 'other').first unless content_type
          end
        end
	type = doc.at('//mods:typeOfResource',NS).try(:content)
	case type
	when "text"
	  content_type = ContentType.where(:name => 'text').first
	when "sound recording"
	  content_type = ContentType.where(:name => 'sounds').first
	when"sound recording-musical"
	  content_type = ContentType.where(:name => 'performed_music').first
	when"sound recording-nonmusical"
	  content_type = ContentType.where(:name => 'spoken_word').first
	when "moving image"
	  content_type = ContentType.where(:name => 'two_dimensional_moving_image').first
	when "software, multimedia"
	  content_type = ContentType.where(:name => 'other').first
	when "cartographic "
	  content_type = ContentType.where(:name => 'cartographic_image').first
	when "notated music"
	  content_type = ContentType.where(:name => 'notated_music').first
	when "still image"
	  content_type = ContentType.where(:name => 'still_image').first
	when "three dimensional object"
	  content_type = ContentType.where(:name => 'other').first
	when "mixed material"
	  content_type = ContentType.where(:name => 'other').first
	end
        { :carrier_type => carrier_type, :content_type => content_type }
      end
    end
  end
end
