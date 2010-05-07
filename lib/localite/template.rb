class Localite::Template < String
  def self.run(mode, template, opts = {})
    new(template).run(mode, opts)
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
        elsif name.respond_to?(:first)
          pl name.first.class.name, name.length # special case, see above.
        else
          name.pluralize
        end
      end
    end

    def method_missing(sym, *args, &block)
      begin
        return @host[sym.to_sym]
      rescue IndexError
      end

      begin
        return @host[sym.to_s]
      rescue IndexError
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
  
  def run(mode, opts = {})
    #
    env = Env.new(opts)

    #
    # get all --> {* code *} <-- parts from the template strings and send
    # them thru the environment.
    r = gsub(/\{\*([^\}]+?)\*\}/) do |_|
      env[$1]
    end
    
    Modi.send(mode, r)
  end

  module Modi
    def self.text(s)
      s
    end

    def self.html(s)
      CGI.escapeHTML s
    end
  end
end

module Localite::Template::Etest
  Template = Localite::Template
  
  def test_templates
    assert_equal "abc",                   Template.run(:text, "{*xyz*}", :xyz => "abc")
    assert_equal "3 items",               Template.run(:text, "{*pl 'item', xyz.length*}", :xyz => "abc")
    assert_equal "xyz",                   Template.run(:text, "xyz", :xyz => "abc")
    assert_equal "abc",                   Template.run(:text, "{*xyz*}", :xyz => "abc")
    assert_equal "3",                     Template.run(:text, "{*xyz.length*}", :xyz => "abc")
    assert_equal "3",                     Template.run(:text, "{*xyz.length*}", :xyz => "abc")
    assert_equal "3 Fixnums",             Template.run(:text, "{*pl xyz*}", :xyz => [1, 2, 3])
    assert_equal "3 Fixnums and 1 Float", Template.run(:text, "{*pl xyz*} and {*pl fl*}", :xyz => [1, 2, 3], :fl => [1.0])
  end

  def test_pl
    h = Object.new.extend(Localite::Template::Env::Helpers)
    assert_equal      "1 apple", h.pl("apple", 1)
    assert_equal      "2 apples", h.pl("apple", 2)
    assert_equal      "1 apple", h.pl("apples", 1)
    assert_equal      "2 apples", h.pl("apples", 2)
    
    assert_equal      "3 Strings", h.pl(%w(apple peach cherry))
  end

  def test_html_env
    h = Object.new.extend(Localite::Template::Env::Helpers)
    assert_equal      "1 apple", h.pl("apple", 1)
    assert_equal      "2 apples", h.pl("apple", 2)
    assert_equal      "1 apple", h.pl("apples", 1)
    assert_equal      "2 apples", h.pl("apples", 2)
    
    assert_equal      "3 Strings", h.pl(%w(apple peach cherry))
  end
end
