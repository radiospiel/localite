require "logger"
require "i18n"

#
# This is a *really* simple template and translation engine.
#
# TODO: Use erubis instead of this simple engine...

module Localite; end

file_dir = File.expand_path(File.dirname(__FILE__))

$: << file_dir
require "localite/format"
require "localite/scopes"
require "localite/settings"
require "localite/translate"
require "localite/template"
require "localite/storage"

module Localite
  #
  # a logger
  def self.logger
    return @logger if @logger
    
    klass = defined?(ActiveSupport) ? ActiveSupport::BufferedLogger : Logger

    @logger = begin
      klass.new("log/localite.log")
    rescue Errno::ENOENT
      ::Logger.new(STDERR)
    end
    
    @logger.warn "=== Initialize localite logging: #{Time.now}"
    @logger
  end
  
  extend Settings
  extend Translate

  #
  # Translating a string:
  #
  # If no translation is found we try to translate the string in the base language. 
  # If there is neither a current nor a base language translation this
  # raises Localite::Translating::Missing.
  module SymbolAdapter
    def t(*args)
      format = if args.first == :text || args.first == :html
        args.shift
      else
        Localite.current_format
      end

      Localite.format(format) do
        translated = Localite.translate(self)
        Localite::Template.run translated, *args
      end
    end
  end
  ::Symbol.send :include, SymbolAdapter

  #
  # Translating a string:
  #
  # If no translation is found we try to translate the string in the base language. 
  # If there is neither a current nor a base language translation this
  # returns nil.
  module StringAdapter
    def t(*args)
      format = if args.first == :text || args.first == :html
        args.shift
      else
        Localite.current_format
      end

      Localite.format(format) do
        translated = begin
          Localite.translate(self)
        rescue Localite::Translate::Missing
          self
        end

        Localite::Template.run translated, *args
      end
    end
  end
  ::String.send :include, StringAdapter
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

      Localite.scope(:outer, :inner) do
        assert_equal("en/outer/inner/x1", :x1.t)
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
    assert_equal "en_only", :base.t

    Localite.locale("en") do
      assert_equal "en_only", :base.t
    end

    Localite.locale("de") do
      assert_equal "en_only", :base.t
    end
  end

  def test_missing_lookup_symbols
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
      Localite.scope(:locale => :de, :format => :text) do
        :x.t
      end
    end
    
    assert_equal(:de, r.locale)
    assert_equal(:x, r.string)
    assert_equal("", r.scope)

    r = catch_exception(Localite::Translate::Missing) do 
      Localite.scope(:locale => :de, :format => :html) do
        :x.t
      end
    end
    
    assert_equal(:de, r.locale)
    assert_equal(:x, r.string)
    assert_equal("", r.scope)

    r = catch_exception(Localite::Translate::Missing) do 
      Localite.scope(:locale => :de) do
        :x.t
      end
    end
    
    assert_equal(:de, r.locale)
    assert_equal(:x, r.string)
    assert_equal("", r.scope)
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
    assert_equal("ab.cd", r.scope)
  end

  def test_reset_scope
    r = catch_exception(Localite::Translate::Missing) do 
      Localite.scope(:ab) do
        Localite.scope(:cd) do
          :yx.t
        end
      end
    end

    assert_equal("ab.cd", r.scope)

    r = catch_exception(Localite::Translate::Missing) do 
      Localite.scope(:ab) do
        Localite.scope!(:cd) do
          assert_equal([:cd], Localite.current_scope)
        end
        assert_equal([:ab], Localite.current_scope)

        Localite.scope!(:cd) do
          :yx.t
        end
      end
    end

    assert_equal("cd", r.scope)
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
  
  def test_format_scope
    Localite.format(:html) do
      assert_equal :html, Localite.current_format
      assert_equal("This is hypertext", :title.t)
      assert_equal("This is &lt;&gt; hypertext", :title2.t)
    end
    Localite.format(:text) do
      assert_equal :text, Localite.current_format
      assert_equal("This is hypertext", :title.t)
      assert_equal("This is <> hypertext", :title2.t)
    end
  end

  def test_unavailable
    Localite.locale("unknown") do
      assert_equal(:en, Localite.current_locale)
      assert_equal("This is hypertext", :title.t)
    end
  end

  def test_inspect
    assert_nothing_raised {
      Localite.inspect
    }
  end
end

