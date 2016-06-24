pw.component.register('delete', function (view, config) {
  var that = this;

  view.node.addEventListener('click', function(e) {
    e.preventDefault();

    if (confirm('Are you sure?')) {
      var form = document.createElement('form');
      form.action = this.href;
      form.method = 'post';

      var input = document.createElement('input');
      input.name = '_method';
      input.type = 'hidden';
      input.value = 'delete';

      form.appendChild(input);
      document.body.appendChild(form);
      form.submit();
    }
  });
});
