Pakyow::Console.editor :file do |options, value|
  if file = Pakyow::Console::FileStore.instance.find(value)
    path = Pakyow::Router.instance.group(:file).path(:show, file_id: value)
    name = file[:filename]
  else
    path = ''
    name = ''
    value = ''
  end

  Pakyow::Presenter::View.new('<input type="file" data-scope="editor"> <a href="' + path + '" target="_blank">' + name + '</a><br><input type="checkbox" id="' + value + '" data-scope="editor" value="delete"> <label for="' + value + '" style="font-weight: normal; display: inline-block">[delete]</label>')
end
