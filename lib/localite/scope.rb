module Localite::Scope
  #
  # scope allows to set a scope around a translation. A scoped translation
  # 
  #   Localite.scope("scope") do
  #     "msg".t
  #   end
  #
  # will look up "scope.msg" and "msg", in that order, and return the first
  # matching translation in the current locale. Scopes can be stacked; looking
  # up a scoped  translation
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
  def root_scope(*ss, &block)
    ss.compact!
    old = scopes
    self.scopes = Scopes.new
    ss.each do |s|
      self.scopes.push(s)
    end

    return yield
  ensure
    self.scopes = old
  end

  def scope(*ss, &block)
    if ss.empty? && !block_given?
      return scopes.map(&:to_s).join(".")
    end

    ss.compact!

    return yield if ss.empty?

    ss.each do |scope| scopes.push(scope) end

    yield
  ensure
    ss.each do |scope| scopes.pop end
  end

  private

  class Scopes < Array
    def push(s); @prepared = nil; super; end
    def pop; @prepared = nil; super; end

    def each(s, &block)
      @prepared ||= (0...length).map { |idx| self[idx..-1].join(".") } << nil

      s = s.to_s

      @prepared.each do |prepared|
        yield prepared ? "#{prepared}.#{s}" : s
      end
    end
  end

  def scopes
    Thread.current[:"localite:scopes"] ||= Scopes.new
  end

  def scopes=(s)
    Thread.current[:"localite:scopes"] = s
  end

  def translate_scoped(s)
    translated = nil
    scopes.each(s) do |scoped|
      begin
        translated = I18n.translate(scoped, :raise => true)
        break 
      rescue I18n::MissingTranslationData
        missing_translation scoped
      end
    end
    translated
  end
end
