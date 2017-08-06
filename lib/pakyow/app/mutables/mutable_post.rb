Pakyow::App.mutable :'pw-post' do
  query :published do
    Pakyow::Console::Models::Post.published.limit(3).all
  end

  query :feed do
    Pakyow::Console::Models::Post.published.limit(15).all
  end

  query :unpublished do
    Pakyow::Console::Models::Post.unpublished.limit(15).all
  end

  query :grouped do
    Pakyow::Console::Models::Post.published.all.group_by { |p|
      "#{p.published_at.year}-#{p.published_at.month.to_s.rjust(2, '0')}"
    }.to_a.sort{ |a, b| b[0] <=> a[0] }
  end

  query :feed do
    posts = []
    posts.concat(Pakyow::Console::Models::Post.published.limit(15).all)
    posts.concat(Pakyow::Console::Models::SyndicatedPost.limit(15).all)
    posts.sort! { |p1, p2| p2.published_at <=> p1.published_at }
  end
end
