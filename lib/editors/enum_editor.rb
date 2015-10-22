Pakyow::Console.editor :enum do |options|
  view = Pakyow::Presenter::View.new('<select data-scope="editor"></select>')

  options[:values].each do |value|
    view.append(Pakyow::Presenter::View.new('<option value="' + value[0].to_s + '">' + value[1].to_s + '</option>'))
  end

  view
end
