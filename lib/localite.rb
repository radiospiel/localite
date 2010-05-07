require "logger"

#
# This is a *really* simple template and translation engine.
#
# TODO: Use erubis instead of this simple engine...

module Localite; end

file_dir = File.expand_path(File.dirname(__FILE__))

# require "#{file_dir}/localite/missing_translation"
require "#{file_dir}/localite/scope"
require "#{file_dir}/localite/settings"
require "#{file_dir}/localite/translate"
require "#{file_dir}/localite/template"

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
    klass = if defined?(ActiveSupport)
      ActiveSupport::BufferedLogger
    else
      ::Logger
    end

    @logger ||= klass.new("log/localite.log")
  end
  
  extend Settings
  extend Translate
  extend Scope

  public
  
  #
  # Translating a string:
  #
  # If no translation is found we try to translate the string in the base 
  # language. If there is no base language translation we return the 
  # string, assuming a base language string.
  module StringAdapter
    def t(*args)
      translated = Localite.translate(self, :no_raise) || self
      Template.run :text, translated, *args
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
      translated = Localite.translate(self, :do_raise)
      Template.run :text, translated, *args
    end

    # returns nil, if there is no translation.
    def t?(*args)
      translated = Localite.translate(self, :no_raise)
      Template.run :text, translated, *args if translated
    end
  end
end

module Localite::Etest

  #
  # make sure .t actually runs the Template engine
  def test_tmpl
    assert_equal "xyz",                   "xyz".t(:xyz => "abc")
    assert_equal "abc",                   "{*xyz*}".t(:xyz => "abc")
  end

  def test_base_lookup
    assert !I18n.load_path.empty?
    
    assert_equal("en.t", "t".t)
    Localite.in("en") { 
      assert_equal("en.t", "t".t )
    }
    
    Localite.in("de") { 
      assert_equal("de.t", "t".t )
    }
    
    assert_equal("de.t", Localite.in("de") { "t".t })
  end
  
  def test_lookup_de
    Localite.in("de") do
      # flat translation
      assert_equal "de.t", "t".t

      Localite.scope(:outer, :inner) do
        assert_equal("de/outer/inner/x1", "x1".t)
      end
  
      # Miss "x1", and don't translate missing entries
      assert_equal("x1", "x1".t)
    end
  end
  
  def test_lookup_in_base
    Localite.in("en") do
      # lookup "base" in base translation
      assert_equal "en_only", "base".t
    end

    Localite.in("de") do
      # lookup "base" in base (i.e. en) translation
      assert_equal "en_only", "base".t
    end
  end
  
  def test_lookup_en
    Localite.in("en") do

      # flat translation
      assert_equal "en.t", "t".t

      Localite.scope(:outer, :inner, :x1) do
        assert_equal("en/outer/inner/x1", "x1".t)
      end
  
      # Miss "x1", and don't translate missing entries
      assert_equal("x1", "x1".t)
    end
  end
  
  def test_lookup_no_specific_lang
    # flat translation
    assert_equal "en.t", "t".t

    Localite.scope(:outer, :inner, :x1) do
      assert_equal("en/outer/inner/x1", "x1".t)
    end

    # Miss "x1", and don't translate missing entries
    assert_equal("x1", "x1".t)
  end

   
#   def test_html
#     assert_equal ">",                      "{*'>'*}".t(:xyz => [1, 2, 3], :fl => [1.0])
#     assert_equal "&gt;",                   "{*'>'*}".t(:html, :xyz => [1, 2, 3], :fl => [1.0])
#     assert_equal "3 Fixnums > 1 Float",    "{*pl xyz*} > {*pl fl*}".t(:xyz => [1, 2, 3], :fl => [1.0])
#     assert_equal "3 Fixnums &gt; 1 Float", "{*pl xyz*} > {*pl fl*}".t(:html, :xyz => [1, 2, 3], :fl => [1.0])
#   end
# 
#   def test_tmpl
# #    assert_equal "3 chars", "{*len*} chars".t(:len => 3)
#     assert_equal "3 chars", "{*length*} chars".t(:length => 3)
#   end
end
