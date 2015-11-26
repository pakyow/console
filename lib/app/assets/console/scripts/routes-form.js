$('.function-list').on('click', 'li a.edit-function', function (evt) {
  evt.preventDefault();

  var li = $(this).closest('li');
  $.get(this.href, function (res) {
    $(li).addClass('active').siblings().removeClass('active');
    $('.function-detail').html(res);

    $('.function-detail form').on('submit', function (evt) {
      evt.preventDefault();
      $.post(this.action, $(this).serialize(), function (res) {
        console.log('done');
      });
    });
  });
});

$('.function-list').on('click', 'a#add-function', function (evt) {
  evt.preventDefault();

  var button = this;
  $.get(this.href, function (res) {
    $(button).replaceWith(res);

    $('.function-list form').on('submit', function (evt) {
      evt.preventDefault();
      $.post(this.action, $(this).serialize(), function (res) {
        $('.function-list').html($(res).find('.function-list').html());
      });
    });
  });
});

$('.function-list').on('click', 'li a.delete-function', function (evt) {
  evt.preventDefault();

  $.post(this.href, { _method: 'DELETE' }, function (res) {
    $('.function-list').html($(res).find('.function-list').html());
  });
});
