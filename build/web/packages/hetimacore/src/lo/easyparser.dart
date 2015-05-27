part of hetimacore;

class EasyParser {
  int index = 0;
  List<int> stack = new List();
  HetimaBuilder buffer = null;
  EasyParser(HetimaBuilder builder) {
    buffer = builder;
  }

  EasyParser toClone() {
    EasyParser parser = new EasyParser(new HetimaBuilderAdapter(buffer, 0));
    parser.index = index;
    parser.stack = new List.from(stack);
    return parser;
  }

  void push() {
    stack.add(index);
  }

  void back() {
    index = stack.last;
  }

  int pop() {
    int ret = stack.last;
    stack.remove(ret);
    return ret;
  }

  int last() {
    return stack.last;
  }

  //
  // [TODO]
  void resetIndex(int _index) {
    index = _index;
  }
  //
  // [TODO]
  int getInedx() {
    return index;
  }
  async.Future<List<int>> getPeek(int length) {
    return buffer.getByteFuture(index, length);
  }

  async.Future<List<int>> nextBuffer(int length) {
    async.Completer<List<int>> completer = new async.Completer();
    buffer.getByteFuture(index, length).then((List<int> v) {
      index += v.length;
      completer.complete(v);
    }).catchError((e) {
      completer.completeError(e);
    });
    return completer.future;
  }

  async.Future<String> nextString(String value) {
    async.Completer completer = new async.Completer();
    List<int> encoded = convert.UTF8.encode(value);
    buffer.getByteFuture(index, encoded.length).then((List<int> v) {
      if (v.length != encoded.length) {
        completer.completeError(new EasyParseError());
        return;
      }
      int i = 0;
      for (int e in encoded) {
        if (e != v[i]) {
          completer.completeError(new EasyParseError());
          return;
        }
        i++;
        index++;
      }
      completer.complete(value);
    });
    return completer.future;
  }

  async.Future<int> nextBytePattern(EasyParserMatcher matcher) {
    async.Completer completer = new async.Completer();
    matcher.init();
    buffer.getByteFuture(index, 1).then((List<int> v) {
      if (v.length < 1) {
        throw new EasyParseError();
      }
      if (matcher.match(v[0])) {
        index++;
        completer.complete(v[0]);
      } else {
        throw new EasyParseError();
      }
    });
    return completer.future;
  }

  async.Future<List<int>> nextBytePatternWithLength(
      EasyParserMatcher matcher, int length) {
    async.Completer completer = new async.Completer();
    matcher.init();
    buffer.getByteFuture(index, length).then((List<int> va) {
      if (va.length < length) {
        completer.completeError(new EasyParseError());
      }
      for (int v in va) {
        bool find = false;
        find = matcher.match(v);
        if (find == false) {
          completer.completeError(new EasyParseError());
        }
        index++;
      }
      completer.complete(va);
    });
    return completer.future;
  }

  async.Future<List<int>> nextBytePatternByUnmatch(EasyParserMatcher matcher,
      [bool keepWhenMatchIsTrue = true]) {
    async.Completer completer = new async.Completer();
    matcher.init();
    List<int> ret = new List<int>();
    async.Future<Object> p() {
      return buffer.getByteFuture(index, 1).then((List<int> va) {
        if (va.length < 1) {
          completer.complete(ret);
        } else if (keepWhenMatchIsTrue == matcher.match(va[0])) {
          ret.add(va[0]);
          index++;
          return p();
        } else if (buffer.immutable) {
          completer.complete(ret);
        } else {
          completer.complete(ret);
        }
      });
    }
    p();
    return completer.future;
  }

  //
  //
  //
  async.Future<String> readSignWithLength(int length) {
    async.Completer<String> completer = new async.Completer();
    buffer.getByteFuture(index, length).then((List<int> va) {
      if (va.length < length) {
        completer.completeError(new EasyParseError());
      } else {
        index += length;
        completer.complete(convert.UTF8.decode(va));
      }
    }).catchError((e) {
      completer.completeError(e);
    });
    return completer.future;
  }
  async.Future<int> readShort(int byteorder) {
    async.Completer<int> completer = new async.Completer();
    buffer.getByteFuture(index, 2).then((List<int> va) {
      if (va.length < 2) {
        completer.completeError(new EasyParseError());
      } else {
        index += 2;
        completer.complete(ByteOrder.parseShort(va, 0, byteorder));
      }
    }).catchError((e) {
      completer.completeError(e);
    });
    return completer.future;
  }

  async.Future<List<int>> readShortArray(int byteorder, int num) {
    async.Completer<List<int>> completer = new async.Completer();
    if (num == 0) {
      completer.complete([]);
      return completer.future;
    }
    buffer.getByteFuture(index, 2 * num).then((List<int> va) {
      if (va.length < 2 * num) {
        completer.completeError(new EasyParseError());
      } else {
        index += 2 * num;
        List<int> l = new List();
        for (int i = 0; i < num; i++) {
          l.add(ByteOrder.parseShort(va, i * 2, byteorder));
        }
        completer.complete(l);
      }
    }).catchError((e) {
      completer.completeError(e);
    });
    return completer.future;
  }

  async.Future<int> readInt(int byteorder) {
    async.Completer<int> completer = new async.Completer();
    buffer.getByteFuture(index, 4).then((List<int> va) {
      if (va.length < 4) {
        completer.completeError(new EasyParseError());
      } else {
        index += 4;
        completer.complete(ByteOrder.parseInt(va, 0, byteorder));
      }
    }).catchError((e) {
      completer.completeError(e);
    });
    return completer.future;
  }

  async.Future<int> readLong(int byteorder) {
    async.Completer<int> completer = new async.Completer();
    buffer.getByteFuture(index, 8).then((List<int> va) {
      if (va.length < 8) {
        completer.completeError(new EasyParseError());
      } else {
        index += 8;
        completer.complete(ByteOrder.parseLong(va, 0, byteorder));
      }
    }).catchError((e) {
      completer.completeError(e);
    });
    return completer.future;
  }

  async.Future<int> readByte([int byteorder]) {
    async.Completer<int> completer = new async.Completer();
    buffer.getByteFuture(index, 1).then((List<int> va) {
      if (va.length < 1) {
        completer.completeError(new EasyParseError());
      } else {
        index += 1;
        completer.complete(va[0]);
      }
    }).catchError((e) {
      completer.completeError(e);
    });
    return completer.future;
  }
}

abstract class EasyParserMatcher {
  void init() {
    ;
  }
  bool match(int target);
  bool matchAll() {
    return true;
  }
}

class EasyParserIncludeMatcher extends EasyParserMatcher {
  List<int> include = null;
  EasyParserIncludeMatcher(List<int> i) {
    include = i;
  }

  bool match(int target) {
    return include.contains(target);
  }
}

class EasyParserStringMatcher extends EasyParserMatcher {
  List<int> include = null;
  int index = 0;
  EasyParserIncludeMatcher(String v) {
    include = convert.UTF8.encode(v);
  }

  void init() {
    index = 0;
  }

  bool match(int target) {
    return include.contains(target);
  }
}
class EasyParseError extends Error {
  EasyParseError();
}
