library hetimapatrinia;

import 'dart:async';
import 'dart:html' as html;
import 'package:ace/ace.dart' as ace;
import 'package:ace/proxy.dart';
import 'dart:convert' as conv;
import 'package:hetimagit/src/git/commands/clone.dart' as git;
import 'package:hetimagit/src/git/objectstore.dart' as git;
import 'package:hetimacore/hetimacore.dart' as hetima;
import 'package:hetimacore/hetimacore_cl.dart' as hetima;
import 'package:hetimafile/hetimafile.dart' as hetifile;
import 'package:hetimafile/hetimafile_cl.dart' as hetifilecl;
import 'utils.dart' as git;
import 'dart:js' as js;
import 'hetitextencoding.dart' as te;
part 'src/autocomplete.dart';
part 'src/documents.dart';
part 'src/key_bindings.dart';
part 'src/modes.dart';
part 'src/options.dart';
part 'src/themes.dart';
part 'src/editor_info.dart';

ace.Editor editorFile = ace.edit(html.querySelector('#editor-file'));
ace.Editor editorNow = ace.edit(html.querySelector('#editor-now'));
Tab tab = new Tab();
Dialog dialog = new Dialog();
RemoveDialog rmdialog = new RemoveDialog();
SaveDialog savedialog = new SaveDialog();
hetifile.HetiDirectory currentDir = null;
String coding = "UTF-8";

Map<String, Buffer> bufferDic = {};
class Buffer {
  hetifile.HetiFile file;
  String value = "";
  bool isChange = false;
}
Buffer currentBuffer = null;
void bufferSave(String key, Buffer value) {
  bufferDic[key] = value;
}

void bufferClear() {
  if (currentBuffer != null) {
    bufferDic.remove(currentBuffer.file.fullPath);
    currentBuffer.isChange = false;
    bufferSetValueFromEntry(currentBuffer.file);
  }
}

bufferSetValueFromString(hetifile.HetiFile entry, String value, [isChange = false]) {
  if (currentBuffer != null && currentBuffer.isChange == true) {
    print("####==> AAA 02");
    bufferDic[currentBuffer.file.fullPath] = currentBuffer;
    currentBuffer.value = editorNow.value;
  }
  print("####==> AAA 03");
  currentBuffer = new Buffer()
    ..file = entry
    ..value = value
    ..isChange = isChange;
  editorNow.session.mode = new ace.Mode.forFile(entry.name);
  editorNow.setValue(value);
  editorNow.focus();
  editorNow.clearSelection();
}

bufferSetValueFromEntry(hetifile.HetiFile entry) {
  if (bufferDic.containsKey(entry.fullPath)) {
    print("####==> AAA 01");
    tab.selectTab("#m01_now");
    bufferSetValueFromString(entry, bufferDic[entry.fullPath].value, true);
    return;
  }
  entry.getHetimaFile().then((hetima.HetimaFile ff) {
    hetima.HetimaBuilder b = new hetima.HetimaFileToBuilder(ff);
    return b.getLength().then((int length) {
      return b.getByteFuture(0, length);
    }).then((List<int> l) {
      tab.selectTab("#m01_now");
      try {
        print("### ${entry.name}");
        te.HetiTextDecoder enc = new te.HetiTextDecoder(coding);
        if (coding == "UTF-8") {
          bufferSetValueFromString(entry, conv.UTF8.decode(l, allowMalformed: true));
        } else {
          bufferSetValueFromString(entry, enc.decode(l));
        }
      } catch (e) {
        print("### ERROR 001 ${e}");
      }
    }).catchError((e) {});
  });
}

void main() {
//  new Future.delayed(new Duration(seconds:5),(){
//  te.HetiTextDecoder sjisEnc = new te.HetiTextDecoder("shift_jis");
//  print("### => ${sjisEnc.decode([65, 66, 67, 68])} ${sjisEnc.decode([0x41, 0x42, 0x43, 0x84, 0x44]).length}");
//  });
  ace.implementation = ACE_PROXY_IMPLEMENTATION;
  editorFile
    ..theme = new ace.Theme.named(ace.Theme.CHROME)
    ..session.mode = new ace.Mode.named(ace.Mode.DART)
    ..readOnly = true
    ..keyboardHandler = new ace.KeyboardHandler.named(ace.KeyboardHandler.EMACS);
  editorNow
    ..theme = new ace.Theme.named(ace.Theme.CHROME)
    ..session.mode = new ace.Mode.named(ace.Mode.DART)
    //..readOnly = true
    ..keyboardHandler = new ace.KeyboardHandler.named(ace.KeyboardHandler.EMACS);

  editorNow.session.onChange.listen((ace.Delta d) {
    print("onchange ${d.action} ${d.text} ${d.range.start}");
    currentBuffer.isChange = true;
  });
  enableAutocomplete(editorNow);

  tab.init();
  dialog.init();
  rmdialog.init();
  savedialog.init();
  //
  // clone
  html.querySelector('#com-clone-btn').onClick.listen((html.MouseEvent e) {
    print("#click clone button");
    onClickClone();
  });

  //
  // support click and ender key
  html.querySelector('#editor-file').onClick.listen((html.MouseEvent e) {
    print("#click file ${editorFile.cursorPosition.row} ${editorFile.cursorPosition.column}");
    if (editorFile.cursorPosition.column == 0) {
      bool include = false;
      List<ace.Annotation> l = [];
      for (ace.Annotation a in editorFile.session.getAnnotations()) {
        if (a.row == editorFile.cursorPosition.row) {
          include = true;
        } else {
          l.add(a);
        }
      }
      if (include == false) {
        l.add(new ace.Annotation(row: editorFile.cursorPosition.row));
      }
      editorFile.session.setAnnotations(l);
    } else {
      select(editorFile.cursorPosition.row, editorFile.cursorPosition.column);
    }
  });

  html.querySelector('#editor-file').onKeyDown.listen((html.KeyboardEvent e) {
    print("#psuh key ${e.keyCode} ${editorFile.cursorPosition.row} ${editorFile.cursorPosition.column}");
    select(editorFile.cursorPosition.row, editorFile.cursorPosition.column);
  });

  //
  // update file list
  tab.onShow.listen((String s) {
    if (s == "#con-file") {
      //"#editor-file") {
      if (currentDir == null) {
        getRoot().then((_) {
          updateList();
        });
      } else {
        updateList();
      }
    }
  });

  html.querySelectorAll('[name="coding"]').forEach((html.InputElement radioButton) {
    radioButton.onClick.listen((html.MouseEvent e) {
      html.InputElement clicked = e.target;
      print("The user is ${clicked.value} ${clicked.checked}");
      coding = clicked.value;
    });
  });

  html.querySelectorAll('[name="mode"]').forEach((html.InputElement radioButton) {
    radioButton.onClick.listen((html.MouseEvent e) {
      print("select mode ${radioButton.value}");
      if (radioButton.value == "emacs") {
        editorFile.keyboardHandler = new ace.KeyboardHandler.named(ace.KeyboardHandler.EMACS);
        editorNow.keyboardHandler = new ace.KeyboardHandler.named(ace.KeyboardHandler.EMACS);
      } else if (radioButton.value == "vi") {
        editorFile.keyboardHandler = new ace.KeyboardHandler.named(ace.KeyboardHandler.VIM);
        editorNow.keyboardHandler = new ace.KeyboardHandler.named(ace.KeyboardHandler.VIM);
      }
    });
  });

  html.querySelector("#con-file-remove-button").onClick.listen((html.MouseEvent e) {
    print("#click remove");
    rmdialog.show();
  });

  html.querySelector("#con-now-save-button").onClick.listen((html.MouseEvent e) {
    print("#click save");
    savedialog.show();
  });
  html.querySelector("#con-now-reset-button").onClick.listen((html.MouseEvent e) {
    print("#click reset");
    bufferClear();
  });

  //
  //
  getRoot();
}

void onClickClone() {
  print("click clone button");
  html.TextAreaElement address = html.querySelector('#com-clone-address');
  html.TextAreaElement outputdir = html.querySelector('#com-clone-outputdir');

  print("click clone button ${address.value}");
  git.GitLocation location = new git.GitLocation(outputdir.value);
  location.init().then((_) {
    print("### ${location.entry}");
    git.ObjectStore store = new git.ObjectStore(location.entry);
    git.Clone clone = new git.Clone(new git.GitOptions(repoUrl: address.value, root: location.entry, depth: 1, store: store));
    clone.clone().then((_) {
      print("end clone");
      dialog.show("clone end");
    }).catchError((e) {
      print("end clone error : ${e} ${e.toString()}");
      dialog.show("end clone error : ${e} ${e.toString()}");
    });
  });
}

Future getRoot() {
  return hetifilecl.DomJSHetiFileSystem.getFileSystem().then((hetifile.HetiFileSystem fs) {
    currentDir = fs.root;
  });
}

updateList() {
  editorFile.session.setAnnotations([]);
  return currentDir.getList().then((List<hetifile.HetiEntry> l) {
    StringBuffer b = new StringBuffer();
    b.write(">>${currentDir.fullPath}\n");
    b.write("..");
    b.write("\n--");
    for (hetifile.HetiEntry e in l) {
      b.write("\n---\n");
      b.write(e.name);
      b.write("\n--");
    }
    b.write("---\n");
    b.write("..");
    b.write("\n--\n");
    editorFile.setValue(b.toString());
    editorFile.clearSelection();
  });
}

List<hetifile.HetiEntry> selectFile(List<int> rowList) {
  List<hetifile.HetiEntry> ret = [];

  for (int row in rowList) {
    int index = (row ~/ 3) - 1;
    if (index <= -1 || index >= (currentDir.lastGetList.length)) {} else if (index < currentDir.lastGetList.length) {
      hetifile.HetiEntry entry = currentDir.lastGetList[index];
      ret.add(entry);
    }
  }
  return ret;
}

select(int row, int col) {
  List<hetifile.HetiEntry> entryList = selectFile([row]);
  if (entryList.length == 0) {
    currentDir.getParent().then((hetifile.HetiDirectory d) {
      if (d != null) {
        currentDir = d;
        updateList();
      }
    });
    return;
  } else {
    hetifile.HetiEntry entry = entryList[0];
    if (entry is hetifile.HetiDirectory) {
      currentDir = entry;
      updateList();
    } else if (entry is hetifile.HetiFile) {
      bufferSetValueFromEntry(entry);
    }
  }
}

class Dialog {
  html.Element dialog = html.querySelector('#dialog');
  html.ButtonElement dialogBtn = html.querySelector('#dialog-btn');
  html.ButtonElement dialogMessage = html.querySelector('#dialog-message');

  Dialog() {
    init();
  }

  void init() {
    dialogBtn.onClick.listen((html.MouseEvent e) {
      dialog.style.display = "none";
    });
  }

  void show(String message) {
    dialog.style.left = "${html.window.innerWidth/2-100}px";
    dialog.style.top = "${html.window.innerHeight/2-100}px";
    dialog.style.position = "absolute";
    dialog.style.display = "block";
    dialog.style.width = "200px";
    dialog.style.zIndex = "50";
    dialogMessage.value = message;
  }
}

class RemoveDialog {
  html.Element dialog = html.querySelector('#dialog-remove-file');
  html.ButtonElement dialogOk = html.querySelector('#dialog-remove-file-ok');
  html.ButtonElement dialogBack = html.querySelector('#dialog-remove-file-back');
  html.TextAreaElement dialogMessage = html.querySelector('#dialog-remove-file-message');

  RemoveDialog() {
    init();
  }

  void init() {
    dialogOk.onClick.listen((html.MouseEvent e) {
      dialog.style.display = "none";
    });
    dialogBack.onClick.listen((html.MouseEvent e) {
      dialog.style.display = "none";
    });
  }

  void show() {
    List<int> rowList = [];
    List<ace.Annotation> a = editorFile.session.getAnnotations();
    for (ace.Annotation b in a) {
      rowList.add(b.row);
    }
    dialogOk.onClick.listen((html.MouseEvent e) {
      dialog.style.display = "none";
    });
    List<hetifile.HetiEntry> fList = selectFile(rowList);
    StringBuffer buffer = new StringBuffer();
    for (hetifile.HetiEntry f in fList) {
      buffer.write(f.name);
      buffer.write("\n");
    }
    dialog.style.left = "${html.window.innerWidth/2-100}px";
    dialog.style.top = "${html.window.innerHeight/2-100}px";
    dialog.style.position = "absolute";
    dialog.style.display = "block";
    dialog.style.width = "200px";
    dialog.style.zIndex = "50";
    dialogMessage.value = buffer.toString();
    dialogOk.onClick.listen((html.MouseEvent e) {
      for (hetifile.HetiEntry f in fList) {
        if (f is hetifile.HetiFile) {
          f.remove();
        } else if (f is hetifile.HetiDirectory) {
          f.removeRecursively();
        }
      }
      dialog.style.display = "none";
    });
  }
}
//
//<div id="dialog-save-file" style="width:20%; height:20%; background-color: #ccccff; display:none;">
//<textarea id="dialog-save-file-message" value="none" style="width:100%;"></textarea>
//<button id="dialog-save-file-ok">OK REMOVE</button>
//<button id="dialog-save-file-back">BACK</button>
//</div>
class SaveDialog {
  html.Element dialog = html.querySelector('#dialog-save-file');
  html.ButtonElement dialogOk = html.querySelector('#dialog-save-file-ok');
  html.ButtonElement dialogBack = html.querySelector('#dialog-save-file-back');
  html.TextAreaElement dialogMessage = html.querySelector('#dialog-save-file-message');
  html.TextAreaElement dialogFilename = html.querySelector('#dialog-save-file-name');

  SaveDialog() {
    init();
  }

  void init() {
    dialogOk.onClick.listen((html.MouseEvent e) {
      if (currentBuffer != null) {
        currentBuffer.isChange == false;
        String text = editorNow.value;
        String name = dialogFilename.value;
        currentBuffer.file.getParent().then((hetifile.HetiDirectory d) {
          return d.createFile(name);
        }).then((hetifile.HetiFile file) {
          return file.getHetimaFile().then((hetima.HetimaFile f) {
            return f.write(conv.UTF8.encode(text), 0);
          }).then((hetima.WriteResult r) {
            bufferSetValueFromEntry(file);
          });
        });
      }
      dialog.style.display = "none";
    });
    dialogBack.onClick.listen((html.MouseEvent e) {
      dialog.style.display = "none";
    });
  }

  void show() {
    dialog.style.left = "${html.window.innerWidth/2-100}px";
    dialog.style.top = "${html.window.innerHeight/2-100}px";
    dialog.style.position = "absolute";
    dialog.style.display = "block";
    dialog.style.width = "200px";
    dialog.style.zIndex = "50";
    dialogMessage.value = "support encoding is utf8 only";
    dialogFilename.value = "";
    if (currentBuffer != null) {
      dialogFilename.value = currentBuffer.file.name;
    }
  }
}

class Tab {
  Map<String, String> tabs = {
    "#m00_file": "#con-file", //"#editor-file",
    "#m01_now": "#con-now", //"#editor-now",
    "#m00_clone": "#com-clone"
  };

  html.Element current = null;

  void selectTab(String id) {
    html.Element i = html.querySelector(id);
    print("##click ${i}");

    display([id]);
    i.classes.add("selected");
    if (current != null && current != i) {
      current.classes.remove("selected");
    }
    current = i;

    update([id]);
  }

  void init() {
    for (String t in tabs.keys) {
      html.Element i = html.querySelector(t);
      i.onClick.listen((html.MouseEvent e) {
        selectTab(t);
      });
    }
  }

  void display(List<String> displayList) {
    for (String t in tabs.keys) {
      if (displayList.contains(t)) {
        html.querySelector(tabs[t]).style.display = "block";
      } else {
        html.querySelector(tabs[t]).style.display = "none";
      }
    }
  }

  StreamController<String> _controller = new StreamController<String>();
  Stream<String> get onShow => _controller.stream;
  void update(List<String> ids) {
    for (String id in ids) {
      if (tabs.containsKey(id)) {
        _controller.add(tabs[id]);
      }
    }
  }
}
