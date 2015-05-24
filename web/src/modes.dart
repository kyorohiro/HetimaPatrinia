part of hetimapatrinia;

html.SelectElement modesSelect = new html.SelectElement();

html.Element buildModes(ace.Editor editor) {
  for (String name in ace.Mode.MODES) {
    final option = new html.OptionElement()
    ..text = name
    ..value = name;
    modesSelect.append(option);
  }
  modesSelect.value = ace.Mode.DART;
  modesSelect.onChange.listen((_) {
    editor.session.mode = new ace.Mode.named(modesSelect.value);
  });  
  final control = new html.DivElement()
  ..append(new html.SpanElement()..text = 'Mode ')
  ..append(modesSelect)
  ..classes = ['control'];
  return control;
}
