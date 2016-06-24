pw.component.register('date', function (view, config) {
  var disabled = view.node.disabled;

  var months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  var v_m, v_d, v_y;
  var originalValue = view.node.value;
  if (originalValue && originalValue != '') {
    var dateParts = originalValue.split('-');
    v_m = dateParts[1];
    v_d = dateParts[2];
    v_y = dateParts[0];
  }

  // create the month input
  var $m = document.createElement('select');
  pw.node.append($m, document.createElement('option'));
  months.forEach(function (month, i) {
    var m = (i + 1).toString();
    if (m.length == 1) {
      m = '0' + m;
    }

    var $o = document.createElement('option');
    $o.value = m;
    $o.innerText = month;
    if ((i + 1) == v_m) {
      $o.selected = 'selected';
    }
    pw.node.append($m, $o);
  });

  // create the day input
  var $d = document.createElement('input');
  $d.placeholder = 'dd';
  $d.size = 2;
  $d.maxLength = 2;
  $d.className = 'ui-date-day';
  $d.type = 'text';
  if (v_d) {
    $d.value = v_d;
  }

  // create the year input
  var $y = document.createElement('input');
  $y.placeholder = 'yyyy';
  $y.size = 4;
  $y.maxLength = 4;
  $y.className = 'ui-date-year';
  $y.type = 'text';
  if (v_y) {
    $y.value = v_y;
  }

  pw.node.after(view.node, $m);
  pw.node.after(view.node, $d);
  pw.node.after(view.node, $y);

  // make the original input a hidden field
  view.node.type = 'hidden';

  // disable fields if original was disabled
  if (disabled) {
    $m.disabled = true;
    $d.disabled = true;
    $y.disabled = true;
  }

  this.saveValue = function () {
    var v_y = $y.value;
    var v_m = $m.value;
    var v_d = $d.value;

    if ((v_y && v_y != '') && (v_m && v_m != '') && (v_d && v_d != '')) {
      view.node.value = [$y.value, $m.value, $d.value].join('-');
    }
  };

  // listen for changes and set value of hidden field
  $m.addEventListener('change', this.saveValue);
  $d.addEventListener('keyup', this.saveValue);
  $y.addEventListener('keyup', this.saveValue);
});
