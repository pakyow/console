pw.component.register('content-editor-plaintext', function (view, config) {
  var self = this;

  var mock = document.createElement('DIV');
  mock.classList.add('console-content-plaintext-mock')
  mock.style.position = 'absolute';
  mock.style.top = '-100px';
  mock.style.opacity = '0';
  mock.style.width = view.node.clientWidth + 'px';

  pw.node.after(view.node, mock);

  view.node.addEventListener('keypress', function (evt) {
    var value = this.value + String.fromCharCode(evt.keyCode);

    if (evt.keyCode == 13) {
      value += '<br>';
    }

    self.update(value);
  });

  view.node.addEventListener('keyup', function (evt) {
    self.update(this.value);
  });

  view.node.addEventListener('blur', function () {
    pw.component.broadcast('content-editor:changed');
  });

  this.listen('content-editor:booted', function () {
    self.update(view.node.value);
  });

  this.update = function (value) {
    value = value.replace(/\n/g, '<br>');

    if (value.trim() == '') {
      value = '&nbsp;';
    }

    // add an extra line break to push the content down
    if (value.substring(value.length - 4, value.length) == '<br>') {
      value += '<br>';
    }

    mock.innerHTML = value;
    view.node.style.height = mock.offsetHeight + 'px';
  };
});
