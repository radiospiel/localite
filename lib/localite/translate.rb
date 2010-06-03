require "set"

module Localite::Translate
  
  private
  
  def log_translation(str, locale, scope, value)        
    value = value[0,37] + "…" if value.length > 40

    msg = "Resolved #{current_scope.first(str)}"
    msg += " (as #{scope.inspect})" if current_scope.to_s != scope
    msg += " to #{value.inspect} [#{locale}]"
    logger.warn msg
  end

  public
  
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
      current_scope.each(s) do |scope|
        next unless value = translate_via_i18n(locale, scope)

        log_translation s, locale, scope, value
        
        #
        # reformat: if target format is html, convert the value into text.
        return Localite::Format.send(current_format, value)
      end
    end

    src = caller[1]
    if src =~ /^([^:]+:[^:]+):/
      src = $1
    end
    logger.warn "[#{current_locale}] Could not translate #{current_scope.first(s).inspect}; from #{src}"

    record_missing current_locale, current_scope.first(s)
    return if raise_mode == :no_raise
    
    raise Missing, [current_locale, s]
  ensure
    I18n.locale = old_i18n_locale
  end

  private
  
  def translate_via_i18n(locale, str)
    I18n.locale = locale
    
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
      @locale, @string = *opts
      @scope = Localite.current_scope.to_s
      # dlog "--> scope", @scope.inspect
    end

    def to_s
      "Missing translation: [#{locale}] #{string.inspect} (in scope #{scope.inspect})"
    end
  end
end
