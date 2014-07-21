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
        pub_date = doc.at('//mods:dateIssued',NS).try(:content)
        if pub_date
	  pub_date.sub!( /\Ac/, '' )
          unless pub_date =~ /^\d+(-\d{0,2}){0,2}$/
            pub_date = nil
	  else
            date = pub_date.split('-')
            if date[0] and date[1]
              date = sprintf("%04d-%02d", date[0], date[1])
            else
              date = pub_date
            end
	  end
        end

        language = Language.where(:iso_639_2 => get_language(doc)).first
        if language
          language_id = language.id
        else
          language_id = 1
        end

        isbn = Lisbn.new(doc.at('//mods:identifier[@type="isbn"]',NS).try(:content).to_s).try(:isbn)
        lccn = StdNum::LCCN.normalize(doc.at('//mods:identifier[@type="lccn"]',NS).try(:content).to_s)
        issn = StdNum::ISSN.normalize(doc.at('//mods:identifier[@type="issn"]',NS).try(:content).to_s)
        issn_l = StdNum::ISSN.normalize(doc.at('//mods:identifier[@type="issn-l"]',NS).try(:content).to_s)

	types = get_carrier_and_content_types( doc )
	content_type = types[ :content_type ]
	carrier_type = types[ :carrier_type ]

	record_identifier = doc.at('//mods:recordInfo/mods:recordIdentifier',NS).try(:content)
        description = doc.at('//mods:abstract',NS).try(:content)
        edition_string = doc.at('//mods:edition',NS).try(:content)
        extent = get_extent(doc)
        publication_periodicity = doc.at('//mods:frequency',NS).try(:content)
        statement_of_responsibility = get_statement_of_responsibility(doc)

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
            :height => extent[:height]
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
          manifestation.periodical = true if publication_periodicity
          if manifestation.save
            identifier.each do |k, v|
              manifestation.identifiers << v if v.valid?
            end
            manifestation.publishers << publisher_agents
	    manifestation.creators << creator_agents
	    create_subject_related_elements(doc, manifestation)
            create_series_statement(doc, manifestation)
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
              classification = Classification.new(:category => ddc)
              classification.classification_type = classification_type
              manifestation.classifications << classification if classification.valid?
            end
          end
	end
      end

      def create_series_statement(doc, manifestation)
        series = series_title = {}
        series[:title] = doc.at('//mods:relatedItem[@type="series"]/mods:titleInfo/mods:title',NS).try(:content)
        if series[:title]
          series_title[:title] = series[:title].split(';')[0].strip
        end

        if series_title[:title]
          series_statement = SeriesStatement.where(:original_title => series_title[:title]).first
          unless series_statement
            series_statement = SeriesStatement.new(
              :original_title => series_title[:title],
            )
          end
        end
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
	    subtitle = e.at('./mods:subtitle',NS).try(:content)
	    original_title << " : #{ subtitle }" if subtitle
	    partnumber = e.at('./mods:partNumber',NS).try(:content)
	    partname = e.at('./mods:partName',NS).try(:content)
	    partname = [ partnumber, partname ].compact.join( ": " )
	    original_title << ". #{ partname }" if partname
	  end
	end
	{ :original_title => original_title, :title_alternative => title_alternatives.join( " ; " ) }
      end

      def get_language(doc)
	language = doc.at('//mods:language/mods:languageTerm[@authority="iso639-2b"]',NS).try(:content)
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
	if note
	  note
	else
	  doc.xpath('/mods:mods/mods:name',NS).map do |n|
	    n.at('./mods:namePart',NS).try(:content)
	  end.join( "; " )
	end
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
	doc.xpath('//mods:subject',NS).each do |s|
	  subject = []
	  s.xpath('./*',NS).each do |subelement|
	    case subelement.name
	    when "topic", "geographic", "genre", "temporal"
	      subject << subelement.try(:content)
	    when "titleInfo"
	      subject << subelement.at('./mods:title',NS).try(:content)
	    end
	  end
	  next if subject.compact.empty?
	  subjects << {
	    :term => subject.compact.join( "--" )
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
	    classifications << ddc.split(/[^\d\.]/).first.strip
	  end
	end
	classifications
      end

      def get_carrier_and_content_types(doc)
        carrier_type = content_type = nil
        doc.xpath('//mods:form',NS).each do |e|
          authority = e.attributes['authority'].try(:content)
	  case authority
	  when "gmd"
	    case e.content
	    when "electronic resource"
	      carrier_type = CarrierType.where(:name => 'file').first
	    when "videorecording"
              content_type = ContentType.where(:name => 'video').first
	    #TODO: Enju needs more specific mappings...
	    when "art original"
	    when "microscope slides"
	    when "art reproduction"
	    when "model"
	    when "chart"
	    when "motion picture"
	    when "diorama"
	    when "picture"
	    when "realia"
	    when "filmstrip"
	    when "slide"
	    when "flash card"
	    when "sound recording"
	    when "game"
	    when "technical drawing"
	    when "graphic"
	    when "toy"
	    when "kit"
	    when "transparency"
	    when "microform"
	    end
	  when "marcsmd" # cf.http://www.loc.gov/standards/valuelist/marcsmd.html
	    case e.content
            when "text", "braille", "large print", "regular print", "text in looseleaf binder"
              carrier_type = CarrierType.where(:name => 'print').first
              content_type = ContentType.where(:name => 'text').first
	    when "videorecording", "videocartridge", "videocassette", "videodisc", "videoreel"
              content_type = ContentType.where(:name => 'video').first
	    when "electronic resource", "chip cartridge", "computer optical disc cartridge", "magnetic disk", "magneto-optical disc", "optical disc", "remote", "tape cartridge", "tape cassette", "tape reel"
	      carrier_type = CarrierType.where(:name => 'file').first
	    when "motion picture", "film cartridge", "film cassette", "film reel"
              content_type = ContentType.where(:name => 'video').first
	    when "sound recording", "cylinder", "roll ", "sound cartridge", "sound cassette ", "sound disc ", "sound-tape reel", "sound-track film ", "wire recording" 
	      conrent_type = ContentType.where(:name => 'audio').first
	    #when "nonprojected graphic", "chart", "collage", "drawing", "flash card", "painting", "photomechanical print", "photonegative", "photoprint", "picture", "print", "technical drawing", "projected graphic", "filmslip", "filmstrip cartridge", "filmstrip roll", "other filmstrip type ", "slide", "transparency"
            #  content_type = ContentType.where(:name => 'image').first
	    #TODO: Enju needs more specific mappings...
	    when "globe"
	    when "celestial globe"
	    when "earth moon globe"
	    when "planetary or lunar globe"
	    when "terrestrial globe"
	    when "map"
	    when "atlas"
	    when "diagram"
	    when "map"
	    when "model"
	    when "profile "
	    when "remote-sensing image"
	    when "section"
	    when "view"
	    when "microform"
	    when "aperture card"
	    when "microfiche"
	    when "microfiche cassette"
	    when "microfilm cartridge"
	    when "microfilm cassette"
	    when "microfilm reel"
	    when "microopaque"
	    when "tactile material"
            when "braille"
            when "combination"
            when "moon"
            when "tactile, with no writing system"
	    end
	  when "marcform" # cf. http://www.loc.gov/standards/valuelist/marcform.html
	    case e.content
	    when "print", "large print"
              carrier_type = CarrierType.where(:name => 'print').first
              content_type = ContentType.where(:name => 'text').first
	    when "electronic"
              carrier_type = CarrierType.where(:name => 'file').first
	    #TODO: Enju needs more specific mappings...
	    when "microfiche"
	    when "braille"
	    when "microfilm"
	    end
	  end
	end
        doc.xpath('//mods:genre',NS).each do |e|
          authority = e.attributes['authority'].try(:content)
	  case authority
	  when "rdacontent"
	    case e.content
	    when "computer dataset", "computer program"
              content_type = ContentType.where(:name => 'file').first
	    when "sounds", "spoken word"
              content_type = ContentType.where(:name => 'audio').first
	    when "text"
              content_type = ContentType.where(:name => 'text').first
	    when "two-dimensional moving image"
              content_type = ContentType.where(:name => 'video').first
	    #TODO: Enju needs more specific mappings...
	    when "cartographic dataset"
	    when "cartographic image"
	    when "cartographic moving image"
	    when "cartographic tactile image"
	    when "cartographic tactile three-dimensional form"
	    when "cartographic three-dimensional form"
	    when "notated movement"
	    when "notated music"
	    when "performed music"
	    when "still image"
	    when "tactile image"
	    when "tactile notated music"
	    when "tactile notated movement"
	    when "tactile text"
	    when "tactile three-dimensional form"
	    when "three-dimensional form"
	    when "three-dimensional moving image"
	    when "other"
	    when "unspecified"
            end
          end
        end
	type = doc.at('//mods:typeOfResource',NS).try(:content)
	case type
	when "text"
	  content_type = ContentType.where(:name => 'text').first
	when "sound recording", "sound recording-musical", "sound recording-nonmusical"
	  content_type = ContentType.where(:name => 'audio').first
	when "moving image"
	  content_type = ContentType.where(:name => 'video').first
	when "software, multimedia"
	  carrier_type = ContentType.where(:name => 'file').first
	#TODO: Enju needs more specific mappings...
	when "cartographic "
	when "notated music"
	when "still image"
	when "three dimensional object"
	when "mixed material"
	end
        { :carrier_type => carrier_type, :content_type => content_type }
      end
    end
  end
end
