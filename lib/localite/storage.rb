require "etest"

module Localite::Storage
  def self.load(glob)
    Dir.glob(glob).each do |file|
      translations = load_file file
      translations.each do |locale, data|
        merge_translations(locale, data)
      end
    end
  end

  private
  
  def self.load_file(file)
    Localite.logger.warn "Load translations from #{file}"

    File.basename(file) =~ /(.*)\.([^\.]+)$/
    locale, format = $1, $2
    
    translations = case format
    when "yml"
      YAML.load File.read(file)
    when "json"
      JSON.parse File.read(file)
    else
      raise "Unsupported file format #{file.inspect}"
    end

    if locale.length == 2
      { locale => translations }
    else
      translations
    end
  end
  
  def self.each_full_key(hash, prefix=nil, &block)
    hash.to_a.sort_by(&:first).each do |k,v|
      k = "#{prefix}.#{k}" if prefix
      if v.is_a?(Hash)
        each_full_key v, k, &block
        next
      end

      yield k
    end
  end
  
  def self.merge_translations(locale, translations)
    each_full_key(translations) do |key|
      Localite.logger.info "[#{locale}] add entry: #{key}"
    end

    I18n.backend.send :merge_translations, locale, translations
  end
end
