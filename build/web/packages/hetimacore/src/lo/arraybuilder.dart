part of hetimacore;

class ArrayBuilder extends HetimaBuilder {
  int _max = 1024;
  List<int> _buffer8;
  int _length = 0;

  async.Completer completer = new async.Completer();
  List<GetByteFutureInfo> mGetByteFutreList = new List();

  ArrayBuilder() {
    _buffer8 = new data.Uint8List(_max);
  }

  ArrayBuilder.fromList(List<int> buffer,[isFin = false]) {
    _buffer8 = buffer;
    _length = buffer.length;
    if(isFin == true) {
      fin();
    }
  }

  async.Future<List<int>> getByteFuture(int index, int length) {
    GetByteFutureInfo info = new GetByteFutureInfo();
    info.completerResult = new List();
    info.completerResultLength = length;

    if (completer.isCompleted) {
      completer = new async.Completer();
    }

    int v = index;
    for (index; index < size() && index < (length + v); index++) {
      info.completerResult.add(get(index));
    }


    if ((info.completerResultLength <= info.completerResult.length) || (immutable)) {
      completer.complete(info.completerResult);
      info.completerResult = null;
      info.completerResultLength = 0;
    } else {
      mGetByteFutreList.add(info);
    }

    return completer.future;
  }

  int get(int index) {
    return 0xFF & _buffer8[index];
  }

  void clear() {
    _length = 0;
  }

  int size() {
    return _length;
  }

  async.Future<int> getLength() {
    async.Completer<int> completer = new async.Completer();
    completer.complete(_length);
    return completer.future;
  }

  void update(int plusLength) {
    if (_length + plusLength < _max) {
      return;
    } else {
      int nextMax = _length + plusLength + _max;
      data.Uint8List next = new data.Uint8List(nextMax);
      for (int i = 0; i < _length; i++) {
        next[i] = _buffer8[i];
      }
      // _buffer8.clear();
      _buffer8 = null;
      _buffer8 = next;
      _max = nextMax;
    }
  }

  void fin() {
    for (GetByteFutureInfo f in mGetByteFutreList) {
      if (f.completerResult != null) {
        completer.complete(f.completerResult);
        f.completerResult = null;
        f.completerResultLength = 0;
      }
    }
    mGetByteFutreList.clear();
    immutable = true;
  }

  void appendByte(int v) {
    if (immutable) {
      return;
    }
    update(1);
    _buffer8[_length] = v;
    _length += 1;

    List<GetByteFutureInfo> removeList = new List();
    for (GetByteFutureInfo f in mGetByteFutreList) {
      if (!completer.isCompleted && f.completerResult != null) {
        f.completerResult.add(v);
      }

      if (f.completerResult != null && f.completerResultLength <= f.completerResult.length) {
        completer.complete(f.completerResult);
        f.completerResult = null;
        f.completerResultLength = 0;
        removeList.add(f);
      }
    }
    for (GetByteFutureInfo f in removeList) {
      mGetByteFutreList.remove(f);
    }
  }

  void appendString(String text) {
    List<int> code = convert.UTF8.encode(text);
    update(code.length);
    for (int i = 0; i < code.length; i++) {
      appendByte(code[i]);
    }
  }

  void appendUint8List(data.Uint8List buffer, int index, int length) {
    update(length);
    for (int i = 0; i < length; i++) {
      appendByte(buffer[index + i]);
    }
  }

  void appendIntList(List<int> buffer, int index, int length) {
    update(length);
    for (int i = 0; i < length; i++) {
      appendByte(buffer[index + i]);
    }
  }

  List toList() {
    return _buffer8.sublist(0, _length);
  }

  data.Uint8List toUint8List() {
    return new data.Uint8List.fromList(_buffer8);
  }

  String toText() {
    return convert.UTF8.decode(toList());
  }

}

class GetByteFutureInfo {
  List<int> completerResult = new List();
  int completerResultLength = 0;
}
