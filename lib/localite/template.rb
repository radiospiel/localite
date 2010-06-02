require "cgi"

class Localite::Template < String
  def self.run(template, opts = {})
    new(template).run(Localite.current_format, opts)
  end

  def self.html(template, opts = {})
    new(template).run(:html, opts)
  end

  def self.text(template, opts = {})
    new(template).run(:text, opts)
  end

  #
  # the environment during run
  class Env
    module Helpers
      # def html(s)
      #   CGI.escapeHTML s
      # end
      # 
      # def hi(s)
      #   "&ldquo;" + CGI.escapeHTML(s) + "&rdquo;"
      # end

      #
      # pluralize something and add count
      # pl("apple", 1) -> "1 apple"
      # pl("apple", 2) -> "2 apples"
      #
      # Note a special case on arrays:
      # pl(%w(apple peach cherry)) -> "3 Strings"
      def pl(name, count=nil)
        if count
          "#{count} #{count != 1 ? name.pluralize : name.singularize}"
        elsif name.respond_to?(:first) && !name.is_a?(String)
          pl name.first.class.name, name.length # special case, see above.
        else
          name.pluralize
        end
      end
    end

    def method_missing(sym, *args, &block)
      unless @host.is_a?(Hash)
        return @host.send(sym, *args, &block)
      end
      
      begin
        return @host.fetch(sym.to_sym)
      rescue IndexError
        :void
      end
      
      begin
        return @host.fetch(sym.to_s)
      rescue IndexError
        :void
      end

      super
    end
    
    def initialize(host)
      @host = host
      extend Helpers
    end

    def [](code)
      eval(code).to_s
    end
  end
  
  def run(format, opts = {})

    #
    env = Env.new(opts)

    #
    # get all --> {* code *} <-- parts from the template strings and send
    # them thru the environment.
    gsub(/\{\*([^\}]+?)\*\}/) do |_|
      Localite::Format.send format, env[$1]
    end
  end
end

module Localite::Template::Etest
  Template = Localite::Template
  
  def test_templates
    assert_equal "abc",                   Template.text("{*xyz*}", :xyz => "abc")
    assert_equal "3 items",               Template.text("{*pl 'item', xyz.length*}", :xyz => "abc")
    assert_equal "xyz",                   Template.text("xyz", :xyz => "abc")
    assert_equal "abc",                   Template.text("{*xyz*}", :xyz => "abc")
    assert_equal "3",                     Template.text("{*xyz.length*}", :xyz => "abc")
    assert_equal "3",                     Template.text("{*xyz.length*}", :xyz => "abc")
    assert_equal "3 Fixnums",             Template.text("{*pl xyz*}", :xyz => [1, 2, 3])
    assert_equal "3 Fixnums and 1 Float", Template.text("{*pl xyz*} and {*pl fl*}", :xyz => [1, 2, 3], :fl => [1.0])
  end

  class Name < String
    def name
      self
    end
  end
  
  def test_nohash
    assert_equal "abc",                   Template.text("{*name*}", Name.new("abc"))
  end

  def test_pl
    h = Object.new.extend(Localite::Template::Env::Helpers)
    assert_equal      "1 apple", h.pl("apple", 1)
    assert_equal      "2 apples", h.pl("apple", 2)
    assert_equal      "1 apple", h.pl("apples", 1)
    assert_equal      "2 apples", h.pl("apples", 2)

    assert_equal      "apples", h.pl("apples")
    assert_equal      "apples", h.pl("apple")
    
    assert_equal      "3 Strings", h.pl(%w(apple peach cherry))
  end

  def test_html_env
    assert_equal "a>c",                 Template.text("{*xyz*}", :xyz => "a>c")
    assert_equal "a&gt;c",              Template.html("{*xyz*}", :xyz => "a>c")
    assert_equal "> a>c",               Template.text("> {*xyz*}", :xyz => "a>c")
    assert_equal "> a&gt;c",            Template.html("> {*xyz*}", :xyz => "a>c")
  end

  def test_template_hash
    assert_equal "a>c",                 Template.text("{*xyz*}", :xyz => "a>c")
    assert_equal "a>c",                 Template.text("{*xyz*}", "xyz" => "a>c")
  end

  def test_template_hash_missing
    assert_raise(NameError) {
      Template.text("{*abc*}", :xyz => "a>c")
    }
  end
end
