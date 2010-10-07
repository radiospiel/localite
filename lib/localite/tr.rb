class Localite::Backend::Tr 
  #
  # This class handles line reading from ios (files, etc.) and strings.
  # It offers an one-line unread buffer.
  class IO
    attr_reader :lineno

    def initialize(src)
      @lineno = 0
      @io = if src.is_a?(String)
        StringIO.new(src)
      else
        src
      end
    end

    def eof?
      @unreadline.nil? && @io.eof?
    end

    def unreadline(line)
      @unreadline = line
    end

    def readline
      r, @unreadline = @unreadline, nil
      r || begin
        @lineno += 1
        @io.readline
      end
    end
  end

  def self.parse(io, name=nil, &block)
    new(io, name).parse(&block)
  end

  def self.load(filename, &block)
    File.open(filename) do |file|
      new(file, filename).parse(&block)
    end
  end

  def initialize(src, name=nil)
    @src, @name = src, name
  end
  
  attr_reader :indent, :name

  def keys
    return @keys if @keys

    if @parse
      @keys = @parse.keys
    else
      @keys = []
      parse_ do |k,_|
        @keys << k
      end
      @keys.uniq!
    end

    @keys.sort!
  end

  def parse(&block)
    if block_given?
      parse_(&block)
    else
      @parse ||= begin
        hash = {}
        parse_ do |k,v|
          duplicate_entry(k) if hash.key?(k)
          hash[k] = v
        end
        hash
      end
    end
  end

  protected
  
  def duplicate_entry(k)
    msg = "[#{name}] " if name
    Localite.logger.warn "#{msg}Duplicate entry" + k.inspect 
  end

  private

  #
  # -- TR scopes
  def register_scope(indent, name)
    @indent = indent
    @scopes = @scopes[0, indent]
    @scopes[indent] = evaluate(name)
  end
  
  def current_scope
    @scopes[0..@indent].compact.join(".")
  end

  def parse_(&block)
    @io = IO.new @src
    @scopes = []
    while !io.eof? do
      line = io.readline

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
        msg = name ? "#{name}(#{io.lineno})" : "Line #{io.lineno}"

        msg += ": format error in #{line.inspect}"
        dlog msg
        raise msg
      end
    end
  ensure
    @io = nil
  end

  attr_reader :io
  
  def read_multiline_value
    value = []
    while !io.eof? do
      line = io.readline
      line =~ /^(\s*)(.*)$/
      
      if $2.empty?
        value << ""
        next
      end

      line_indent = $1.length 
      
      #
      # all multiline entries have a higher indent than the current line.
      if line_indent <= indent
        io.unreadline(line)
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

    assert_equal(%w(base ml outer outer.inner.x1 outer.inner.y1 param t title title2), p.keys)
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
  
  def test_parse_key_names
    tr = <<TR
  a: aa
    "b.c": abc
    "b\\nc": anlc
    b.c: dot
TR

    d = Localite::Backend::Tr.parse(tr)
    assert_equal({"a"=>"aa", "a.b.c"=>"dot", "a.b\nc"=>"anlc"}, d)
  end
  
  def test_multiline_w_spaces
    tr = <<-TR
refresh:
  title:        t1
  info:           |
    line1
    line2

    line3
    line4
  title:        t2
TR

    p = Localite::Backend::Tr.new(tr)
    d = p.parse
    p.stubs(:dlog) {}
 
    assert_equal "line1\nline2\n\nline3\nline4", d["refresh.info"]
    assert_equal "t2", d["refresh.title"]
  end

end
