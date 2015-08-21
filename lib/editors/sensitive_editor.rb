Pakyow::Console::EditorRegistry.register :sensitive do
  Pakyow::Presenter::View.new('<input type="password" data-scope="editor" style="width: 400px">')
end
