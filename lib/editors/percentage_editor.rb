Pakyow::Console::EditorRegistry.register :percentage do |options|
  Pakyow::Presenter::View.new('<input type="text" data-scope="editor"> <span>%</span>')
end
