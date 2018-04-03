// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@initializeTracker
library initialize.test.foo.bar;

export '../foo.dart';
import '../foo.dart';
import 'package:initialize/src/initialize_tracker.dart';

// Foo should be initialized first.
@initializeTracker
class Bar extends Foo {}

@initializeTracker
bar() {}
