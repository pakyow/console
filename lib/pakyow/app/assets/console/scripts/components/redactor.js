pw.component.register('redactor', function (view, config, name, id) {
  this.setup = function () {
    $(view.node).redactor({changeCallback: function() {
      pw.node.trigger('change', view.node);
    }});
  };

  var parent = pw.node.component(view.node.parentNode);
  if (!parent || parent.getAttribute('data-ui') != 'content-editor') {
    // no need to wait on the editor to boot
    this.setup();
  } else if (parent.booted) {
    // cool, it's already booted
    this.setup();
  } else {
    // ugh, gotta wait until it boots
    this.listen('content-editor:booted', this.setup);
  }
});
