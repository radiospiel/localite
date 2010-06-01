require "localite/filter"

class LocaliteController < ApplicationController
  include Localite::Filter
  
  def index
  end

  def current_locale
    return "de" if action_name == "auto" 
    super
  end

  def auto
    render :action => :index
  end
  
  def template
  end
end
