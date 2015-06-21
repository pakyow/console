Pakyow::App.bindings :app_event do
  scope :app_event do
    binding :created_at do
      DateFormatter.in_words(bindable[:created_at]) + ' ago'
    end
  end
end
