part of hetimapatrinia;

html.Element buildDeltaTracker(ace.Editor editor) {
  var labels = [new html.SpanElement()..text = "last change:",
                new html.SpanElement()..text = "2nd last change:",
                new html.SpanElement()..text = "3rd last change:",];
  
  var deltaDisplays = new List.generate(3, (i) => new html.SpanElement());
  editor.onChange.listen((delta) {
    for (int i = 2; i > 0; --i) {
      deltaDisplays[i].text = deltaDisplays[i-1].text;  
    }
    deltaDisplays[0].text = delta.action;
  });
  
  var singleTrackers = new List.generate(3, (i) => new html.DivElement());
  for (int i = 0; i < 3; ++i) {
      singleTrackers[i]..classes.add('control')
      ..append(labels[i])
      ..append(deltaDisplays[i]);
  }
  
  return new html.DivElement()..children.addAll(singleTrackers);
}

html.Element buildTokenClickTracker(ace.Editor editor) {
  var tokenDisplay = new html.SpanElement();
  
  var tokenTracker = new html.DivElement()
    ..classes.add('control')
    ..append(new html.SpanElement()..text = "Token at cursor:")
    ..append(tokenDisplay);
  
  editor.selection.onChangeCursor.listen((_) {
    int r = editor.selection.cursor.row;
    int c = editor.selection.cursor.column;
    if (c + 1 == editor.session.getRowLength(r)) {
      tokenDisplay.text = "";
    } else {
      tokenDisplay.text = editor.session.getTokenAt(r, c).type.toString();
    }
  });
  
  return tokenTracker;
}
