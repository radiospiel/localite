require "logger"
require "i18n"

#
# This is a *really* simple template and translation engine.
#
# TODO: Use erubis instead of this simple engine...

module Localite; end

file_dir = File.expand_path(File.dirname(__FILE__))

require "#{file_dir}/localite/scopes"
require "#{file_dir}/localite/settings"
require "#{file_dir}/localite/translate"
require "#{file_dir}/localite/template"

module Localite
  #
  # a logger
  def self.logger
    klass = defined?(ActiveSupport) ? ActiveSupport::BufferedLogger : Logger

    @logger ||= begin
      klass.new("log/localite.log")
    rescue Errno::ENOENT
      ::Logger.new(STDERR)
    end
  end
  
  extend Settings
  extend Translate

  private
  
  def self.template(template, *args)
    Template.run current_format, template, *args
  end

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
      Localite.template translated, *args
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
      Localite.template translated, *args
    end

    # returns nil, if there is no translation.
    def t?(*args)
      translated = Localite.translate(self, :no_raise)
      Localite.template translated, *args if translated
    end
  end
  
  #
  # == initialize Localite adapters =======================================
  ::String.send :include, StringAdapter
  ::Symbol.send :include, SymbolAdapter
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
    Localite.locale("en") { 
      assert_equal("en.t", "t".t )
    }
    
    Localite.locale("de") { 
      assert_equal("de.t", "t".t )
    }
    
    assert_equal("de.t", Localite.locale("de") { "t".t })
  end
  
  def test_lookup_de
    Localite.locale("de") do
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
    Localite.locale("en") do
      # lookup "base" in base translation
      assert_equal "en_only", "base".t
    end

    Localite.locale("de") do
      # lookup "base" in base (i.e. en) translation
      assert_equal "en_only", "base".t
    end
  end
  
  def test_lookup_en
    Localite.locale("en") do

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

  def test_lookup_symbols
    assert :base.t?
    
    assert_equal "en_only", :base.t

    Localite.locale("en") do
      assert_equal "en_only", :base.t
    end

    Localite.locale("de") do
      assert_equal "en_only", :base.t
    end
  end

  def test_missing_lookup_symbols
    assert !:missing.t?
    assert_raise(Localite::Translate::Missing) {
      assert_equal "en_only", :missing.t
    }

    Localite.locale("en") do
      assert_raise(Localite::Translate::Missing) {
        :missing.t
      }
    end

    Localite.locale("de") do
      assert_raise(Localite::Translate::Missing) {
        :missing.t
      }
    end

    begin
      :missing.t
    rescue Localite::Translate::Missing
      assert_kind_of(String, $!.to_s)
    end
  end

  def catch_exception(klass, &block)
    yield
    nil
  rescue klass
    $!
  end
  
  def test_missing_translation_wo_scope
    r = catch_exception(Localite::Translate::Missing) do 
      Localite.locale(:de) do
        :x.t
      end
    end
    
    assert_equal(:de, r.locale)
    assert_equal(:x, r.string)
    assert_equal([], r.scope)
  end

  def test_missing_translation_w_scope
    r = catch_exception(Localite::Translate::Missing) do 
      Localite.locale(:de) do
        Localite.scope(:ab, :cd) do
          :yx.t
        end
      end
    end
    
    assert_equal(:de, r.locale)
    assert_equal(:yx, r.string)
    assert_equal([:ab, :cd], r.scope)
#    assert_equal(:text, r.format)
  end

  def test_translation_with_types
    
  end
  
  def test_default_format
    assert_equal "abc", "param".t(:xxx => "abc")
    assert_equal "a > c", "param".t(:xxx => "a > c")
    assert_equal "abc", "param".t(:xxx => "abc")
  end

  def test_text_format
    assert_equal "a > c", Localite.format(:text) { "param".t(:xxx => "a > c") }
  end

  def test_html_format
    Localite.format(:html) { 
      assert_equal(:html, Localite.current_format)
      assert_equal "a &gt; c", "param".t(:xxx => "a > c")
    }
    
    assert_equal "a &gt; c", Localite.format(:html) { "param".t(:xxx => "a > c") }
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
