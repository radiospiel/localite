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
  def scope(*args, &block)
    return yield if args.empty?

    scopes.exec(args.shift) do
      scope *args, &block
    end
  end
  
  def scopes
    Thread.current[:"localite:scopes"] ||= Scopes.new
  end

  private
  
  class Scopes < Array
    def exec(s, &block)
      s = "#{last}.#{s}" if last
      push s
      
      yield
    ensure
      pop
    end
    
    def each(s)
      reverse_each do |entry| 
        yield "#{entry}.#{s}"
      end

      yield s
    end
  end
end

module Localite::Scope::Etest
  Scopes = Localite::Scope::Scopes
  
  def test_scope
    scope = Scopes.new
    scope.exec("a") do 
      scope.exec("b") do 
        scope.exec("b") do 
          r = []
          scope.each("str") do |scoped|
            r << scoped
          end
          assert_equal %w(a.b.b.str a.b.str a.str str), r
        end
      end
    end
  end
  
  def test_more_scopes
    Localite.scope("a", :b, "b") do 
      r = []
      Localite.scopes.each("str") do |scoped|
        r << scoped
      end
      assert_equal %w(a.b.b.str a.b.str a.str str), r
    end
  end
end
