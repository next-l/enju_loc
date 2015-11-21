class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  enju_leaf
  enju_biblio
  enju_library
  after_action :verify_authorized

  include Pundit
end
