library hetimapatrinia.file;

import 'dart:async';
import 'dart:html' as html;
import 'package:hetimacore/hetimacore.dart' as hetima;
import 'package:hetimacore/hetimacore_cl.dart' as hetima;


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
