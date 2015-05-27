part of hetimacore_cl;

class HetimaFileBlob extends HetimaFile {
  html.Blob _mBlob;

  HetimaFileBlob(bl) {
    _mBlob = bl;
  }

  async.Future<WriteResult> write(Object o, int start) {
    return null;
  }

  async.Future<int> getLength() {
    async.Completer<int> ret = new async.Completer();
    ret.complete(_mBlob.size);
    return ret.future;
  }

  async.Future<ReadResult> read(int start, int end) {
    async.Completer<ReadResult> ret = new async.Completer<ReadResult>();
    html.FileReader reader = new html.FileReader();
    reader.onLoad.listen((html.ProgressEvent e) {
      ret.complete(new ReadResult(ReadResult.OK, reader.result));
    });
    reader.onError.listen((html.Event e) {
      ret.complete(new ReadResult(ReadResult.NG, null));
    });
    reader.onAbort.listen((html.ProgressEvent e) {
      ret.complete(new ReadResult(ReadResult.NG, null));
    });
    reader.readAsArrayBuffer(_mBlob.slice(start, end));
    return ret.future;
  }

}

class HetimaFileGet extends HetimaFile {

  html.Blob _mBlob = null;
  String _mPath = "";

  HetimaFileGet(String path) {
    _mPath = path;
  }

  async.Future<WriteResult> write(Object buffer, int start) {
    return new async.Completer<WriteResult>().future;
  }

  async.Future<html.Blob> getBlob() {
    async.Completer<html.Blob> ret = new async.Completer();
    html.HttpRequest request = new html.HttpRequest();
    request.responseType = "blob";
    request.open("GET", _mPath);
    request.onLoad.listen((html.ProgressEvent e) {
      _mBlob = request.response;
      ret.complete(request.response);
    });
    request.send();
    return ret.future;
  }
/*
  async.Future<core.int> getLength() {
    async.Completer<core.int> ret = new async.Completer();
    if (_mBlob == null) {
      getBlob().then((html.Blob b) {
        ret.complete(b.size);
      });
    } else {
      ret.complete(_mBlob.size);
    }
    return ret.future;
  }
*/
  
//  data.Uint8List bbbuffer = null;
  async.Future<int> getLength() {
    async.Completer<int> ret = new async.Completer();
    if (_mBlob == null) {
      getBlob().then((html.Blob b) {
//        read(0, b.size).then((ReadResult re){
//          bbbuffer = re.buffer;
          ret.complete(b.size);          
//        });
      });
    } else {
      ret.complete(_mBlob.size);
    }
    return ret.future;
  }

  async.Future<ReadResult> read(int start, int end) {
    async.Completer<ReadResult> ret = new async.Completer<ReadResult>();
    if (_mBlob != null) {
//      if(bbbuffer != null) {
//        //core.print("-read read-\n");
//        ret.complete(new ReadResult(ReadResult.OK, bbbuffer.sublist(start, end)));
//        return ret.future;
//      } else {
        return readBase(ret, start, end);
//      }
    } else {
      getBlob().then((html.Blob b) {
        readBase(ret, start, end);
      });
      return ret.future;
    }
  }

  async.Future<ReadResult> readBase(async.Completer<ReadResult> ret, int start, int end) {
    html.FileReader reader = new html.FileReader();
    reader.onLoad.listen((html.ProgressEvent e) {
      ret.complete(new ReadResult(ReadResult.OK, reader.result));
    });
    reader.onError.listen((html.Event e) {
      ret.complete(new ReadResult(ReadResult.NG, null));
    });
    reader.onAbort.listen((html.ProgressEvent e) {
      ret.complete(new ReadResult(ReadResult.NG, null));
    });
    reader.readAsArrayBuffer(_mBlob.slice(start, end));
    return ret.future;
  }

}

class HetimaFileFS extends HetimaFile {
  String fileName = "";
  html.FileEntry _fileEntry = null;

  HetimaFileFS(String name) {
    fileName = name;
  }

  async.Future<html.Entry> getEntry() {
    return init();
  }

  async.Future<html.Entry> init() {
    async.Completer<html.Entry> completer = new async.Completer();
    if (_fileEntry != null) {
      completer.complete(_fileEntry);
      return completer.future;
    }
    html.window.requestFileSystem(1024).then((html.FileSystem e) {
      e.root.createFile(fileName).then((html.Entry e) {
        _fileEntry = (e as html.FileEntry);
        completer.complete(_fileEntry);
      }).catchError((es) {
        completer.complete(null);
      });
    });
    return completer.future;
  }


  async.Future<int> getLength() {
    async.Completer<int> completer = new async.Completer();
    init().then((e) {
      html.FileReader reader = new html.FileReader();
      _fileEntry.file().then((html.File f) {
        completer.complete(f.size);
      });
    });
    return completer.future;
  }


  async.Future<WriteResult> write(Object buffer, int start) {
    async.Completer<WriteResult> completer = new async.Completer();
    init().then((e) {
      _fileEntry.createWriter().then((html.FileWriter writer) {
        writer.onWrite.listen((html.ProgressEvent e) {
          completer.complete(new WriteResult());
        });
        if (start > 0) {
          writer.seek(start);
        }
        writer.write(new html.Blob([buffer]));
      });
    });
    return completer.future;
  }

  async.Future<int> truncate(int fileSize) {
    async.Completer<int> completer = new async.Completer();
    init().then((e) {
      return _fileEntry.createWriter();
    }).then((html.FileWriter writer) {
      writer.truncate(fileSize);
      completer.complete(fileSize);
    }).catchError((e) {
      completer.completeError(e);
    });
    return completer.future;
  }

  async.Future<ReadResult> read(int start, int end) {
    async.Completer<ReadResult> c_ompleter = new async.Completer();
    init().then((e) {
      html.FileReader reader = new html.FileReader();
      _fileEntry.file().then((html.File f) {
        reader.onLoad.listen((html.ProgressEvent e) {
          c_ompleter.complete(new ReadResult(ReadResult.OK, reader.result));
        });
        reader.readAsArrayBuffer(f.slice(start, end));
      });
    });
    return c_ompleter.future;
  }
}
