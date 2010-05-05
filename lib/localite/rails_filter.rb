module Localite::RailsFilter
  def self.filter(controller, &block)
    begin
      locale = controller.send(:current_locale)
    rescue NoMethodError
      nil
    end
    
    scope = begin
      controller.send(:localite_scope)
    rescue NoMethodError
      nil
    end
    
    localite :in, locale do
      localite :scope, scope, &block
    end
  end
  
  private

  # override this method to adjust localite parameters
  def current_locale
    return params[:locale] if params[:locale] && params[:locale] =~ /^[a-z][a-z]$/
    return params[:lang] if params[:lang] && params[:lang] =~ /^[a-z][a-z]$/
  end

  def self.localite(mode, value, &block)
    if value
      Localite.send(mode, value, &block)
    else
      yield
    end
  end
end
