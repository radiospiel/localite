require "set"

module Localite::Translate
  # 
  # translate a string 
  #
  # returns the translated string in the current locale.
  # If no translation is found try the base locale. 
  # If still no translation is found, return nil
  # 
  def translate(s, raise_mode)
    old_i18n_locale = I18n.locale
    
    [ current_locale, base ].uniq.each do |locale|

      scopes.each(s) do |scoped_string|
        next unless tr = translate_via_i18n(locale, scoped_string)

        #
        # reformat: if target format is html:
        tr = Localite::Format.send(current_format, tr)
        return tr
      end
    end

    record_missing current_locale, scopes.first(s)
    return if raise_mode == :no_raise
    
    raise Missing, [current_locale, s, scopes]
  ensure
    I18n.locale = old_i18n_locale
  end

  private
  
  def translate_via_i18n(locale, str)
    I18n.locale = locale
    
    logger.warn "Translate: #{str.inspect}"
    
    r = I18n.translate(str, :raise => true)
    return nil if r.is_a?(Hash)
    r
  rescue I18n::MissingTranslationData
    nil
  end
  
  #
  # log a missing translation and raise an exception 
  def record_missing(locale, s)
    @missing_translations ||= Set.new
    entry = [ locale, s ]
    return if @missing_translations.include?(entry)
    @missing_translations << entry
    logger.warn "Missing translation: [#{locale}] #{s.inspect}"
  end
  
  public
  
  class Missing < RuntimeError
    attr_reader :locale, :string, :scope

    def initialize(opts)
      @locale, @string, @scope = *opts

      @string = @string.to_s.dup unless @string.is_a?(Symbol)      
      @scope = @scope.dup
    end

    def to_s
      "Missing translation: [#{locale}] #{string.inspect} (in scope #{scope.inspect})"
    end
  end
end
