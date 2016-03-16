module Pakyow::Helpers
  def console_handle(status)
    return if status == 200

    presenter.path = "console/errors/#{status}"
    res.body = [view.to_html]
    res.status = status
    halt
  end
end
