pw.component.register('toggle', function (view, config) {
  var that = this;

  view.node.addEventListener('click', function (evt) {
    pw.component.push({
      channel: 'toggled:' + config.name,
      payload: {}
    });
  });
});

pw.component.register('toggleable', function (view, config) {
  var that = this;

  view.node.classList.add('hidden');

  //TODO update once listen has specific functions
  this.listen('toggled:' + config.name);

  this.message = function (channel, payload) {
    view.node.classList.toggle('hidden');
  };
});
