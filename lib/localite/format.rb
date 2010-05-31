module Localite::Format
  #
  # convert from text into target format
  def self.text(s)
    s 
  end

  def self.html(s)
    CGI.escapeHTML(s)
  end
  
  def self.fbml(s)
    html s
  end
end
