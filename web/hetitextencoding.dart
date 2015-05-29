library hetitextencoding;
import 'dart:js' as js;
import 'dart:typed_data' as typed;
//import 'package:textencoding_js/' as ajs;

class HetiTextDecoder {
//  js.JsObject _textEncoder = null;
  js.JsObject _textDecoder = null;
  HetiTextDecoder(String encoding) {
    
    _textDecoder = new js.JsObject(js.context["TextDecoder"], [encoding]);

//    _textEncoder = new js.JsObject(js.context["TextEncoder"], [
//      encoding,
//      new js.JsObject.jsify({ "NONSTANDARD_allowLegacyEncoding": true })
//      ]);
  }

//  List<int> encode(String text) {
//    return _textEncoder.callMethod("encode", [text]);
//  }
  
  String decode(List<int> b) {
    return _textDecoder.callMethod("decode",[new typed.Uint8List.fromList(b)]);
  }
}
