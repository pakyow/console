pw.component.register('content-editor', function (view, config) {
  var $input = view.node.querySelector('input[type="hidden"]');
  var $constraints = view.node.querySelector('input[data-c="constraints"]');

  var self = this;

  var initial;
  if ($input.value && $input.value != '') {
    initial = JSON.parse(window.atob($input.value)).filter(function (datum) {
      // filters out bad data, which we've seen a few times if the editor breaks
      return datum.scope == 'content';
    });
  }

  var constraints = {};
  if ($constraints.value && $constraints.value != '') {
    constraints = JSON.parse(window.atob($constraints.value));
  }

  if (config.restricted) {
    pw.node.remove(view.node.querySelector('.console-content-add'));
  }

  this.inited = function (o) {
    if (initial) {
      if (typeof initial == 'string') {
        initial = JSON.parse(initial);
      }

      this.state.snapshots.push(initial);
      this.transform(initial);
      this.updateState();
    } else {
      self.addEditor();
    }

    self.trickle('content-editor:booted');
    view.node.booted = true;
  };

  view.node.addEventListener('trix-change', function () {
    self.updateState();
  });

  view.node.addEventListener('change', function () {
    self.updateState();
  });

  this.listen('content-editor:add', function (editor) {
    var index = self.indexForEditor(editor);

    self.updateState();
    self.addEditor(index + 1);
    self.focus(index + 1);
  });

  this.listen('content-editor:delete', function (editor) {
    var index = self.indexForEditor(editor);

    self.focus(index - 1);
    self.remove(editor);
    self.updateState();
  });

  this.listen('content-editor:split', function (options) {
    var editor = options.editor;
    var at = options.at;

    var index = self.indexForEditor(editor);

    self.updateState();
    self.addEditor(index + 1);

    self.state.current()[index + 1].content = self.state.current()[index].content.substring(at);
    self.state.current()[index].content = self.state.current()[index].content.substring(0, at);
    this.transform(this.state.current());

    self.focusAt(index + 1, 0);
  });

  // triggered when the delete key is pressed at the start of a non-empty field
  //
  this.listen('content-editor:concat', function (editor) {
    var index = self.indexForEditor(editor);

    if (index > 0) {
      if (self.state.current()[index - 1].type === "default") {
        var copy = self.state.copy();
        var start = copy[index - 1].content.length;
        copy[index - 1].content += copy[index].content;
        self.state.snapshots.push(copy);
        this.transform(this.state.current());
        self.focusAt(index - 1, start);

        self.remove(editor);
        self.updateState();
      } else {
        // nothing to do
      }
    }
  });

  this.listen('content-editor:changed', function () {
    self.updateState();
  });

  this.listen('content-editor:next', function (editor) {
    var fields = self.state.current().filter(function (field) {
      return field.type == "default";
    });

    var index = self.indexForEditorIn(editor, fields);

    if (index == fields.length - 1) {
      // this is the last text editor, so insert one at the end
      self.addEditor(self.state.current().length);
      self.focus(self.state.current().length - 1);
    } else if (index < self.state.current().length - 1) {
      // move to the next text editor
      self.focusAt(self.nextIndexForDefaultFrom(editor), 0);
    }
  });

  this.listen('content-editor:previous', function (editor) {
    var fields = self.state.current().filter(function (field) {
      return field.type == "default";
    });

    var index = self.indexForEditorIn(editor, fields);

    if (index > 0) { // we want to move only if we aren't the first default editor
      self.focus(self.previousIndexForDefaultFrom(editor));
    }
  });

  view.node.addEventListener("dragstart", function (evt) {
    var id = evt.target.getAttribute("data-id");
    evt.dataTransfer.setData("text/plain", id);
    self.dragTarget = evt.target;
  });

  view.node.addEventListener("dragover", function (evt) {
    evt.preventDefault();
    evt.dataTransfer.dropEffect = "move";

    var target = pw.node.scope(evt.target);

    if (target && target.getAttribute("data-scope") == "content") {
      self.removeDropArea();
      var area = document.createElement("DIV");
      // area.style.height = self.dragTarget.clientHeight + "px";
      area.className = "console-content-drop-area";
      area.id = "drop";

      self.dropTarget = self.state.current().find(function (editor) {
        return editor.id === target.getAttribute("data-id");
      });

      var positionRelativeToElement = evt.clientY - target.getBoundingClientRect().top;
      if (positionRelativeToElement > target.clientHeight / 2) {
        pw.node.after(target, area);
        self.dropPosition = "after";
      } else {
        pw.node.before(target, area);
        self.dropPosition = "before";
      }
    }
  });

  view.node.addEventListener("drop", function (evt) {
    evt.preventDefault();

    var draggedId = evt.dataTransfer.getData("text");
    var draggedDatum = self.state.current().find(function (editor) {
      return editor.id === draggedId;
    });

    var copy = self.state.copy();

    // remove the dragged datum
    copy.splice(self.indexForEditor(draggedDatum), 1);

    // determine where the element should be inserted
    var dropIndex;
    if (self.dropPosition === "after") {
      dropIndex = self.indexForEditor(self.dropTarget) + 1;
    } else {
      dropIndex = self.indexForEditor(self.dropTarget);
    }

    copy.splice(dropIndex, 0, draggedDatum);
    self.state.snapshots.push(copy);
    self.transform(self.state.current());
    self.removeDropArea();
    self.updateState();

    // hide stuck settings
    document.querySelectorAll('*[data-c="settings"]').forEach(function (settings) {
      settings.classList.add('hidden');
    });
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

  this.indexForEditor = function (editor) {
    return this.indexForEditorIn(editor, self.state.current());
  };

  this.indexForEditorIn = function (editor, fields) {
    for (var i = 0; i < fields.length; i++) {
      if (fields[i].id == editor.id) {
        return i;
      }
    }
  };

  // returns the index for the next default editor
  //
  this.nextIndexForDefaultFrom = function (editor) {
    for (var i = this.indexForEditor(editor) + 1; i < self.state.current().length; i++) {
      if (self.state.current()[i].type === "default") {
        return i;
      }
    }
  };

  // returns the index for the previous default editor
  //
  this.previousIndexForDefaultFrom = function (editor) {
    for (var i = this.indexForEditor(editor) - 1; i >= 0; i--) {
      if (self.state.current()[i].type === "default") {
        return i;
      }
    }
  };

  this.addEditor = function (index) {
    var editor = {
      type: 'default',
      align: 'default',
      scope: 'content',
      id: pw.util.guid()
    };

    var copy = self.state.copy();
    copy.splice(index, 0, editor);
    self.state.snapshots.push(copy);
    this.transform(this.state.current());
  };

  this.focus = function (index) {
    var fields = view.node.querySelectorAll(".console-content-editor-wrapper");
    var field = fields.item(index).querySelector("textarea");
    self.focusFieldAt(field, field.value.length);
  };

  this.focusAt = function (index, start) {
    var fields = view.node.querySelectorAll("textarea");
    var field = fields.item(index);
    self.focusFieldAt(field, start);
  };

  this.focusFieldAt = function (field, start) {
    field.selectionStart = field.selectionEnd = start;
  };

  this.removeDropArea = function () {
    var node = document.querySelector("#drop");

    if (node) {
      pw.node.remove(node);
    }
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

    console.log('state', state);
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

        if (config.restricted) {
          pw.node.toA($match.node.querySelectorAll('.console-content-alignment ul, .console-content-actions')).forEach(function (node) {
            pw.node.remove(node);
          });
        }

        var $current = view.node.querySelector('*[data-id="' + datum.id + '"]');

        if ($current) {
          if ($current.getAttribute('data-version') != datum.type) {
            pw.node.replace($current, $match.node);
            pw.component.findAndInit($match.node);

            $match.node.setAttribute('data-id', datum.id);
          }

          return;
        }

        $match.node.classList.remove("hidden");

        if (state.indexOf(datum) > 0) {
          var previous = view.node.querySelector("*[data-id='" + state[state.indexOf(datum) - 1].id + "']");

          if (previous) {
            pw.node.after(previous, $match.node);
          } else {
            pw.node.append(view.node, $match.node);
          }
        } else {
          pw.node.append(view.node, $match.node);
        }

        pw.component.findAndInit($match.node);
      });

      this.view.scope('content').order(state.map(function (datum) { return datum.id; }));
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
    self.bubble('content-editor:delete', self.parent());
  });
});

pw.component.register('content-add', function (view, config) {
  var self = this;

  view.node.addEventListener('click', function (evt) {
    evt.preventDefault();
    self.bubble('content-editor:add');
  });
});

pw.component.register('content-settings-toggle', function (view, config) {
  var self = this;

  view.node.addEventListener('click', function (evt) {
    evt.preventDefault();
    self.bubble('content-editor:settings:toggle', self.parent());
  });
});

pw.component.register('content-type-toggle', function (view, config) {
  var self = this;

  view.node.addEventListener('click', function (evt) {
    evt.preventDefault();
    self.bubble('content-editor:type:toggle', {
      type: config.type,
      editor: self.parent()
    });
  });
});

pw.component.register('content-align-toggle', function (view, config) {
  var self = this;

  view.node.addEventListener('click', function (evt) {
    evt.preventDefault();
    self.bubble('content-editor:align:toggle', {
      type: config.type,
      editor: self.parent()
    });
  });
});
