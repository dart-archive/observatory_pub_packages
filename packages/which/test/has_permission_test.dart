
library which.test.has_permission;

import 'package:unittest/unittest.dart';
import 'package:which/src/has_permission.dart';

import 'util.dart';

main() {
  test('hasPermission', () {
    var mode = parseBinary('010101010101');

    expect(hasPermission(mode, FilePermission.SET_UID), isFalse);
    expect(hasPermission(mode, FilePermission.SET_GID), isTrue);
    expect(hasPermission(mode, FilePermission.STICKY), isFalse);
    expect(hasPermission(mode, FilePermission.READ, role: FilePermissionRole.OWNER), isTrue);
    expect(hasPermission(mode, FilePermission.WRITE, role: FilePermissionRole.OWNER), isFalse);
    expect(hasPermission(mode, FilePermission.EXECUTE, role: FilePermissionRole.OWNER), isTrue);
    expect(hasPermission(mode, FilePermission.READ, role: FilePermissionRole.GROUP), isFalse);
    expect(hasPermission(mode, FilePermission.WRITE, role: FilePermissionRole.GROUP), isTrue);
    expect(hasPermission(mode, FilePermission.EXECUTE, role: FilePermissionRole.GROUP), isFalse);
    expect(hasPermission(mode, FilePermission.READ, role: FilePermissionRole.WORLD), isTrue);
    expect(hasPermission(mode, FilePermission.WRITE, role: FilePermissionRole.WORLD), isFalse);
    expect(hasPermission(mode, FilePermission.EXECUTE, role: FilePermissionRole.WORLD), isTrue);
  });
}
