Pakyow::Console.editor :datetime do
  Pakyow::Presenter::View.new(
    '<link href="/console/flatpickr/flatpickr.css" rel="stylesheet" type="text/css">' \
    '<script src="/console/flatpickr/flatpickr.js"></script>' \
    '<script src="/console/scripts/components/flatpickr.js"></script>' \
    '<input type="text" data-scope="editor" class="field-datetime" data-ui="flatpickr">'
  )
end
