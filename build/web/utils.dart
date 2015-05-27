// Copyright (c) 2014, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

/**
 * General utilities for testing the git library.
 */
library git.commands.utils;

import 'dart:async';
import 'dart:html' as html;
import 'dart:math' show Random;

import 'package:hetimagit/src/utils.dart';

final String sampleRepoUrl = 'https://github.com/kyorohiro/HelloBeacon.git';

class GitLocation {
  String _name;
  html.DirectoryEntry entry;

  GitLocation() {
    Random r = new Random();
    _name = 'git_${r.nextInt(100)}';
  }

  String get name => _name;

  Future init() {
    print("#### GitLocation#init");
    // Create `git/git_xxx`. Delete the directory if it already exists.
    return getLocalDataDir('git').then((html.DirectoryEntry gitDir) {
      print("#### GitLocation 001 ${name} ${gitDir.fullPath}");
      return gitDir.getDirectory(name).then((dir) {
        print("#### GitLocation 002 ${dir.fullPath}");
        return _safeDelete(dir).then((_) {
          print("#### GitLocation 003 ${_}");
          return gitDir.createDirectory(name).then((d) {
            print("#### createdDirectory ${d}");
            entry = d;
          });
        });
      }).catchError((e) {
        print("#### createdDirectory ERROR ${e}");
        return gitDir.createDirectory(name).then((d) {
          print("#### createdDirectory ERROR [2] ${d}");
          entry = d;
        });
      });
    }).catchError((html.FileError e){
      print("###${e} ${e.message}");
    });
  }

  Future dispose() {
    return new Future.value();
  }

  Future _safeDelete(html.DirectoryEntry dir) {
    return dir.removeRecursively().catchError((e) => null);
  }
}
