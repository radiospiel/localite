#
# This is a *really* simple template and translation engine.
#
# TODO: Use erubis instead of this simple engine...

module Localite; end

file_dir = File.expand_path(File.dirname(__FILE__))

require "#{file_dir}/localite/missing_translation"
require "#{file_dir}/localite/scope"
require "#{file_dir}/localite/settings"
require "#{file_dir}/localite/translate"

module Localite
  #
  # Add the Localite adapters for Strings ad Symbols.
  def self.init
    String.send :include, StringAdapter
    Symbol.send :include, SymbolAdapter
  end

  #
  # a logger
  def self.logger
    @logger ||= ActiveSupport::BufferedLogger.new("log/localite.log")
  end
  
  extend Settings
  extend Translate

  public
  
  #
  # Translating a string:
  #
  # If no translation is found we try to translate the string in the base 
  # language. If there is no base language translation we return the 
  # string, assuming a base language string.
  module StringAdapter
    def t(*args)
      translated = Localite.translate(self) || self
      Templates.run translated, *args
    end
  end

  #
  # Translating a string:
  #
  # If no translation is found we try to translate the string in the base 
  # language. If there is no base language translation we raise areturn the 
  # string, assuming a base language string.
  module SymbolAdapter
    def t(*args)
      translated = Localite.translate(self) || raise
      Templates.run translated, *args
    end

    # returns nil, if there is no translation.
    def t?(*args)
      t *args
    rescue Localite::MissingTranslation
      nil
    end
  end
end

module Localite::Etest
  
  def test_tmpl
    assert_equal "xyz",                   "xyz".t(:xyz => "abc")
    assert_equal "abc",                   "{*xyz*}".t(:xyz => "abc")
    assert_equal "3",                     "{*xyz.length*}".t(:xyz => "abc")
    assert_equal "3",                     "{*xyz.length*}".t(:xyz => "abc")
    assert_equal "3 items",               "{*pl 'item', xyz.length*}".t(:xyz => "abc")
    assert_equal "3 Fixnums",             "{*pl xyz*}".t(:xyz => [1, 2, 3])
    assert_equal "3 Fixnums and 1 Float", "{*pl xyz*} and {*pl fl*}".t(:xyz => [1, 2, 3], :fl => [1.0])
   end


  def test_html
    assert_equal ">",                      "{*'>'*}".t(:xyz => [1, 2, 3], :fl => [1.0])
    assert_equal "&gt;",                   "{*'>'*}".t(:html, :xyz => [1, 2, 3], :fl => [1.0])
    assert_equal "3 Fixnums > 1 Float",    "{*pl xyz*} > {*pl fl*}".t(:xyz => [1, 2, 3], :fl => [1.0])
    assert_equal "3 Fixnums &gt; 1 Float", "{*pl xyz*} > {*pl fl*}".t(:html, :xyz => [1, 2, 3], :fl => [1.0])
  end

  def test_tmpl
#    assert_equal "3 chars", "{*len*} chars".t(:len => 3)
    assert_equal "3 chars", "{*length*} chars".t(:length => 3)
  end
end


__END__


module Templates
  module Helpers
    def self.html(s)
      CGI.escapeHTML s
    end
    
    def self.hi(s)
      "&ldquo;" + CGI.escapeHTML(s) + "&rdquo;"
    end

    def self.pl(name, count=nil)
      return pl name.first.class.name.camelize, name.length if count.nil?
      "#{count} #{count != 1 ? name.pluralize : name.singularize}"
    end
  end
  
  class Env < DelegateSlate
    def initialize(hosts)
      super hosts, Helpers
    end

    def [](code)
      r = eval(code)
      r = r.name if r.respond_to?(:name)
      r.to_s 
    end

    public :eval
  end
  
  def self.run(template, *environments)
    return template unless template.is_a?(String)

    options = environments.select do |env|
      env.is_a?(Symbol)
    end

    environments -= options
    environments.map do |env|
      env.is_a?(Hash) ? env.easy_access : env
    end
    
    env = Env.new(environments)

    parts = []
    last_idx = 0
    while idx = template.index(/\{\*([^\}]+?)\*\}/, last_idx)
      parts << template[last_idx, idx-last_idx] if idx > last_idx
      parts << env[$1]
      last_idx = idx + $&.length
    end
    parts << template[last_idx..-1]

    options.inject(parts.join) do |s, opt|
      Helpers.send opt, s
    end
  end
end
