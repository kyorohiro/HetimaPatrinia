part of hetimapatrinia;

html.Element buildThemes(ace.Editor editor) {  
  final select = new html.SelectElement();
  for (String name in ace.Theme.THEMES) {
    final option = new html.OptionElement()
    ..text = name
    ..value = name;
    select.append(option);
  }
  select.value = ace.Theme.CHROME;
  select.onChange.listen((_) {
    editor.theme = new ace.Theme.named(select.value);
  });
  final control = new html.DivElement()
  ..append(new html.SpanElement()..text = 'Theme ')
  ..append(select)
  ..classes = ['control'];
  return control;
}
