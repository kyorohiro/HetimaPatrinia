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
import 'utils.dart' as git;

part 'src/autocomplete.dart';
part 'src/documents.dart';
part 'src/key_bindings.dart';
part 'src/modes.dart';
part 'src/options.dart';
part 'src/themes.dart';
part 'src/editor_info.dart';

ace.Editor editorFile = ace.edit(html.querySelector('#editor-file'));
ace.Editor editorNow = ace.edit(html.querySelector('#editor-now'));
Tab table = new Tab();

void main() {
  ace.implementation = ACE_PROXY_IMPLEMENTATION;
  editorFile
    ..theme = new ace.Theme.named(ace.Theme.CHROME)
    ..session.mode = new ace.Mode.named(ace.Mode.DART)
    ..readOnly = true;

  editorNow
    ..theme = new ace.Theme.named(ace.Theme.CHROME)
    ..session.mode = new ace.Mode.named(ace.Mode.DART);

  enableAutocomplete(editorNow);

  table.init();

  //
  // <textarea id="com-clone-address" ></textarea>
  // <button id="com-clone-btn">Clone</button>
  // clone
  html.querySelector('#com-clone-btn').onClick.listen((html.MouseEvent e) {
    print("clicj clone button");
    html.TextAreaElement address = html.querySelector('#com-clone-address');
    print("click clone button ${address.value}");
    git.GitLocation location = new git.GitLocation();
    location.init().then((_) {
      git.ObjectStore store = new git.ObjectStore(location.entry);
      git.Clone clone = new git.Clone(new git.GitOptions(repoUrl: address.value, root: location.entry, depth: 1, store: store));
      clone.clone().then((_) {});
    });
  });

  //---------
  //
  //---------
  HetiDirectory currentDir = null;

  Future getRoot() {
    return HetiFileSystem.getFileSystem().then((HetiFileSystem fs) {
      currentDir = fs.root;
    });
  }

  updateList() {
    return currentDir.getList().then((List<HetiEntry> l) {
      StringBuffer b = new StringBuffer();
      b.write(">>${currentDir.fullPath}\n");
      b.write("..");
      b.write("\n--");
      for (HetiEntry e in l) {
        b.write("\n---\n");
        b.write(e.name);
        b.write("\n--");
      }
      b.write("---\n");
      b.write("..");
      b.write("\n--\n");
      editorFile.setValue(b.toString());
    });
  }
  select(int row, int col) {
    int index = row ~/ 3;
    if (index == 0 || index - 1 == (currentDir.lastGetList.length)) {
      currentDir.getParent().then((HetiDirectory d) {
        if (d != null) {
          currentDir = d;
          updateList();
        }
      });
      return;
    } else {
      index = index - 1;
      if (currentDir.lastGetList != null && index < currentDir.lastGetList.length) {
        HetiEntry entry = currentDir.lastGetList[index];
        if (entry is HetiDirectory) {
          currentDir = entry;
          updateList();
        } else if(entry is HetiFile) {
          print("#--f-- 001");
          (entry as HetiFile).getHetimaBuilder().then((hetima.HetimaBuilder b){
            print("#--f-- 002");
            return b.getLength().then((int length) {
              print("#--f-- 003");
              return b.getByteFuture(0, length);
            }).then((List<int> l) {
              print("#--f-- 004${conv.UTF8.decode(l)}");
              editorNow.setValue(conv.UTF8.decode(l));
              print("#--f-- 005");
            }).catchError((e){});
          });
        }
      }
    }
  }
  //
  // support click and ender key
  html.querySelector('#editor-file').onClick.listen((html.MouseEvent e) {
    print("#click {e} ${editorFile.cursorPosition.row} ${editorFile.cursorPosition.column}");
    select(editorFile.cursorPosition.row, editorFile.cursorPosition.column);
  });

  html.querySelector('#editor-file').onKeyDown.listen((html.KeyboardEvent e) {
    print("#key {e} ${e.keyCode} ${editorFile.cursorPosition.row} ${editorFile.cursorPosition.column}");
    select(editorFile.cursorPosition.row, editorFile.cursorPosition.column);
  });

  //
  // update file list
  table.onShow.listen((String s) {
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
    dialog.style.left = "${html.window.innerWidth/2}px";
    dialog.style.top = "${html.window.innerHeight/2}px";
    dialog.style.position = "absolute";
    dialog.style.display = "block";
    dialog.style.zIndex = "50";
  }
}

class Tab {
  Map<String, String> tabs = {"#m00_file": "#editor-file", "#m01_now": "#editor-now", "#m00_clone": "#com-clone"};

  void init() {
    html.Element current = null;
    for (String t in tabs.keys) {
      html.Element i = html.querySelector(t);
      i.onClick.listen((html.MouseEvent e) {
        print("##click ${i}");

        display([t]);
        i.classes.add("selected");
        if (current != null && current != i) {
          current.classes.remove("selected");
        }
        current = i;

        update([t]);
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

// ---
//
// ---

class HetiEntry {
  String get name => "";
  String get fullPath => "";
  bool isFile() {
    return false;
  }
  bool isDirectory() {
    return false;
  }
}

class HetiDirectory extends HetiEntry {
  html.DirectoryEntry _directory = null;
  List<HetiEntry> lastGetList = [];

  HetiDirectory._create(html.DirectoryEntry e) {
    this._directory = e;
  }

  Future<HetiDirectory> getParent() {
    Completer<HetiDirectory> ret = new Completer();
    _directory.getParent().then((html.Entry e) {
      if (e != null) {
        ret.complete(new HetiDirectory._create(e));
      } else {
        ret.complete(null);
      }
    });
    return ret.future;
  }

  bool isDirectory() {
    return true;
  }

  String get name => _directory.name + "/";
  String get fullPath => _directory.fullPath;

  Future<List<HetiEntry>> getList() {
    Completer<List<HetiEntry>> ret = new Completer();
    html.DirectoryReader reader = _directory.createReader();
    reader.readEntries().then((List<html.Entry> l) {
      lastGetList.clear();
      for (html.Entry e in l) {
        if (e.isFile) {
          lastGetList.add(new HetiFile._create(e as html.FileEntry));
        } else {
          lastGetList.add(new HetiDirectory._create(e as html.DirectoryEntry));
        }
      }
      ret.complete(lastGetList);
    });
    return ret.future;
  }
}

class HetiFile extends HetiEntry {
  html.FileEntry _file = null;
  HetiFile._create(html.FileEntry file) {
    this._file = file;
  }
  String get name => _file.name;

  bool isFile() {
    return true;
  }

  Future<hetima.HetimaBuilder> getHetimaBuilder() {
    Completer<hetima.HetimaBuilder> ret = new Completer();
    _file.file().then((html.File f) {
      hetima.HetimaFile ff = new hetima.HetimaFileBlob(f);
      hetima.HetimaBuilder b = new hetima.HetimaFileToBuilder(ff);
      ret.complete(b);
    }).catchError((e){
      ret.completeError(e);
    });
    return ret.future;
  }
}

class HetiFileSystem {
  html.FileSystem _fileSystem = null;
  static Future<HetiFileSystem> getFileSystem() {
    Completer<HetiFileSystem> ret = new Completer();
    html.window.requestFileSystem(100 * 1024 * 1024, persistent: true).then((html.FileSystem fileSystem) {
      ret.complete(new HetiFileSystem._create(fileSystem));
    }).catchError((e) {
      ret.completeError(e);
    });
    return ret.future;
  }

  HetiFileSystem._create(html.FileSystem fileSystem) {
    this._fileSystem = fileSystem;
  }

  HetiDirectory get root {
    html.DirectoryEntry e = _fileSystem.root;
    return new HetiDirectory._create(e);
  }
}
