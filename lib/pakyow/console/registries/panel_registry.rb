module Pakyow::Console::PanelRegistry
  def self.register(namespace, **kargs, &block)
    panels[namespace] = Pakyow::Console::Panel.new(namespace, **kargs, &block)
  end

  def self.all
    panels.values
  end

  def self.nav
    all.map { |panel|
      {
        namespace:  panel.namespace,
        nice_name:  panel.nice_name,
        icon_class: panel.icon_class
      }
    }
  end

  private

  def self.panels
    @panels ||= {}
  end
end
