part of hetimapatrinia;

html.Element buildShowInvisibles(ace.Editor editor) => _buildOption('Show Invisibles ', false,
    (bool value) => editor.setOption('showInvisibles', value));

html.Element buildShowGutter(ace.Editor editor) => _buildOption('Show Gutter ', true,
    (bool value) => editor.setOption('showGutter', value));

html.Element buildShowPrintMargin(ace.Editor editor) => _buildOption('Show Print Margin ', true, 
    (bool value) => editor.setOption('showPrintMargin', value));

html.Element buildUseSoftTabs(ace.Editor editor) => _buildOption('Use Soft Tabs ', true, 
    (bool value) => editor.session.setOption('useSoftTabs', value));

html.Element _buildOption(String desc, bool defaultValue, onChange(bool value)) {
  final input = new html.InputElement();
  input
  ..type = 'checkbox'
  ..checked = defaultValue
  ..onChange.listen((_) => onChange(input.checked));  
  final control = new html.DivElement()
  ..append(new html.SpanElement()..text = desc)
  ..append(input)
  ..classes = ['control'];
  return control;
}
