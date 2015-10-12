
library which.test.which_impl;

import 'dart:async';

import 'package:unittest/unittest.dart';
import 'package:which/src/which_impl.dart';

import 'util.dart';

main() {
  group('which', () {
    test('should complete to the first matching executable in candidate paths', () {
      var candidatePaths = getPosixCandidatePaths('z', '/x/y:/a/b/c', '/foo/bar');

      return which('z', candidatePaths, false, (path, isWindows) => new Future.value(path == '/x/y/z' || path == '/a/b/c/z'), null)
          .then((path) => expect(path, '/x/y/z'));
    });

    test('should call orElse if command not found', () {
      var candidatePaths = getPosixCandidatePaths('z', '/x/y:/a/b/c', '/foo/bar');

      return which('z', candidatePaths, false, (path, isWindows) => new Future.value(false), () => '/or/else')
          .then((path) => expect(path, '/or/else'));
    });

    test('should throw state error if command not found and orElse not provided', () {
      var future = new Future(() =>
          which('z', [], false, (path, isWindows) => new Future.value(false), null));

      expect(future, throwsStateError);
    });
});

  group('whichSync', () {
    test('should return the first matching executable in candidate paths', () {
      var candidatePaths = getWindowsCandidatePaths('z', r'C:\x\y;C:\a\b\c', '.EXE;.BAT', r'C:\foo\bar');

      var result = whichSync('find', candidatePaths, true, (path, isWindows) => path == r'C:\x\y\z.BAT' || path == r'C:\a\b\c\z.BAT', null);

      expect(result, r'C:\x\y\z.BAT');
    });

    test('should call orElse if command not found', () {
      var candidatePaths = getWindowsCandidatePaths('z', r'C:\x\y;C:\a\b\c', '.EXE;.BAT', r'C:\foo\bar');

      var result = whichSync('find', candidatePaths, true, (path, isWindows) => false, () => r'C:\or\else');

      expect(result, r'C:\or\else');
    });
    test('should throw state error if command not found and orElse not provided', () {
      expect(() => whichSync('z', [], true, (path, isWindows) => false, null), throwsStateError);
    });
  });
}
