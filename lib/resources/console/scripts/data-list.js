$('tr[data-id]').on('click', function (evt) {
  evt.preventDefault();
  var path = window.location.pathname + '/' + $(this).attr('data-id');
  document.location = path;
});
