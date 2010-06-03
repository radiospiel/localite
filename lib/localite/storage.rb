require 'i18n'
require 'stringio'

module Localite
  module Backend; end
end

require "#{File.dirname(__FILE__)}/tr"

class Localite::Backend::Simple < I18n::Backend::Simple
  # Loads a single translations file by delegating to #load_rb or
  # #load_yml depending on the file extension and directly merges the
  # data to the existing translations. Raises I18n::UnknownFileType
  # for all other file extensions.
  def load_file(filename)
    type = File.extname(filename).tr('.', '').downcase
    raise UnknownFileType.new(type, filename) unless respond_to?(:"load_#{type}")
    
    data = send :"load_#{type}", filename

    #
    # 
    locale_from_file = File.basename(filename).sub(/\.[^\.]+$/, "")

    if locale_from_file.length == 2 && data.keys.map(&:to_s) != [ locale_from_file ]
      merge_translations(locale_from_file, data) 
    else
      data.each { |locale, d| merge_translations(locale, d) }
    end
  end

  #
  # add an additional translation storage layer.
  def merge_translations(locale, data)
    translations_for_locale!(locale).update data
    super
  end
  
  def translations
    @translations ||= {}
  end
  
  def translations_for_locale(locale)
    translations[locale.to_sym]
  end

  def translations_for_locale!(locale)
    translations[locale.to_sym] ||= {}
  end
  
  #
  # monkeypatches "I18n::Backend::Simple"
  #
  # Looks up a translation from the translations hash. Returns nil if
  # eiher key is nil, or locale, scope or key do not exist as a key in the
  # nested translations hash. Splits keys or scopes containing dots
  # into multiple keys, i.e. <tt>currency.format</tt> is regarded the same as
  # <tt>%w(currency format)</tt>.
  def lookup(locale, key, scope = [], options = {})
    return unless key
    init_translations unless initialized?
    keys = I18n.normalize_keys(locale, key, scope, options[:separator])
    
    #
    # the first key is the locale; all other keys make up the final key.
    lookup_localite_storage(*keys) || begin
      keys.inject(translations) do |result, key|
        key = key.to_sym
        return nil unless result.is_a?(Hash) && result.has_key?(key)
        result = result[key]
        result = resolve(locale, key, result, options) if result.is_a?(Symbol)
        String === result ? result.dup : result
      end
    end
  end

  def lookup_localite_storage(locale, *keys)
    return nil unless tr = translations_for_locale(locale)
    r = tr[keys.join(".")]
  end
    
  #
  # The main differences to a yaml file are: ".tr" files support 
  # specific and lower level entries for the same key, and allows
  # to reopen a key.
  #
  # x:
  #   y: "x.y translation"
  #     z: "x.y.z translation"
  #   y: 
  #     a: "x.y.a translation"
  #
  def self.load_tr(filename)
    Localite::Backend::Tr.load(filename)
  end
end
