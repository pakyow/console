Pakyow::App.mutators :'pw-post' do
  mutator :list do |view, posts|
    renderer = Pakyow.app.presenter.store(:console).view('/console/pages/template')

    view.apply(posts) do |view, post|
      view.prop(:body)[0].replace(post.html)
    end
  end

  mutator :show do |view, post|
    view.bind(post)
    view.prop(:body)[0].replace(post.html)
  end
end

Pakyow::App.mutators :'pw-post-group' do
  mutator :archive do |view, groups|
    view.repeat(groups) do |group|
      y, m = group[0].split('-')
      bind({ name: "#{Pakyow::Console::Models::Post::MONTHS[m]} #{y}" })
      scope(:'pw-post').apply(group[1])
    end
  end
end
