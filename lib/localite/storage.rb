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
