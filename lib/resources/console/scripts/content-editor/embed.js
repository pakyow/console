pw.component.register('content-editor-embed', function (view, config) {
  var self = this;

  view.node.addEventListener('keypress', function (evt) {
    var value = this.value + String.fromCharCode(evt.keyCode);

    if (evt.keyCode == 13) {
      evt.preventDefault();

      if (view.node.value.search('vimeo.com') != -1) {
        var id = view.node.value.split('vimeo.com/')[1];
        var source = '<iframe src="//player.vimeo.com/video/' + id + '" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>';
        var div = document.createElement('div');
        div.classList.add('console-content-vimeo-wrapper');
        div.innerHTML = source;
        pw.node.after(view.node, div);
        view.node.classList.add('hidden');
      }
    }
  });
});
