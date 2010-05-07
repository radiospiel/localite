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

  #
  # The mode setting defines how the template engine deals with its
  # parameters. In :html mode all parameters will be subject to HTML
  # escaping, while in :text mode the parameters remain unchanged.
  def html(&block)
    in_mode :html, &block
  end

  def text(&block)
    in_mode :text, &block
  end
  
  def mode
    Thread.current[:"localite:mode"] || :text
  end
  
  private

  def in_mode(mode, &block)
    old = Thread.current[:"localite:mode"]
    Thread.current[:"localite:mode"] = mode
    yield
  ensure
    Thread.current[:"localite:mode"] = old
  end
  
  
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
  
    def first(s)
      each(s) do |entry|
        return entry
      end
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
  
  def test_more_scopes_w_dots
    Localite.scope("a", :b, "b.c.d") do 
      r = []
      Localite.scopes.each("str.y") do |scoped|
        r << scoped
      end
      assert_equal %w(a.b.b.c.d.str.y a.b.str.y a.str.y str.y), r
    end
  end
  
  def test_empty_scopes
    r = []
    Localite.scopes.each("str.y") do |scoped|
      r << scoped
    end
    assert_equal %w(str.y), r
  end

  def test_modi
    assert_equal "abc", "param".t(:xxx => "abc")
    assert_equal "a > c", "param".t(:xxx => "a > c")
    assert_equal "a > c", Localite.text { "param".t(:xxx => "a > c") }
    assert_equal "a &gt; c", Localite.html { "param".t(:xxx => "a > c") }
    assert_equal "a > c", "param".t(:xxx => "a > c")
  end
end
