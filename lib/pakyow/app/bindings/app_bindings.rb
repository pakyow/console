Pakyow::App.bindings :app do
  scope :app do
    binding :select_href do
      {
        href: "/console/setup/app/#{bindable[:id]}"
      }
    end
  end
end
