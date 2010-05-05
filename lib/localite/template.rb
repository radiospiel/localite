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
    end

    def [](code)
      eval(code).to_s
    end
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
