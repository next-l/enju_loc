module LocSearchHelper
  def link_to_import(lccn)
    if lccn.blank?
      t('enju_loc.not_available')
    else
      manifestation = Manifestation.where(:lccn => lccn).first
      unless manifestation
        link_to t('enju_loc.add'), ndl_books_path(:book => {:lccn => lccn}), :method => :post
      else
        link_to t('enju_loc.already_exists'), manifestation
      end
    end
  end
end
