class Localite::MissingTranslation < RuntimeError
  attr :locale
  attr :string
  
  def initialize(opts)
    @locale, @string = *opts
  end
  
  def to_s
    "Missing translation: [#{locale}] #{string.inspect}"
  end

  #
  # log a missing translation and raise an exception 
  def self.record!(locale, s)
    entry = [ locale,  s ]

    @missing_translations ||= Set.new
    unless @missing_translations.include?(entry)
      @missing_translations << entry
    
      msg = "Missing translation: [#{locale}] #{s.inspect}"
      Localite::logger.warn msg
    end
    
    raise self, entry
  end
end
