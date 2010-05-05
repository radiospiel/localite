module Localite::Scope
  #
  # scope allows to set a scope around a translation. A scoped translation
  # 
  #   Localite.scope("scope") do
  #     "msg".t
  #   end
  #
  # will look up "scope.msg" and "msg", in that order, and return the first
  # matching translation in the current locale. Scopes can be stacked; looking
  # up a scoped  translation
  #   Localite.scope("outer") do
  #     Localite.scope("scope") do
  #       "msg".t
  #     end
  #   end
  #
  # will look up "outer.scope.msg", "scope.msg", "msg".
  #
  # If no translation will be found we look up the same entries in the base
  # locale.
  def scope(s, &block)
    scopes.push(s)
    yield
  ensure
    scopes.pop
  end
  
  def scopes
    Thread.current[:"localite:scopes"] ||= Scopes.new
  end

  private
  
  class Scopes < Array
    def each(s)
      @scopes.reverse_each do |entry| 
        yield "#{entry}.#{s}"
      end
      yield s
    end 
      
    def push(s)
      super "#{last}.#{s}"
    end
  end
end
