pw.component.register('content-editor-media', function (view, config, name, id) {
  var self = this;

  var uri = '/console/media';
  var channel = 'media:' + id;
  var blinder, media;

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

    var opts = {
      uri: uri,
      context: channel,
      container: 'default'
    }

    window.history.pushState(opts, uri, uri);

    // listen for a choice to be made
    self.listen('media-editor:chosen', function (item) {
      // TODO: stop listening

      pw.node.remove(view.node.querySelector('i'));
      view.node.style.backgroundImage = "url('" + item.thumb + "')";
      self.close();

      view.node.querySelector('input').value = item.id;
      pw.component.broadcast('content-editor:changed');
    });

    // also listen for it to be dismissed
    self.listen('media-editor:dismissed', function () {
      // TODO: stop listening
    });
  };

  this.close = function () {
    pw.node.remove(blinder);
    blinder = null;
    media = null;
  };
});
