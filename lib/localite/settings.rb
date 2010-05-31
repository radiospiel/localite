#
# Localite provides three dimensions for translation keys. A call like 
# that:
#
# Localite.locale(:de) do
#   Localite.format(:fbml) do
#     Localite.scope("outer") do
#       Localite.scope("scope") do
#         "msg".t
#       end
#     end
#   end
# end
#
# looks up the following entries in these formats and languages, in
# that order:
#
# - "fbml.de.outer.scope.msg"
# - "fbml.en.outer.scope.msg"
# - "html.de.outer.scope.msg"
# - "html.en.outer.scope.msg"
# - "text.de.outer.scope.msg"
# - "text.en.outer.scope.msg"
# - "fbml.de.scope.msg"
# - "fbml.en.scope.msg"
# - "html.de.scope.msg"
# - "html.en.scope.msg"
# - "text.de.scope.msg"
# - "text.en.scope.msg"
# - "fbml.de.msg"
# - "fbml.en.msg"
# - "html.de.msg"
# - "html.en.msg"
# - "text.de.msg"
# - "text.en.msg"
#
module Localite::Settings
  #
  # == set/return the locale ==========================================

  #  
  # Returns the base locale; e.g. :en
  def base
    :en
  end

  #
  # returns the current locale; defaults to the base locale
  def current_locale
    Thread.current[:"localite:locale"] || base
  end

  def current_locale=(locale)
    I18n.locale = Thread.current[:"localite:locale"] = locale
  end

  #
  # runs a block in the changed locale
  def locale(locale, &block)
    scope :locale => locale, &block
  end

  #
  # scope allows to set a scope around a translation. A scoped 
  # translation
  # 
  #   Localite.scope("scope") do
  #     "msg".t
  #   end
  #
  # will look up "scope.msg" and "msg", in that order, and return the
  # first matching translation in the current locale. Scopes can be 
  # stacked; looking up a scoped translation
  #
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
    options = if args.last.is_a?(Hash)
      args.pop
    else
      {}
    end
    
    #
    # set locale
    if locale = options[:locale]
      old_locale = self.current_locale
      self.current_locale = if I18n.backend.available_locales.include?(locale = locale.to_sym)
        locale
      else
        base
      end
    end

    #
    # set format
    if format = options[:format]
      old_format = self.current_format
      self.current_format = format
    end

    #
    # adjust scope (from the remaining arguments)
    scopes.push(*args)

    yield
  ensure
    scopes.pop(*args)
    self.current_format = old_format if old_format
    self.current_locale = old_locale if old_locale
  end
  
  def scopes
    Thread.current[:"localite:scopes"] ||= Localite::Scopes.new
  end

  #
  # == format setting =================================================

  #
  # The format setting defines how the template engine deals with its
  # parameters. In :html mode all parameters will be subject to HTML
  # escaping, while in :text mode the parameters remain unchanged.
  #
  def format(format, &block)
    scope :format => format, &block
  end

  def current_format
    Thread.current[:"localite:format"] || :text
  end

  def current_format=(fmt)
    Thread.current[:"localite:format"] = fmt
  end
end
