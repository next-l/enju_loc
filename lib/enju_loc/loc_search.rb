module EnjuLoc
  module LocSearch
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      LOC_SRU_BASEURL = "http://lx2.loc.gov:210/LCDB"
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
          raise EnjuNdl::InvalidIsbn unless lisbn.valid?
        #end

        manifestation = Manifestation.find_by_isbn(lisbn.isbn)
        return manifestation.first if manifestation.present?

        doc = return_xml(lisbn.isbn)
        raise EnjuNdl::RecordNotFound unless doc
        #raise EnjuNdl::RecordNotFound if doc.at('//openSearch:totalResults').content.to_i == 0
        import_record_from_loc(doc)
      end

      def import_record_from_loc( doc )
        record_identifier = doc.at('//recordInfo/recordIdentifier').values.first
        loc_identifier = Identifier.where(:body => record_identifier, :identifier_type_id => IdentifierType.where(:name => 'loc_identifier').first_or_create.id).first
        return loc_identifier.manifestation if loc_identifier

        lccn = doc.at('//identifier[@type="lccn"]').try(:content)

        publishers = get_publishers(doc)

        # title
        title = get_title(doc)

        # date of publication
        pub_date = doc.at('//dateIssued').try(:content).sub(/\Ac/, '')
        unless pub_date =~ /^\d+(-\d{0,2}){0,2}$/
          pub_date = nil
        end
        if pub_date
          date = pub_date.split('-')
          if date[0] and date[1]
            date = sprintf("%04d-%02d", date[0], date[1])
          else
            date = pub_date
          end
        end

        language = Language.where(:iso_639_2 => get_language(doc)).first
        if language
          language_id = language.id
        else
          language_id = 1
        end

        isbn = Lisbn.new(doc.at('//identifier[@type="isbn"]').try(:content).to_s).try(:isbn)
        issn = StdNum::ISSN.normalize(doc.at('//identifier[@type="issn"]').try(:content))
        issn_l = StdNum::ISSN.normalize(doc.at('//identifier[@type="issn-l"]').try(:content))

        carrier_type = get_carrier_type( doc )

        content_type = get_content_type( doc )

        # admin_identifier = doc.at('//dcndl:BibAdminResource[@rdf:about]').attributes["about"].value
        # description = doc.at('//abstract').try(:content)
        # price = doc.at('//dcndl:price').try(:content)
        # volume_number_string = doc.at('//dcndl:volume/rdf:Description/rdf:value').try(:content)
        # extent = get_extent(doc)
        publication_periodicity = doc.at('//frequency').try(:content)
        # statement_of_responsibility = doc.xpath('//dcndl:BibResource/dc:creator').map{|e| e.content }

        manifestation = nil
        Agent.transaction do
          publisher_agents = Agent.import_agents(publishers)

          manifestation = Manifestation.new(
            :manifestation_identifier => admin_identifier,
            :original_title => title[:manifestation],
            :title_transcription => title[:transcription],
            :title_alternative => title[:alternative],
            :title_alternative_transcription => title[:alternative_transcription],
            # TODO: NDLサーチに入っている図書以外の資料を調べる
            #:carrier_type_id => CarrierType.where(:name => 'print').first.id,
            :language_id => language_id,
            :pub_date => date,
            :description => description,
            :volume_number_string => volume_number_string,
            :price => price,
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
            create_additional_attributes(doc, manifestation)
            create_series_statement(doc, manifestation)
          end
        end

        #manifestation.send_later(:create_frbr_instance, doc.to_s)
        return manifestation
      end

      private
      def get_content_type( doc )
        doc.xpath('//typeOfResource').each do |d|
          content_type = ContentType.where( :name => d ).first
        end
#          case d.content
#          when 'text'
#          when 'http://purl.org/dc/dcmitype/Sound'
#            content_type = ContentType.where(:name => 'audio').first
#          when 'http://purl.org/dc/dcmitype/MovingImage'
#            content_type = ContentType.where(:name => 'video').first
#          when 'http://ndl.go.jp/ndltype/ElectronicResource'
#            carrier_type = CarrierType.where(:name => 'file').first
#          end
#        end
#        ""
        ""
      end
    end
  end
end
