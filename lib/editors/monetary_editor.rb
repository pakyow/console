Pakyow::Console::EditorRegistry.register :monetary do |options|
  Pakyow::Presenter::View.new('<span>$</span> <input type="text" data-scope="editor">')
end
