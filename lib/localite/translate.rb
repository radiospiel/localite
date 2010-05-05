module Localite::Translate
  # 
  # translate a string 
  #
  # returns the translated string in the current locale.
  # If no translation is found try the base locale. 
  # If still no translation is found, return nil
  # 
  def translate(s, raise_mode)
    r = do_translate(locale, s)
    return r if r
    
    if base != locale 
      r = do_translate(base, s)
      return r if r
    end
    
    raise Missing, locale, s if raise_mode != :no_raise
  end

  private

  def do_translate(locale, s)
    scopes.each(s) do |scoped_string|
      tr = do_translate_raw locale, scoped_string
      return tr if tr
    end

    record_missing locale, s
    nil
  end
  
  def do_translate_raw(locale, s)
    I18n.translate(s, :raise => true)
  rescue I18n::MissingTranslationData
    nil
  end
  
  #
  # log a missing translation and raise an exception 
  def record_missing(locale, s)
    @missing_translations ||= Set.new
    @missing_translations << [ locale,  s ]
    logger.warn "Missing translation: [#{locale}] #{s.inspect}"
  end
  
  public
  
  class Missing < RuntimeError
    attr :locale
    attr :string

    def initialize(opts)
      @locale, @string = *opts
    end

    def to_s
      "Missing translation: [#{locale}] #{string.inspect}"
    end
  end
end
