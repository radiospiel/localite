class Localite::Backend::Tr 
  def self.parse(io, name=nil)
    new(io, name).parse
  end

  def self.load(file)
    new(File.open(file), file).parse
  end
  
  def initialize(io, name=nil)
    io = StringIO.new(io) if io.is_a?(String)
    @io = io
    @name = name
  end

  attr_reader :lineno, :indent, :name

  def parse(&block)
    return parse_(&block) if block_given?

    hash = {}
    parse_ do |k,v|
      duplicate_entry(k) if hash.key?(k)
      hash[k] = v
    end

    return hash
  end

  protected
  
  def duplicate_entry(k)
    msg = "[#{name}] " if name
    dlog "#{msg}Duplicate entry", k.inspect 
  end

  private
  
  #
  # --- add a one-line unread buffer to the @io -----------------------
  def eof?
    @unreadline.nil? && @io.eof?
  end

  def unreadline(line)
    @unreadline = line
  end
  
  def readline
    r = @unreadline || begin
      @lineno += 1
      @io.readline
    end

    @unreadline = nil
    r
  end
  
  #
  # -- TR scopes
  def register_scope(indent, name)
    @indent = indent
    @scopes = @scopes[0, indent]
    @scopes[indent] = name
  end
  
  def current_scope
    @scopes[0..@indent].compact.join(".")
  end
  
  def parse_(&block)
    @scopes = []
    @lineno = 0

    while !eof? do
      line = readline

      #
      # skip empty and comment lines
      next if line =~ /^\s*(#|$)/

      if line =~ /^(\s*)([^:]+):\s*\|\s*$/                # Start of a multiline entry?
        register_scope $1.length, $2
        yield current_scope, read_multiline_value
      elsif line =~ /^(\s*)([^:]+):\s*([^|].*)/           # A singleline entry?
        register_scope $1.length, $2
        value = $3.sub(/\s+$/, "")
        yield current_scope, evaluate(value) unless value.empty?
      else
        msg = name ? "#{name}(#{lineno})" : "Line #{lineno}"

        msg += ": format error in #{line.inspect}"
        dlog msg
        raise msg
      end
    end
  end

  def read_multiline_value
    value = []
    while !eof? do
      line = readline
      line =~ /^(\s*)(.*)$/
      line_indent = $1.length 
      
      #
      # all multiline entries have a higher indent than the current line.
      if line_indent <= indent
        unreadline(line)
        break
      end
      value << $2.sub(/\s+$/, "")
    end
    
    value.join("\n")
  end

  #
  # evaluate a string
  def evaluate(s)
    return s unless s[0] == s[-1] && (s[0] == 34 || s[0] == 39)

    s[1..-2].gsub(/\\(.)/m) do
      case $1
      when "n"  then "\n"
      when "t"  then "\t"
      else      $1
      end
    end
  end
end

module Localite::Backend::Tr::Etest
  def evaluate(s)
    Localite::Backend::Tr.new("").send(:evaluate, s)
  end

  def test_tr_file
    d = Localite::Backend::Tr.load(File.dirname(__FILE__) + "/../../test/i18n/en.tr")
    assert_kind_of(Hash, d)
  end
  
  def test_eval_string_prereq
    assert_equal 34, '""'[0]
    assert_equal 34, '""'[-1]
    assert_equal 39, "''"[0]
  end
  
  def test_eval_string
    assert_equal "ab\nc", evaluate("'ab\nc'")
    assert_equal "ab\ncdef", evaluate('"ab\ncdef"')
    assert_equal "ab\tcd\nef", evaluate('"ab\tcd\nef"')
    assert_equal "abbcd", evaluate('"ab\bcd"')
    assert_equal "en/outer/inner/y1", evaluate("\"en/outer/inner/y1\"")
  end
  
  def test_parse_tr
    tr = <<-TR
#
# comment
param: "{* xxx *}"
base: "en_only"
t: "en.t"
#
# another comment
outer:
  inner:
    x1: "en/outer/inner/x1"
  inner:
    y1: "en/outer/inner/y1"
title: "This is hypertext"
title2: "This is <> hypertext"

ml: |
  mlmlml
ml: mlober

outer: |
  A first multiline
  entry
outer: Hey Ho!
outer: |
  A multiline
  entry
TR

    p = Localite::Backend::Tr.new(tr)
    p.stubs(:dlog) {}
    data = p.parse

    assert_equal("en/outer/inner/x1", data["outer.inner.x1"])
    assert_equal(nil, data["outer.inner"])
    assert_equal("A multiline\nentry", data["outer"])
    assert_equal("mlober", data["ml"])
    assert_kind_of(Hash, data)
  end

  def test_parse_tr_invalid
    tr = <<-TR

ml: | av
  mlmlml
ml: mlober
TR

    p = Localite::Backend::Tr.new(tr)
    p.stubs(:dlog) {}
    assert_raise(RuntimeError) {
      p.parse
    }
  end

  def test_parse_from_io
    tr = "  ml: mlober"
    d = Localite::Backend::Tr.parse(tr)
    assert_equal({"ml" => "mlober"}, d)
  end
end
