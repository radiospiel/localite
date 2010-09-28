module Localite::Format
  #
  # convert from text into target format
  def self.text(s)
    case s
    when /html:(.*)/m then $1
    when /text:(.*)/m then $1
    else              s
    end
  end

  def self.html(s)
    case s
    when /html:(.*)/m then $1
    when /text:(.*)/m then CGI.escapeHTML($1)
    else              CGI.escapeHTML(s)
    end
  end
end

module Localite::Format::Etest
  def test_format
    assert_equal "xxx", Localite::Format.html("xxx")
    assert_equal "xxx", Localite::Format.html("html:xxx")
    assert_equal "xxx", Localite::Format.html("text:xxx")
    
    assert_equal "&lt;&gt;", Localite::Format.html("text:<>")
    assert_equal "&lt;&gt;", Localite::Format.html("<>")
    assert_equal "<>", Localite::Format.html("html:<>")

    assert_equal "xxx\nyyy", Localite::Format.html("xxx\nyyy")
    assert_equal "xxx\nyyy", Localite::Format.html("html:xxx\nyyy")
    assert_equal "xxx\nyyy", Localite::Format.html("text:xxx\nyyy")
  end
end
