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
    end
  end
end
