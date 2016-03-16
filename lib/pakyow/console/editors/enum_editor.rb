Pakyow::Console.editor :enum do |attribute|
  view = Pakyow::Presenter::View.new('<select data-scope="editor"></select>')

  attribute[:extras][:values].each do |value|
    view.append(Pakyow::Presenter::View.new('<option value="' + value[0].to_s + '">' + value[1].to_s + '</option>'))
  end

  view
end
