
library which.test.util;

import 'dart:io';

import 'package:mockito/mockito.dart';
import 'package:path/path.dart' as path;
import 'package:which/src/candidate_paths.dart';

getPosixCandidatePaths(String command, String pathVar, String current) {
  var env = {
    'PATH': pathVar
  };
  var isWindows = false;
  var context = new path.Context(style: path.Style.posix, current: current);

  return getCandidatePaths(command, env, isWindows, context);
}

getWindowsCandidatePaths(String command, String pathVar, String pathExtVar, String current) {
  var env = {
    'PATH': pathVar,
    'PATHEXT': pathExtVar
  };
  var isWindows = true;
  var context = new path.Context(style: path.Style.windows, current: current);

  return getCandidatePaths(command, env, isWindows, context);
}

class MockFileStat extends Mock implements FileStat {

  MockFileStat();

  noSuchMethod(i) => super.noSuchMethod(i);
}

int parseBinary(String b) => int.parse(b, radix: 2);
