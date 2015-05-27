library hetimapatrinia.file;

import 'dart:async';
import 'dart:html' as html;
import 'package:hetimacore/hetimacore.dart' as hetima;
import 'package:hetimacore/hetimacore_cl.dart' as hetima;
import 'dart:js' as js;

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

abstract class HetiDirectory extends HetiEntry {
  List<HetiEntry> lastGetList = [];
  Future<HetiDirectory> getParent();
  bool isDirectory();
  String get name;
  String get fullPath;
  Future<List<HetiEntry>> getList();
}

class DomJSHetiDirectory extends HetiDirectory  {
  js.JsObject _directory = null;
  List<HetiEntry> lastGetList = [];

  DomJSHetiDirectory._create(js.JsObject e) {
    this._directory = e;
  }

  Future<HetiDirectory> getParent() {
    Completer<HetiDirectory> ret = new Completer();
    _directory.callMethod("getParent",[
      (a){
        if(a != null) {
          ret.complete(new DomJSHetiDirectory._create(a));
        } else {
          ret.complete(null);
        }
      },
      (b){
        ret.completeError(b);
      }]);
    return ret.future;
  }

  bool isDirectory() {
    return true;
  }

  String get name => _directory["name"] + "/";
  String get fullPath => _directory["fullPath"];

  Future<List<HetiEntry>> getList() {
    Completer<List<HetiEntry>> ret = new Completer();
    js.JsObject reader = _directory.callMethod("createReader");
    reader.callMethod("readEntries",[
      (a){
        lastGetList.clear();
        js.JsArray b = a;
        for(js.JsObject c in b.toList()) {
          print("### getList ${c} ${c.runtimeType} ${c["isDirectory"]}");
          if(true == c["isDirectory"]) {
            lastGetList.add(new DomJSHetiDirectory._create(c));
          } else if (true == c["isFile"]){
            lastGetList.add(new DomJSHetiFile._create(c));
          }
        }
        print("onRead ${a} ${a.runtimeType}");
        ret.complete(lastGetList);
      },
      (b){print("onRead error");ret.completeError(b);}]);

    return ret.future;
  }

}


class DomHetiDirectory extends HetiDirectory  {
  html.DirectoryEntry _directory = null;
  List<HetiEntry> lastGetList = [];

  DomHetiDirectory._create(html.DirectoryEntry e) {
    this._directory = e;
  }

  Future<HetiDirectory> getParent() {
    Completer<HetiDirectory> ret = new Completer();
    _directory.getParent().then((html.Entry e) {
      if (e != null) {
        ret.complete(new DomHetiDirectory._create(e));
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
          lastGetList.add(new DomHetiFile._create(e as html.FileEntry));
        } else {
          lastGetList.add(new DomHetiDirectory._create(e as html.DirectoryEntry));
        }
      }
      ret.complete(lastGetList);
    });
    return ret.future;
  }
}

abstract class HetiFile extends HetiEntry {
  String get name;
  bool isFile() {
    return true;
  }
  Future<hetima.HetimaBuilder> getHetimaBuilder();
}

class DomJSHetiFile extends HetiFile {
  js.JsObject _file = null;
  DomJSHetiFile._create(js.JsObject file) {
    this._file = file;
  }
  String get name => _file["name"];

  bool isFile() {
    return true;
  }

  Future<hetima.HetimaBuilder> getHetimaBuilder() {
    Completer<hetima.HetimaBuilder> ret = new Completer();
    _file.callMethod("file",[
      (a){
        hetima.HetimaFile ff = new hetima.HetimaFileBlob(a);
             hetima.HetimaBuilder b = new hetima.HetimaFileToBuilder(ff);
             ret.complete(b);
      },
      (b){
        ret.completeError(b);
      }]);
    return ret.future;
  }
}


class DomHetiFile extends HetiFile {
  html.FileEntry _file = null;
  DomHetiFile._create(html.FileEntry file) {
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
    }).catchError((e) {
      ret.completeError(e);
    });
    return ret.future;
  }
}



abstract class HetiFileSystem {
  HetiDirectory get root;
}


class DomJSHetiFileSystem extends HetiFileSystem {
  js.JsObject _fileSystem = null;
  static Future<HetiFileSystem> getFileSystem() {
    Completer<HetiFileSystem> ret = new Completer();
    js.context.callMethod("webkitRequestFileSystem", [
      1,
      5 * 1024 * 1024,
      (a) {
        ret.complete(new DomJSHetiFileSystem._create(a));
      },
      (b) {
        ret.completeError(b);
      }
    ]);
    return ret.future;
  }

  DomJSHetiFileSystem._create(js.JsObject fileSystem) {
    this._fileSystem = fileSystem;
  }

  HetiDirectory get root {
    return new DomJSHetiDirectory._create(_fileSystem["root"]);
  }
}


class DomHetiFileSystem extends HetiFileSystem {
  html.FileSystem _fileSystem = null;
  static Future<HetiFileSystem> getFileSystem() {
    Completer<HetiFileSystem> ret = new Completer();
    html.window.requestFileSystem(100 * 1024 * 1024, persistent: true).then((html.FileSystem fileSystem) {
      ret.complete(new DomHetiFileSystem._create(fileSystem));
    }).catchError((e) {
      ret.completeError(e);
    });
    return ret.future;
  }

  DomHetiFileSystem._create(html.FileSystem fileSystem) {
    this._fileSystem = fileSystem;
  }

  HetiDirectory get root {
    html.DirectoryEntry e = _fileSystem.root;
    return new DomHetiDirectory._create(e);
  }
}
