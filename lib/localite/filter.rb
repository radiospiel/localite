module Localite::Filter
  module ControllerFilter
    #
    # set up localite for this action.
    def self.filter(controller, &block)
      args = controller.send(:localite_scopes)
      args.push :locale => controller.send(:current_locale),
        :format => controller.send(:localite_format)

      Localite.scope(*args) do
        if controller.logger
          controller.logger.warn "Localite::Filter: scope is [#{Localite.current_locale}] #{Localite.scopes.join(".").inspect}"
        end
        yield
      end
    rescue
      if Rails.env.development?
        controller.response.body = "Caught exception: " + CGI::escapeHTML($!.inspect) 
      end
      raise
    end
  end

  module ControllerMethods
    #
    # override this method to adjust localite parameters
    def current_locale
      return params[:locale] if params[:locale] && params[:locale] =~ /^[a-z][a-z]$/
      return params[:lang] if params[:lang] && params[:lang] =~ /^[a-z][a-z]$/
    end

    #
    # return the current scope(s) as an array.
    def localite_scopes
      []
    end

    #
    # return the current scope(s) as an array.
    def localite_format
      :html
    end
  end
  
  def self.included(klass)
    klass.send :include, ControllerMethods
    klass.send :helper_method, :current_locale
    klass.send :around_filter, ControllerFilter
  end
end
