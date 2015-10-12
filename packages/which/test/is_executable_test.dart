
library which.test.is_executable;

import 'dart:io';

import 'package:mockito/mockito.dart';
import 'package:unittest/unittest.dart';
import 'package:which/src/is_executable.dart';

import 'util.dart';

main() {
  group('isExecutableStat', () {
    test('false if not a file', () {

      var stat = new MockFileStat();

      // A directory.
      when(stat.type).thenReturn(FileSystemEntityType.DIRECTORY);

      var result = isExecutableStat(stat, false);

      expect(result, isFalse);

      verifyNever(stat.mode);
    });

    test('true for all files on windows', () {

      var stat = new MockFileStat();

      // A file.
      when(stat.type).thenReturn(FileSystemEntityType.FILE);

      var result = isExecutableStat(stat, true);

      expect(result, isTrue);

      verifyNever(stat.mode);
    });

    test('true if has world execute permission', () {
      var result = isExecutableStat(_getMockFileStat('000000000001'), false);
      expect(result, isTrue);
    });

    test('true if has group execute permission', () {
      var result = isExecutableStat(_getMockFileStat('000000001000'), false);
      expect(result, isTrue);
    });

    test('true if has owner execute permission', () {
      var result = isExecutableStat(_getMockFileStat('000001000000'), false);
      expect(result, isTrue);
    });

    test('false if has no execute permissions', () {
      var result = isExecutableStat(_getMockFileStat('111110110110'), false);
      expect(result, isFalse);
    });
  });
}

MockFileStat _getMockFileStat(String mode) {
  var stat = new MockFileStat();

  // A file.
  when(stat.type).thenReturn(FileSystemEntityType.FILE);

  // Last bit is world execute.
  when(stat.mode).thenReturn(int.parse(mode, radix: 2));

  return stat;
}
