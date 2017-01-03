Pakyow::App.mutable :'pw-post' do
  query :published do
    Pakyow::Console::Models::Post.where(published: true).limit(15).all
  end
  
  query :unpublished do
    Pakyow::Console::Models::Post.where(published: false).limit(15).all
  end

  query :grouped do
    Pakyow::Console::Models::Post.where(published: true).all.group_by { |p|
      "#{p.published_at.year}-#{p.published_at.month.to_s.rjust(2, '0')}"
    }.to_a.sort{ |a, b| b[0] <=> a[0] }
  end
end
