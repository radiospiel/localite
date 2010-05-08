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
    r = do_translate(locale, s)
    return r if r

    r = do_translate(base, s) if base != locale
    return r if r
    
    raise Missing, [locale, s] if raise_mode != :no_raise
  end

  private

  def do_translate(locale, s)
    scopes.each(s) do |scoped_string|
      tr = Localite::Translate.translate_via_i18n locale, scoped_string
      return tr if tr
    end

    record_missing locale, scopes.first(s)
    nil
  end
  
  def self.translate_via_i18n(locale, s)
    locale = base unless I18n.backend.available_locales.include?(locale)
    I18n.locale = locale
    I18n.translate(s, :raise => true)
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
