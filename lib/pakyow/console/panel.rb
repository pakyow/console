class Pakyow::Console::Panel
  attr_reader :namespace, :mode, :nice_name, :icon_class

  def initialize(namespace, mode: nil, nice_name: nil, icon_class: nil, &block)
    @namespace = namespace
    @mode = mode

    @nice_name  = nice_name
    @icon_class = icon_class

    # instance_exec(self, &block)
  end
end
