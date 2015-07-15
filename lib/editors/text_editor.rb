Pakyow::Console::EditorRegistry.register :text do
  Pakyow::Presenter::View.new('<textarea data-scope="editor" style="resize:none" cols="80" rows="8" data-ui="redactor"></textarea>')
end
