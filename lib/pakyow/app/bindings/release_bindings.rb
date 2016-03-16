Pakyow::App.bindings :release do
  scope :release do
    binding :created_at do
      DateFormatter.in_words(bindable[:created_at]) + ' ago'
    end

    binding :version do
      "v#{bindable[:version]}"
    end
  end
end
