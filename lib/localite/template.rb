module Localite::Template
  module Helpers
    def html(s)
      CGI.escapeHTML s
    end
    
    def hi(s)
      "&ldquo;" + CGI.escapeHTML(s) + "&rdquo;"
    end

    def pl(name, count=nil)
      return pl name.first.class.name.camelize, name.length if count.nil?
      "#{count} #{count != 1 ? name.pluralize : name.singularize}"
    end
  end
  
  class Env
    def method_missing(sym, *args, &block)
      sym = sym.to_sym
      return @host[sym] if @host.key?(sym)

      sym = sym.to_s
      return @host[sym] if @host.key?(sym)
      
      super
    end
    
    def initialize(host)
      @host = host
    end

    def [](code)
      r = eval(code)
      r = r.name if r.respond_to?(:name)
      r.to_s 
    end

    public :eval
  end
  
  def self.run(template, opts = {})
    #
    env = Env.new(opts).extend(Helpers)

    #
    # get all --> {* code *} <-- parts from the template strings and send
    # them thru the environment.
    template.gsub(/\{\*([^\}]+?)\*\}/) do |_|
      env[$1]
    end
  end
end
