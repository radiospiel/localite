module Localite::RailsFilter
  def self.filter(controller, &block)
    #
    # get the current locale
    locale = begin
      controller.send(:current_locale)
    rescue NoMethodError
    end

    #
    # get the current locale
    begin
      scope = controller.send(:localite_scope)
      scope = [ scope ] if scope && !scope.is_a?(Array)
    rescue NoMethodError
    end

    #
    # set up localite for this action.
    Localite.in(locale) do 
      Localite.scope(*scope, &block)
    end
  end
  
  private

  #
  # override this method to adjust localite parameters
  def current_locale
    return params[:locale] if params[:locale] && params[:locale] =~ /^[a-z][a-z]$/
    return params[:lang] if params[:lang] && params[:lang] =~ /^[a-z][a-z]$/
  end
end
