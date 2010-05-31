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
    
    formats = [ current_format, :html, :text, nil ]
    
    [ current_locale, base ].uniq.each do |locale|
      scopes.each(s) do |scoped_string|
        formats.each do |source_format|
          next unless tr = translate_via_i18n(locale, source_format, scoped_string)
          #
          # reformat: if source format is text and target format is *ml:
          if source_format != current_format &&  source_format == :text
            tr = Localite::Format.send(current_format, tr)
          end
          return tr
        end
      end
    end
    
    record_missing current_locale, scopes.first(s)
    return if raise_mode == :no_raise
    
    raise Missing, [current_locale, s, scopes, formats.first]
  ensure
    I18n.locale = old_i18n_locale
  end

  private
  
  def translate_via_i18n(locale, fmt, str)
    I18n.locale = locale
    str = "#{fmt}.#{str}" if fmt
    
    I18n.translate(str, :raise => true)
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
    attr_reader :locale, :string, :scope, :format

    def initialize(opts)
      @locale, @string, @scope, @format = *opts

      @string = @string.to_s.dup unless @string.is_a?(Symbol)      
      @scope = @scope.dup
    end

    def to_s
      "Missing translation: [#{format}/#{locale}] #{string.inspect} (in scope #{scope.inspect})"
    end
  end
end
