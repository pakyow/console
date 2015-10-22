Pakyow::Console.editor :boolean do |options|
  id = self.object_id.to_s
  Pakyow::Presenter::View.new('<input type="checkbox" value="1" data-scope="editor" id="' + id + '"> <label for="' + id + '" style="display:inline-block;font-weight:normal">[toggle]</label>')
end
