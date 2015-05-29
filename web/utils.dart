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

import 'package:hetimafile/hetimafile.dart' as hetifile;
import 'package:hetimafile/hetimafile_cl.dart' as hetifile;
import 'package:hetimafile/src/hetimafile_cl.dart' as hetifile;
import 'package:hetimafile/src/hetimafile_base.dart' as hetifile;

import 'package:hetimagit/src/utils.dart';
import 'package:chrome/chrome_app.dart' as chrome;
import 'package:chrome/src/files.dart' as chrome;

final String sampleRepoUrl = 'https://github.com/kyorohiro/HelloBeacon.git';

class GitLocation {
  String _name;
  html.DirectoryEntry entry;

  GitLocation(String name) {
    if (name == null || name.length == 0) {
      Random r = new Random();
      _name = 'git_${r.nextInt(100)}';
    } else {
      _name = name;
    }
  }

  String get name => _name;

  /**
   * Returns the root directory of the application's persistent local storage.
   */
  Future<hetifile.HetiDirectory> getLocalDataRoot() {
    return hetifile.DomJSHetiFileSystem.getFileSystem().then((hetifile.HetiFileSystem fs) {
      return fs.root;
    });
  }

  /**
   * Creates and returns a directory in persistent local storage. This can be used
   * to cache application data, e.g `getLocalDataDir('workspace')` or
   * `getLocalDataDir('pub')`.
   */
  Future<hetifile.HetiDirectory> getLocalDataDir(String name) {
    return getLocalDataRoot().then((hetifile.HetiDirectory root) {
      return root.createDirectory(name, exclusive: false);
    });
  }

  Future init() {
    print("#### GitLocation#init");
    // Create `git/git_xxx`. Delete the directory if it already exists.
    return getLocalDataDir('git').then((hetifile.HetiDirectory gitDir) {
      print("#### GitLocation 001 ${name} ${gitDir.fullPath}");
      return gitDir.getDirectory(name).then((dir) {
        print("#### GitLocation 002 ${dir.fullPath}");
        return _safeDelete(dir).then((_) {
          print("#### GitLocation 003 ${_}");
          return gitDir.createDirectory(name).then((hetifile.DomJSHetiDirectory d) {
            print("#### createdDirectory ${d}");
            entry = new chrome.CrDirectoryEntry.fromProxy(d.toBinary());
          });
        });
      }).catchError((e) {
        print("#### createdDirectory ERROR ${e}");
        return gitDir.createDirectory(name).then((hetifile.DomJSHetiDirectory d) {
          print("#### createdDirectory ERROR [2] ${d}");
          entry = new chrome.CrDirectoryEntry.fromProxy(d.toBinary());
        });
      });
    }).catchError((html.FileError e) {
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
