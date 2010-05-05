module Localite::Settings
  #
  # Returns the base locale; e.g. :en
  def base
    I18n.default_locale
  end

  #
  # returns the current locale; defaults to the base locale
  def locale
    I18n.locale
  end

  #
  # sets the current locale. If the locale is not available it changes
  # the locale to the default locale.
  def locale=(locale)
    locale = base unless I18n.backend.available_locales.include?(locale)
    I18n.locale = locale
  end

  #
  # runs a block in the changed locale
  def in(locale, &block)
    old = self.locale
    self.locale = locale if locale
    yield
  ensure
    self.locale = old
  end
end
