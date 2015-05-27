part of hetimapatrinia;

html.Element buildKeyBindings(ace.Editor editor) {  
  final select = new html.SelectElement();
  for (String name in ace.KeyboardHandler.BINDINGS) {
    final value = (name == ace.KeyboardHandler.DEFAULT) ? 'ace' : name;
    final option = new html.OptionElement()
    ..text = value
    ..value = value;
    select.append(option);
  }
  select.onChange.listen((_) {
    final value = (select.value == 'ace') ? ace.KeyboardHandler.DEFAULT 
        : select.value;
    editor.keyboardHandler = new ace.KeyboardHandler.named(value);
  });
  final control = new html.DivElement()
  ..append(new html.SpanElement()..text = 'Key binding ')
  ..append(select)
  ..classes = ['control'];
  return control;
}
