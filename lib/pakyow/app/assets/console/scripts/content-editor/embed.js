pw.component.register('content-editor-embed', function (view, config) {
  var self = this;

  var $input = view.node;

  this.inited = function () {
    setTimeout(function () {
      if ($input.value && $input.value != '') {
        self.transform($input.value);
      }
    });
  };

  view.node.addEventListener('keypress', function (evt) {
    var value = this.value + String.fromCharCode(evt.keyCode);

    if (evt.keyCode == 13) {
      evt.preventDefault();
      self.transform(view.node.value);
      self.bubble('content-editor:changed');
    }
  });

  this.transform = function (value) {
    if (value.search('vimeo.com') != -1) {
      var id = value.split('vimeo.com/')[1];
      var source = '<iframe src="//player.vimeo.com/video/' + id + '" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>';
      var div = document.createElement('div');
      div.classList.add('console-content-vimeo-wrapper');
      div.innerHTML = source;
      pw.node.after(view.node, div);
      view.node.classList.add('hidden');
    }
  };
});
