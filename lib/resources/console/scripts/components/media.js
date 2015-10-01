pw.component.register('media-editor', function (view, config) {
});

pw.component.register('media-item', function (view, config) {
  view.node.addEventListener('click', function (evt) {
    evt.preventDefault();
    pw.component.broadcast('media-editor:chosen', config);
  });
});

pw.component.register('media-upload', function (view, config) {
  var self = this;

  var field = view.node.querySelector('input');

  view.node.addEventListener('click', function (evt) {
    if (evt.target.tagName != 'INPUT') {
      evt.preventDefault();
      field.click();
    }
  });

  field.addEventListener('change', function (evt) {
    var files = evt.target.files || evt.dataTransfer.files;

    for (var i = 0, f; f = files[i]; i++) {
      self.upload(f);
    }

    evt.target.value = '';
  });

  this.upload = function (file) {
    var xhr = new XMLHttpRequest();

    if(xhr.upload) {
      xhr.open("POST", '/console/files', true);
      xhr.setRequestHeader("X_FILENAME", file.name);

      // xhr.onreadystatechange = function() {
      //   pui.announce('media:uploaded');
      // };

      xhr.send(file);
    } else {
      console.log('err');
    }
  };
});
