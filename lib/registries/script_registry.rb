module Pakyow::Console::ScriptRegistry
  def self.register(path)
    scripts << path
  end

  def self.scripts
    @scripts ||= []
  end
end
