pw.component.register('content-editor', function (view, config) {
  var $input = view.node.querySelector('input[name="console-datum[content]"]');
  var $constraints = view.node.querySelector('input[data-c="constraints"]');

  var self = this;

  var initial;
  if ($input.value && $input.value != '') {
    initial = JSON.parse(decodeURIComponent($input.value)).filter(function (datum) {
      // filters out bad data, which we've seen a few times if the editor breaks
      return datum.scope == 'content';
    });
  }

  var constraints = {};
  if ($constraints.value && $constraints.value != '') {
    constraints = JSON.parse(decodeURIComponent($constraints.value));
  }

  this.inited = function (o) {
    if (initial) {
      if (typeof initial == 'string') {
        initial = JSON.parse(initial);
      }

      this.state.snapshots.push(initial);
      this.transform(initial);
      this.updateState();

      pw.component.broadcast('content-editor:booted');
      window.editorBooted = true;
    } else {
      self.addEditor();
    }
  };

  view.node.addEventListener('trix-change', function () {
    self.updateState();
  });

  this.listen('content-editor:add', function () {
    self.addEditor();
    self.updateState();
  });

  this.listen('content-editor:delete', function (editor) {
    self.remove(editor);
    self.updateState();
  });

  this.listen('content-editor:changed', function () {
    self.updateState();
  });

  this.listen('content-editor:settings:toggle', function (editor) {
    var $editorView = view.node.querySelector('*[data-id="' + editor.id + '"]');
    $editorView.querySelector('*[data-c="editor"]').classList.toggle('hidden');
    $editorView.querySelector('*[data-c="settings"]').classList.toggle('hidden');
  });

  this.listen('content-editor:type:toggle', function (options) {
    var state = self.state.current();

    var currentEditorState = state.find(function (datum) {
      return datum.id == options.editor.id;
    });

    if (currentEditorState.type == options.type) {
      newType = 'default';
    } else {
      newType = options.type;
    }

    var $editorView = view.node.querySelector('*[data-id="' + options.editor.id + '"]');

    currentEditorState.type = newType;
    currentEditorState.scope = 'content-' + newType;

    self.transform(state);

    self.mutated($editorView);
    self.updateState();
  });

  this.listen('content-editor:align:toggle', function (options) {
    var state = self.state.current();

    var currentEditorState = state.find(function (datum) {
      return datum.id == options.editor.id;
    });

    var newType = options.type;

    var $editorView = view.node.querySelector('*[data-id="' + options.editor.id + '"]');

    currentEditorState.align = newType;

    self.transform(state);
    self.mutated($editorView);
    self.updateState();
  });

  this.addEditor = function () {
    self.append({
      type: 'default',
      align: 'default',
      scope: 'content',
      id: pw.util.guid()
    });
  };

  this.updateState = function () {
    this.state.update();

    var state = this.state.diffNode(view.node)['__nested'].filter(function (datum) {
      // filters out bad data before saving
      return datum.scope == 'content';
    });

    // do some cleanup
    state.forEach(function (datum) {
      delete datum['__nested'];
    });

    console.log('new state');
    console.log(state);

    $input.value = JSON.stringify(state);
  };

  this.transform = function (state) {
    if (!state) {
      return;
    }

    if (state.length > 0) {
      var $template = this.templates['content'];
      var $working;

      if (view.scope('content').length() > state.length) {
        view.scope('content').views.forEach(function (view) {
          var id = view.node.getAttribute('data-id');
          if (!state.find(function (datum) {
            return id == datum.id;
          })) {
            view.remove();
          }
        });
        return;
      }

      state.forEach(function (datum) {
        $working = $template.clone();

        var $match = $working.views.find(function (view) {
          return view.node.getAttribute('data-version') == datum.type;
        });

        var $current = view.node.querySelector('*[data-id="' + datum.id + '"]');

        if ($current) {
          if ($current.getAttribute('data-version') != datum.type) {
            pw.node.replace($current, $match.node);
            pw.component.findAndInit($match.node);

            $match.node.setAttribute('data-id', datum.id);
          }

          return;
        }

        pw.node.append(view.node, $match.node);
        pw.component.findAndInit($match.node);
      });

      this.view.scope('content').bind(state);
    } else {
      pw.node.breadthFirst(this.view.node, function () {
        if (this.hasAttribute('data-scope')) {
          pw.node.remove(this);
        }
      });
    }

    state.forEach(function (datum) {
      var $editorView = view.node.querySelector('*[data-id="' + datum.id + '"]');
      var $toggle = $editorView.querySelector('*[data-config="type: ' + datum.type + '"]');
      var $align = $editorView.querySelector('*[data-config="type: ' + datum.align + '"]');

      // deselect all toggles
      $editorView.querySelectorAll('*[data-ui="content-type-toggle"]').forEach(function ($toggle) {
        $toggle.classList.remove('active');
      });

      // select the specific toggle
      if ($toggle) {
        $toggle.classList.add('active');
      }

      // deselect all alignment
      $editorView.querySelectorAll('*[data-ui="content-align-toggle"]').forEach(function ($align) {
        $align.classList.remove('active');
      });

      // select the specific alignment
      if ($align) {
        $align.classList.add('active');
      }

      // set the editor alignment
      $editorView.classList.remove('console-content-align-right');
      $editorView.classList.remove('console-content-align-left');
      $editorView.classList.remove('console-content-align-justify');
      $editorView.classList.add('console-content-align-' + datum.align);

      var align = datum.align;
      if (!align || align == '') {
        align = 'default';
      }

      if (constraints && constraints[datum.type] && constraints[datum.type][align]) {
        $editorView.constraints = constraints[datum.type][align];
      }
    });
  };
});

pw.component.register('content-delete', function (view, config) {
  var self = this;

  view.node.addEventListener('click', function (evt) {
    evt.preventDefault();
    pw.component.broadcast('content-editor:delete', self.parent());
  });
});

pw.component.register('content-add', function (view, config) {
  view.node.addEventListener('click', function (evt) {
    evt.preventDefault();
    pw.component.broadcast('content-editor:add');
  });
});

pw.component.register('content-settings-toggle', function (view, config) {
  var self = this;

  view.node.addEventListener('click', function (evt) {
    evt.preventDefault();
    pw.component.broadcast('content-editor:settings:toggle', self.parent());
  });
});

pw.component.register('content-type-toggle', function (view, config) {
  var self = this;

  view.node.addEventListener('click', function (evt) {
    evt.preventDefault();
    pw.component.broadcast('content-editor:type:toggle', {
      type: config.type,
      editor: self.parent()
    });
  });
});

pw.component.register('content-align-toggle', function (view, config) {
  var self = this;

  view.node.addEventListener('click', function (evt) {
    evt.preventDefault();
    pw.component.broadcast('content-editor:align:toggle', {
      type: config.type,
      editor: self.parent()
    });
  });
});
