pw.component.register('toggle', function (view, config) {
  var that = this;

  view.node.addEventListener('click', function (evt) {
    pw.component.broadcast('toggled:' + config.name);
  });
});

pw.component.register('toggleable', function (view, config) {
  var that = this;

  if (config.hidden) {
    view.node.classList.add('hidden');
  }

  this.listen('toggled:' + config.name, function () {
    view.node.classList.toggle('hidden');
  });
});
