pw.component.register('content-editor-plaintext', function (view, config) {
  var self = this;

  var mock = document.createElement('DIV');
  mock.classList.add('console-content-plaintext-mock')
  mock.style.position = 'absolute';
  mock.style.right = '-100px';
  mock.style.opacity = '0';
  mock.style.width = view.node.clientWidth + 'px';

  pw.node.after(view.node, mock);

  view.node.addEventListener('keypress', function (evt) {
    var value = this.value + String.fromCharCode(evt.keyCode);

    if (evt.keyCode == 13) {
      if (evt.shiftKey) {
        value += '<br>';
      } else {
        var current = pw.state.init(pw.node.scope(view.node)).current()[0];
        evt.preventDefault();

        if (self.atEnd()) {
          self.bubble('content-editor:add', current);
        } else {
          self.bubble('content-editor:split', { editor: current, at: this.selectionStart });
        }
      }
    }

    self.update(value);
  });

  view.node.addEventListener('keyup', function (evt) {
    var current = pw.state.init(pw.node.scope(view.node)).current()[0];

    if (evt.keyCode == 8 && self.atStart()) {
      evt.preventDefault();

      if (this.value == "") {
        return self.bubble('content-editor:delete', current);
      } else {
        return self.bubble('content-editor:concat', current);
      }
    }

    if (evt.keyCode == 37 && self.atStart()) {
      return self.bubble('content-editor:previous', current);
    }
    if (evt.keyCode == 38 && self.atStart()) {
      return self.bubble('content-editor:previous', current);
    }
    if (evt.keyCode == 39 && self.atEnd()) {
      return self.bubble('content-editor:next', current);
    }
    if (evt.keyCode == 40 && self.atEnd()) {
      return self.bubble('content-editor:next', current);
    }

    self.update(this.value);
    self.bubble('content-editor:changed');
  });

  view.node.addEventListener('blur', function () {
    self.bubble('content-editor:changed');
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

  this.atStart = function () {
    return (view.node.selectionStart == 0);
  };

  this.atEnd = function () {
    return (view.node.selectionEnd == view.node.value.length);
  };
});
