
library which.test;

import 'candidate_paths_test.dart' as candidate_paths;
import 'has_permission_test.dart' as has_permission;
import 'is_executable_test.dart' as is_exe;
import 'which_test.dart' as which;
import 'which_impl_test.dart' as which_impl;

main() {
  candidate_paths.main();
  has_permission.main();
  is_exe.main();
  which.main();
  which_impl.main();
}
