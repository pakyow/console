#TODO put this in a util
def pretty_errors(errors)
  Array(errors).map { |error|
    String.capitalize(error.gsub('_', ' '))
  }
end

Pakyow::App.mutators :errors do
  mutator :list do |view, errors|
    errors = pretty_errors(errors)

    if errors.empty?
      view.attrs.send('data-version=', 'empty')
    end

    view.prop(:message).repeat(errors) do |view, message|
      view.text = message
    end

    view
  end
end
