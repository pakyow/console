class Pakyow::Console::ServiceHookRegistry
  def self.register(type, action, subject, &block)
    for_type = hooks.fetch(type.to_sym)
    for_action = for_type[action.to_sym] ||= {}
    (for_action[subject.to_sym] ||= []) << block
  end

  def self.call(type, action, subject, data)
    hooks
      .fetch(type.to_sym, {})
      .fetch(action.to_sym, {})
      .fetch(subject.to_sym, [])
      .each { |fn| fn.call(data) }
  end

  private

  def self.hooks
    @hooks ||= {
      before: {},
      after:  {},
    }
  end
end
