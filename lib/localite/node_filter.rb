require "nokogiri"

module Localite::NodeFilter
  #
  # set up filter for this action.
  def self.filter(controller, &block)
    yield
      
    return unless controller.response.headers["Content-Type"] =~ /text\/html/
    r = controller.response
    r.body = filter_node r.body, Localite.current_locale
  rescue
    if Rails.env.development?
      controller.response.body = "Caught exception: " + CGI::escapeHTML($!.inspect) 
    end
    raise
  end

  def self.included(klass)
    klass.send :around_filter, self
  end

  private

  def self.filter_node(body, locale)
    locale = locale.to_s

    doc = Nokogiri.HTML fb_mark(body)
    doc.css("[lang]").each do |node|
      if locale != node["lang"]
        node.remove
        next
      end

      #
      # we have a node with content specific for the current locale,
      # i.e. a node to keep. If we find a base locale sibling (i.e. 
      # with identical attributes but no "lang" attribute) prior 
      # this node we have to remove that.
      next unless base = base_node(node)
      base.remove 
    end

    doc = doc.css("body").inner_html
    filtered = fb_unmark(doc.to_s)
  end

  def self.base_node(node)
    previous = node
    while (previous = previous.previous) && previous.name == "text" do
      :void
    end

    return previous if base_node?(node, previous)
  end

  #
  # is \a other_node the base_node? for \a me?
  def self.base_node?(me, other_node)
    return false if !other_node
    return false if me.name != other_node.name
    return false if other_node.attributes.key?("lang")
    return false if me.attributes.length != other_node.attributes.length + 1

    # do we have a mismatching attribute?
    other_node.attributes.each { |k,v| 
      return false if me.attributes[k] != v 
    }

    true
  end

  #
  # for <fb:XXXXXX> tags to survive Nokogiri's HTML parsing we rename 
  # them into something non-namespacy. THIS IS A HACK! I wished I knew 
  # how to make
  #
  # a) Nokogiri.XML to let entities live, or, preferredly
  # b) Nokogiri.HTML to let namespaces survive
  #
  module FbMarker
    FB =            "fb:"
    FB_RE =         /(<|<\/)fb:/
    FB_MARKER =     "fb_marker_0xjgh_123_"
    FB_MARKER_RE =  Regexp.new "(<|<\/)#{FB_MARKER}"
    
    def fb_mark(s)
      s.gsub(FB_RE) { $1 + FB_MARKER }
    end
    
    def fb_unmark(s)
      s.gsub(FB_MARKER_RE) { $1 + FB }
    end
  end

  extend FbMarker
end

module Localite::NodeFilter::Etest
  def normalize_xml(str)
    str.gsub(/>(.*?)</) do |s|
      ">#{$1.gsub(/\s+/, "")}<"
    end.gsub(/"/, "'")
  end
  
  def assert_filtered(locale, src, expected)
    filtered = Localite::NodeFilter.filter_node(src, locale)
    expected = normalize_xml(expected)
    filtered = normalize_xml(filtered)
    
    assert_equal expected, filtered
  end
  
  ## 
  def test_simple_html
    assert_equal "<p>ppp</p>", normalize_xml("<p>ppp</p>")
    assert_filtered :de, "<p>ppp</p>", "<p>ppp</p>"
    assert_filtered :en, "<p>ppp</p>", "<p>ppp</p>"
    assert_filtered :fr, "<p>ppp</p>", "<p>ppp</p>"
  end

  def test_simple_html_w_lang
    assert_filtered :de, "<p lang='de'>ppp</p>", "<p lang='de'>ppp</p>"
    assert_filtered :en, "<p lang='de'>ppp</p>", ""
    assert_filtered :fr, "<p lang='de'>ppp</p>", ""

    assert_filtered :de, "<p lang='en'>ppp</p>", ""
    assert_filtered :en, "<p lang='en'>ppp</p>", "<p lang='en'>ppp</p>"
    assert_filtered :fr, "<p lang='en'>ppp</p>", ""
  end

  def test_fbml_tags
    assert_filtered :de, "<fb:p lang='de'>ppp</fb:p>", "<fb:p lang='de'>ppp</fb:p>"
    assert_filtered :en, "<fb:p lang='de'>ppp</fb:p>", ""
    assert_filtered :fr, "<fb:p lang='de'>ppp</fb:p>", ""

    assert_filtered :de, "<fb:p lang='en'>ppp</fb:p>", ""
    assert_filtered :en, "<fb:p lang='en'>ppp</fb:p>", "<fb:p lang='en'>ppp</fb:p>"
    assert_filtered :fr, "<fb:p lang='en'>ppp</fb:p>", ""
  end

  def test_umlauts
    assert_filtered :de, "<p lang='de'>&Auml; &Ouml;</p>", "<p lang='de'>&Auml; &Ouml;</p>"

    #
    # Nokogiri translates UTF-8 umlauts into entities. That is ok (for now)
    assert_filtered :de, "<p lang='de'>Ä Ö</p>", "<p lang='de'>&Auml; &Ouml;</p>"
  end
end
