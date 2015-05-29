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

hetifile.HetiDirectory currentDir = null;
String coding = "UTF-8";

void main() {
//  new Future.delayed(new Duration(seconds:5),(){
//  te.HetiTextDecoder sjisEnc = new te.HetiTextDecoder("shift_jis");
//  print("### => ${sjisEnc.decode([65, 66, 67, 68])} ${sjisEnc.decode([0x41, 0x42, 0x43, 0x84, 0x44]).length}");
//  });
  ace.implementation = ACE_PROXY_IMPLEMENTATION;
  editorFile
    ..theme = new ace.Theme.named(ace.Theme.CHROME)
    ..session.mode = new ace.Mode.named(ace.Mode.DART)
    ..readOnly = true;

  editorNow
    ..theme = new ace.Theme.named(ace.Theme.CHROME)
    ..session.mode = new ace.Mode.named(ace.Mode.DART)
    ..readOnly = true;

  enableAutocomplete(editorNow);

  tab.init();

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
    select(editorFile.cursorPosition.row, editorFile.cursorPosition.column);
  });

  html.querySelector('#editor-file').onKeyDown.listen((html.KeyboardEvent e) {
    print("#psuh key ${e.keyCode} ${editorFile.cursorPosition.row} ${editorFile.cursorPosition.column}");
    select(editorFile.cursorPosition.row, editorFile.cursorPosition.column);
  });

  //
  // update file list
  tab.onShow.listen((String s) {
    if (s == "#editor-file") {
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
    clone.clone().then((_) {});
  });
}


Future getRoot() {
  return hetifilecl.DomJSHetiFileSystem.getFileSystem().then((hetifile.HetiFileSystem fs) {
    currentDir = fs.root;
  });
}

updateList() {
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

select(int row, int col) {
  int index = row ~/ 3;
  if (index == 0 || index - 1 == (currentDir.lastGetList.length)) {
    currentDir.getParent().then((hetifile.HetiDirectory d) {
      if (d != null) {
        currentDir = d;
        updateList();
      }
    });
    return;
  } else {
    index = index - 1;
    if (currentDir.lastGetList != null && index < currentDir.lastGetList.length) {
      hetifile.HetiEntry entry = currentDir.lastGetList[index];
      if (entry is hetifile.HetiDirectory) {
        currentDir = entry;
        updateList();
      } else if(entry is hetifile.HetiFile) {
        //(entry as hetifile.HetiFile)
        entry.getHetimaBuilder().then((hetima.HetimaBuilder b){
          return b.getLength().then((int length) {
            return b.getByteFuture(0, length);
          }).then((List<int> l) {
            tab.selectTab("#m01_now");
            try {
              print("### ${entry.name}");
              te.HetiTextDecoder enc = new te.HetiTextDecoder(coding);
              ;
              editorNow.session.mode = new ace.Mode.forFile(entry.name);
              if(coding == "UTF-8") {
                editorNow.setValue(conv.UTF8.decode(l,allowMalformed:true));
              } else {
                editorNow.setValue(enc.decode(l));
              }
              editorNow.focus();
              editorNow.clearSelection();
            } catch(e) {
              print("### ERROR 001 ${e}");
            }
          }).catchError((e){});
        });
      }
    }
  }
}


class Dialog {
  html.Element dialog = html.querySelector('#dialog');
  html.ButtonElement dialogBtn = html.querySelector('#dialog-btn');

  Dialog() {
    init();
  }

  void init() {
    dialogBtn.onClick.listen((html.MouseEvent e) {
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
  }
}

class Tab {
  Map<String, String> tabs = {"#m00_file": "#editor-file", "#m01_now": "#editor-now", "#m00_clone": "#com-clone"};

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

