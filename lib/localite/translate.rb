module Localite::Translate
  # 
  # translate a string 
  #
  # returns the translated string or symbol in the current locale.
  # If no translation is found try the base locale. If still no
  # translation is found, then
  # a) return the string if a string was passed in, or
  # b) raise an exception if a symbol was passed in.
  # 
  def translate(s)
    tr = translate_scoped(s)
    return tr if tr

    tr = (locale != base) && self.in(base) do translate_scoped(s) end
    return tr if tr

    return s  if s.is_a?(String)

    s = "#{scopes.join(".")}.#{s}" unless scopes.empty?

    MissingTranslation.record! locale, s
  end
end