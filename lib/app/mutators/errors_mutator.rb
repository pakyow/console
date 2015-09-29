#TODO put this in a util
def pretty_errors(errors)
  Array(errors).map { |error|
    String.capitalize(error.gsub('_', ' '))
  }
end

Pakyow::App.mutators :errors do
  mutator :list do |view, errors|
    if errors.empty?
      view.remove
    else
      errors = pretty_errors(errors)

      view.prop(:message).repeat(errors) do |view, message|
        view.text = message
      end
    end

    #TODO remove, repeat, etc should just return the right thing
    view
  end
end
