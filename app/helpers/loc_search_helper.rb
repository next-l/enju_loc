module LocSearchHelper
  def link_to_import_from_loc(lccn)
    if lccn.blank?
      t('enju_loc.not_available')
    else
      identifier_type = IdentifierType.where(:name => 'lccn').first
      if identifier_type
        manifestation = Identifier.where(:body => lccn, :identifier_type_id => identifier_type
.id).first.try(:manifestation)
      end
      unless manifestation
        link_to t('enju_loc.add'), loc_search_index_path(:book => {:lccn => lccn}), :method =>
:post
      else
        link_to t('enju_ndl.already_exists'), manifestation
      end
    end
  end
end
