require "nokogiri"

module Localite::NodeFilter
  #
  # set up filter for this action.
  def self.filter(controller, &block)
    yield
      
    return unless controller.response.headers["Content-Type"] =~ /text\/html/
    r = controller.response
    r.body = filter_body r.body, Localite.current_locale
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

  def self.filter_body(body, locale)
    if body =~ /(<body[^>]*>)(.*)(<\/body>)/m
      $`.html_safe + 
      $1.html_safe +
      filter_node($2, locale).html_safe + 
      $3.html_safe + 
      $'.html_safe
    else
      filter_node(body, locale).html_safe
    end
  end
  
  def self.filter_node(body, locale)
    locale = locale.to_s

    body = fb_mark(body)
    
    doc = Nokogiri.HTML body
    doc.css("[lang]").each do |node|
      next unless locale != node["lang"]
      node.remove
    end

    doc = doc.css("body").inner_html
    doc = fb_unmark(doc)
    doc.html_safe
  end

  #
  # for <fb:XXXXXX> tags to survive Nokogiri's HTML parsing we rename 
  # them into something non-namespacy. THIS IS A HACK! I wished I knew 
  # how to make
  #
  # a) Nokogiri.XML to let entities live, or, preferredly
  # b) Nokogiri.HTML to let namespaces survive
  #
  FB =            "fb:"
  FB_RE =         /(<|<\/)fb:/
  FB_MARKER =     "fb_marker_0xjgh_123_"
  FB_MARKER_RE =  Regexp.new "(<|<\/)#{FB_MARKER}"
  
  def self.fb_mark(s)
    s.gsub(FB_RE) { $1 + FB_MARKER }
  end
  
  def self.fb_unmark(s)
    s.gsub(FB_MARKER_RE) { $1 + FB }
  end
end

module Localite::NodeFilter::Etest
  def normalize_xml(str)
    str.
      gsub(/>(.*?)</m) do |s| ">#{$1.gsub(/\s+/m, " ")}<" end.  # normalize spaces between tags
      gsub(/>\s*</m, ">\n<").                                   # normalize spaces in empty text nodes
      gsub(/"/, "'")                                            # normalize ' and "
  end
  
  def assert_filtered(locale, src, expected)
    filtered = Localite::NodeFilter.filter_body(src, locale)
    filtered = normalize_xml(filtered)

    expected = normalize_xml(expected)

    if expected == filtered
      assert true
      return
    end

    puts "expected:\n\n" + expected + "\n\n"
    puts "filtered:\n\n" + filtered + "\n\n"
    
    assert_equal expected, filtered
  end
  
  ## 
  def test_normalize_xml
    assert_equal "<p>ppp</p>", normalize_xml("<p>ppp</p>")
    assert_equal "<p>a b c </p>\n", normalize_xml("<p>a   b c </p>\n")
  end
  
  def test_simple_html
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

  def test_full_html_match
    src = <<-HTML
<!--Force IE6 into quirks mode with this comment tag-->
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <title>socially.io</title>
  </head>
  <body x="y">
    <p lang='de'>&Auml; &Ouml;</p>", "<p lang='de'>&Auml; &Ouml;</p>
  </body>
</html>
HTML

    expected = <<-HTML
<!--Force IE6 into quirks mode with this comment tag-->
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <title>socially.io</title>
  </head>
  <body x="y">
    <p lang='de'>&Auml; &Ouml;</p>", "<p lang='de'>&Auml; &Ouml;</p>
  </body>
</html>
HTML

    assert_filtered :de, src, expected
  end

  def test_full_html_miss
    src = <<-HTML
<!--Force IE6 into quirks mode with this comment tag-->
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <title>socially.io</title>
  </head>
  <body x="y">
    <p lang='de'>&Auml; &Ouml;</p>
  </body>
</html>
HTML

    expected = <<-HTML
<!--Force IE6 into quirks mode with this comment tag-->
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <title>socially.io</title>
  </head>
  <body x="y">
  </body>
</html>
HTML

    assert_filtered :en, src, expected
  end
end
