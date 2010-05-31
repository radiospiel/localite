class Localite::Scopes < Array
  def initialize
    @prebuilt = []
  end
  
  def push(*array)
    array.each do |s|
      prebuilt = "#{@prebuilt.last}.#{s}" if @prebuilt.last
      @prebuilt.push(prebuilt || s)
      super(s)
    end
  end
  
  def pop(*array)
    array.each do 
      @prebuilt.pop
      super()
    end
  end
  
  def each(s)
    @prebuilt.reverse_each do |entry| 
      yield "#{entry}.#{s}"
    end

    yield s
  end

  def first(s)
    if @prebuilt.last
      "#{@prebuilt.last}.#{s}"
    else
      s
    end
  end
end

module Localite::Scopes::Etest
  Scopes = Localite::Scopes
  
  def test_scope
    scope = Scopes.new

    scope.push("a") 
    scope.push("b")
    scope.push("b", "str")

    assert_equal %w(a b b str), scope
    assert_equal %w(a.b.b.str a.b.b a.b a), scope.instance_variable_get("@prebuilt").reverse
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
end
