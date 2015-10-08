pw.component.register('content-editor-media', function (view, config, name, id) {
  var self = this;

  var uri = '/console/media';
  var channel = 'media:' + id;
  var blinder, media;

  var input = view.node.querySelector('input');
  var icon = view.node.querySelector('i').cloneNode(true);

  this.inited = function () {
    setTimeout(function () {
      if (input.value && input.value != '') {
        self.transform(JSON.parse(input.value));
      }
    });
  };

  this.listen(channel + ':navigator:enter', function (response) {
    if (!blinder) {
      blinder = document.createElement('DIV');
      blinder.classList.add('ui-media-blinder');

      media = document.createElement('DIV');
      media.classList.add('ui-media');

      blinder.appendChild(media);
      document.body.appendChild(blinder);

      blinder.addEventListener('click', function (evt) {
        if (evt.target === blinder) {
          evt.preventDefault();
          self.close();

          var uri = window.location.pathname;

          var opts = {
            uri: uri
          };

          window.history.pushState(opts, uri, uri);
        }
      });
    }

    media.innerHTML = response.body;
    pw.component.findAndInit(blinder);

    blinder.classList.add('ui-appear');
  });

  this.listen(channel + ':navigator:exit', function () {
    self.close();
  });

  this.listen(channel + ':navigator:boot', function () {
    // FIXME: this is never being triggered; related to load order of scripts; modal works?
    self.load();
  });

  view.node.addEventListener('click', function (evt) {
    evt.preventDefault();
    self.load();
  });

  this.load = function () {
    if (!window.socket) {
      // TODO: not sure what we can do here
      return;
    }

    var items;
    if (input.value && input.value != '') {
      items = JSON.parse(input.value);
    }

    var opts = {
      uri: uri,
      context: channel,
      container: 'default',
      items: items
    }

    window.history.pushState(opts, uri, uri);

    // listen for a choice to be made
    self.listen('media-editor:changed', function (items) {
      self.transform(items);
    });
  };

  this.close = function () {
    self.ignore('media-editor:changed');
    pw.node.remove(blinder);
    blinder = null;
    media = null;
  };

  this.transform = function (items) {
    var i = view.node.querySelector('i');

    if (items.length == 0) {
      if (!i) {
        pw.node.append(view.node, icon.cloneNode(true));
      }

      view.node.style.backgroundImage = null;
    } else if (items.length == 1) {
      if (i) {
        pw.node.remove(i);
      }

      view.node.style.backgroundImage = "url('" + items[0].thumb + "')";
    } else {
      //TODO decide how to display slideshows
    }

    view.node.querySelector('input').value = JSON.stringify(items);

    pw.component.broadcast('content-editor:changed');
  };
});
