part of hetimacore_cl;

abstract class HetimaFile extends HetimaReadBuffer {
  async.Future<int> getLength();
  async.Future<WriteResult> write(Object buffer, int start);
  async.Future<ReadResult> read(int start, int end);
}

abstract class HetimaReadBuffer {
  async.Future<int> getLength();
  async.Future<ReadResult> read(int start, int end);
}

class WriteResult {
}

class ReadResult {
  static final OK = 1;
  static final NG = -1;
  int status = NG;
  data.Uint8List buffer;
  ReadResult(int _status, data.Uint8List _buffer) {
    status = _status;
    buffer = _buffer;
  }
}

class HetimaBuilderToFile extends HetimaFile {
  
  HetimaBuilder mBuilder;
  HetimaBuilderToFile(HetimaBuilder builder) {
    mBuilder = builder;
  }
  @override
  async.Future<int> getLength() {
    return mBuilder.getLength();
  }

  @override
  async.Future<ReadResult> read(int start, int end) {
    async.Completer<ReadResult> cc = new async.Completer();
    mBuilder.getByteFuture(start, end-start).then((List<int> b){
      ReadResult result = new ReadResult(ReadResult.OK,
          new data.Uint8List.fromList(b));
      cc.complete(result);
    }).catchError((e){
      cc.completeError(e);
    });
    return cc.future;
  }

  @override
  async.Future<WriteResult> write(Object buffer, int start) {
    // todo
  }
}

class HetimaFileToBuilder extends HetimaBuilder {

  HetimaFile mFile;

  HetimaFileToBuilder(HetimaFile f) {
    mFile = f;
  }

  @override
  async.Future<List<int>> getByteFuture(int index, int length) {
    async.Completer<List<int>> c = new async.Completer();
    mFile.read(index, index+length).then((ReadResult r) {
      if(r.status == ReadResult.OK) {
        c.complete(r.buffer.toList());
      } else {
        throw new Error();
      }
    }).catchError((e){
      c.completeError(e);
    });
    return c.future;
  }

  @override
  async.Future<int> getLength() {
    return mFile.getLength();
  }
}