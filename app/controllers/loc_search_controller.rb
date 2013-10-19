class LocSearchController < ApplicationController
  def index
    if params[:page].to_i <= 0
      page = 1
    else
      page = params[:page].to_i
    end
    @query = params[ :query ].to_s.strip
    books = LocSearch.search( @query, { :page => page } )
    @books = Kaminari.paginate_array(
      books[:items],
      :total_count => books[ :total_entries ],
      :page => page
    ).page( page ).per( 10 )
    respond_to do |format|
      format.html
    end
  end
end
