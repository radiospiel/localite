require "etest"

module Localite::Storage
  def self.load(glob)
    Dir.glob(glob).each do |file|
      load_file file
    end 
  end
  
  def self.load_file(file)
    File.basename(file) =~ /(.*)\.([^\.]+)$/
    locale, format = $1, $2
    
    translations = self.send "load_#{format}", file
    
    if locale.length == 2
      merge_translations locale, translations
    else
      translations.each do |locale, data|
        merge_translations(locale, data)
      end
    end
  end

  private
  
  def self.load_yml(file)
    YAML.load File.read(file)
  end
  
  def self.load_json(file)
    JSON.parse File.read(file)
  end
  
  def self.merge_translations(locale, translations)
    I18n.backend.send :merge_translations, locale, translations
  end
end
