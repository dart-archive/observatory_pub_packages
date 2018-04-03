// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('vm')
library web_components.test.build.import_inliner_test;

import 'package:transformer_test/utils.dart';
import 'package:web_components/build/import_inliner.dart';
import 'package:web_components/build/messages.dart';
import 'package:test/test.dart';

var transformer = new ImportInlinerTransformer(null, ['{{', '[[']);
var phases = [
  [transformer]
];

main() {
  group('rel=import', importTests);
  group('url attributes', urlAttributeTests);
  group('deep entrypoints', entryPointTests);
  // group('templates', templateTests);
}

void importTests() {
  testPhases(
      'no imports',
      phases,
      {
        'a|web/index.html': '''
        <!DOCTYPE html><html><head></head><body></body></html>''',
      },
      {
        'a|web/index.html': '''
        <!DOCTYPE html><html><head></head><body></body></html>''',
      },
      messages: [],
      formatter: StringFormatter.noNewlinesOrSurroundingWhitespace);

  testPhases(
      'one import, removes dart script',
      phases,
      {
        'a|web/index.html': '''
        <!DOCTYPE html>
        <html>
          <head><link rel="import" href="packages/a/foo.html"></head>
          <body></body>
        </html>''',
        'a|lib/foo.html': '''
        <div>hello from foo!</div>
        <script type="application/dart" src="foo.dart"></script>
        ''',
      },
      {
        'a|web/index.html': '''
        <!DOCTYPE html>
        <html>
          <head></head>
          <body>
            <div hidden="">
              <div>hello from foo!</div>
            </div>
          </body>
        </html>''',
      },
      messages: [],
      formatter: StringFormatter.noNewlinesOrSurroundingWhitespace);

  testPhases(
      'preserves order of scripts',
      phases,
      {
        'a|web/index.html': '''
        <!DOCTYPE html><html><head>
        <script type="text/javascript">/*first*/</script>
        <script src="second.js"></script>
        <link rel="import" href="packages/a/foo.html">
        <script>/*forth*/</script>
        </head></html>''',
        'a|lib/foo.html': '''
        <!DOCTYPE html><html><head><script>/*third*/</script>
        </head><body><polymer-element>2</polymer-element></html>''',
        'a|web/second.js': '/*second*/'
      },
      {
        'a|web/index.html': '''
        <!DOCTYPE html><html><head>
        <script type="text/javascript">/*first*/</script>
        <script src="second.js"></script>
        </head><body>
        <div hidden="">
        <script>/*third*/</script>
        <polymer-element>2</polymer-element>
        <script>/*forth*/</script>
        </div>
        </body></html>''',
      },
      messages: [],
      formatter: StringFormatter.noNewlinesOrSurroundingWhitespace);

  testPhases(
      'preserves order of scripts, extract Dart scripts',
      phases,
      {
        'a|web/index.html': '''
        <!DOCTYPE html>
        <html>
          <head>
            <script type="text/javascript">/*first*/</script>
            <script src="second.js"></script>
            <link rel="import" href="test2.html">
            <script type="application/dart">/*fifth*/</script>
          </head>
        </html>''',
        'a|web/test2.html': '''
        <!DOCTYPE html>
        <html>
          <head>
            <script>/*third*/</script>
            <script type="application/dart">/*forth*/</script>
          </head>
          <body>
            <polymer-element>2</polymer-element>
          </body>
        </html>''',
        'a|web/second.js': '/*second*/'
      },
      {
        'a|web/index.html': '''
        <!DOCTYPE html>
        <html>
          <head>
            <script type="text/javascript">/*first*/</script>
            <script src="second.js"></script>
          </head>
          <body>
            <div hidden="">
            <script>/*third*/</script>
            <polymer-element>2</polymer-element>
            <script type="application/dart">/*fifth*/</script>
            </div>
          </body>
        </html>''',
        'a|web/test2.html': '''
        <!DOCTYPE html>
        <html>
          <head>
            <script>/*third*/</script>
            <script type="application/dart">/*forth*/</script>
          </head>
          <body>
            <polymer-element>2</polymer-element>
          </body>
        </html>''',
      },
      messages: [],
      formatter: StringFormatter.noNewlinesOrSurroundingWhitespace);

  testPhases(
      'no transformation outside web/',
      phases,
      {
        'a|lib/test.html': '''
        <!DOCTYPE html><html><head>
        <link rel="import" href="test2.html">
        </head></html>''',
        'a|lib/test2.html': '''
        <!DOCTYPE html><html><head>
        </head><body><polymer-element>2</polymer-element></html>''',
      },
      {
        'a|lib/test.html': '''
        <!DOCTYPE html><html><head>
        <link rel="import" href="test2.html">
        </head></html>''',
        'a|lib/test2.html': '''
        <!DOCTYPE html><html><head>
        </head><body><polymer-element>2</polymer-element></html>''',
      },
      messages: [],
      formatter: StringFormatter.noNewlinesOrSurroundingWhitespace);

  testPhases(
      'shallow, elements, many',
      phases,
      {
        'a|web/test.html': '''
        <!DOCTYPE html><html><head>
        <link rel="import" href="test2.html">
        <link rel="import" href="test3.html">
        </head></html>''',
        'a|web/test2.html': '''
        <!DOCTYPE html><html><head>
        </head><body><polymer-element>2</polymer-element></html>''',
        'a|web/test3.html': '''
        <!DOCTYPE html><html><head>
        </head><body><polymer-element>3</polymer-element></html>''',
      },
      {
        'a|web/test.html': '''
        <!DOCTYPE html><html><head>
        </head><body>
        <div hidden="">
        <polymer-element>2</polymer-element>
        <polymer-element>3</polymer-element>
        </div>
        </body></html>''',
        'a|web/test2.html': '''
        <!DOCTYPE html><html><head>
        </head><body><polymer-element>2</polymer-element></html>''',
        'a|web/test3.html': '''
        <!DOCTYPE html><html><head>
        </head><body><polymer-element>3</polymer-element></html>''',
      },
      messages: [],
      formatter: StringFormatter.noNewlinesOrSurroundingWhitespace);

  testPhases(
      'deep, elements, one per file',
      phases,
      {
        'a|web/test.html': '''
        <!DOCTYPE html><html><head>
        <link rel="import" href="test2.html">
        </head></html>''',
        'a|web/test2.html': '''
        <!DOCTYPE html><html><head>
        <link rel="import" href="assets/b/test3.html">
        </head><body><polymer-element>2</polymer-element></html>''',
        'b|asset/test3.html': '''
        <!DOCTYPE html><html><head>
        <link rel="import" href="../../packages/c/test4.html">
        </head><body><polymer-element>3</polymer-element></html>''',
        'c|lib/test4.html': '''
        <!DOCTYPE html><html><head>
        </head><body><polymer-element>4</polymer-element></html>''',
      },
      {
        'a|web/test.html': '''
        <!DOCTYPE html><html><head>
        </head><body>
        <div hidden="">
        <polymer-element>4</polymer-element>
        <polymer-element>3</polymer-element>
        <polymer-element>2</polymer-element>
        </div>
        </body></html>''',
        'a|web/test2.html': '''
        <!DOCTYPE html><html><head>
        </head><body>
        <div hidden="">
        <polymer-element>4</polymer-element>
        <polymer-element>3</polymer-element>
        </div>
        <polymer-element>2</polymer-element>
        </body></html>''',
        'b|asset/test3.html': '''
        <!DOCTYPE html><html><head>
        <link rel="import" href="../../packages/c/test4.html">
        </head><body><polymer-element>3</polymer-element></html>''',
        'c|lib/test4.html': '''
        <!DOCTYPE html><html><head>
        </head><body><polymer-element>4</polymer-element></html>''',
      },
      messages: [],
      formatter: StringFormatter.noNewlinesOrSurroundingWhitespace);

  testPhases(
      'deep, elements, many imports',
      phases,
      {
        'a|web/test.html': '''
        <!DOCTYPE html><html><head>
        <link rel="import" href="test2a.html">
        <link rel="import" href="test2b.html">
        </head></html>''',
        'a|web/test2a.html': '''
        <!DOCTYPE html><html><head>
        <link rel="import" href="test3a.html">
        <link rel="import" href="test3b.html">
        </head><body><polymer-element>2a</polymer-element></body></html>''',
        'a|web/test2b.html': '''
        <!DOCTYPE html><html><head>
        <link rel="import" href="test4a.html">
        <link rel="import" href="test4b.html">
        </head><body><polymer-element>2b</polymer-element></body></html>''',
        'a|web/test3a.html': '''
        <!DOCTYPE html><html><head>
        </head><body><polymer-element>3a</polymer-element></body></html>''',
        'a|web/test3b.html': '''
        <!DOCTYPE html><html><head>
        </head><body><polymer-element>3b</polymer-element></body></html>''',
        'a|web/test4a.html': '''
        <!DOCTYPE html><html><head>
        </head><body><polymer-element>4a</polymer-element></body></html>''',
        'a|web/test4b.html': '''
        <!DOCTYPE html><html><head>
        </head><body><polymer-element>4b</polymer-element></body></html>''',
      },
      {
        'a|web/test.html': '''
        <!DOCTYPE html><html><head>
        </head><body>
        <div hidden="">
        <polymer-element>3a</polymer-element>
        <polymer-element>3b</polymer-element>
        <polymer-element>2a</polymer-element>
        <polymer-element>4a</polymer-element>
        <polymer-element>4b</polymer-element>
        <polymer-element>2b</polymer-element>
        </div>
        </body></html>''',
        'a|web/test2a.html': '''
        <!DOCTYPE html><html><head>
        </head><body>
        <div hidden="">
        <polymer-element>3a</polymer-element>
        <polymer-element>3b</polymer-element>
        </div>
        <polymer-element>2a</polymer-element>
        </body></html>''',
        'a|web/test2b.html': '''
        <!DOCTYPE html><html><head>
        </head><body>
        <div hidden="">
        <polymer-element>4a</polymer-element>
        <polymer-element>4b</polymer-element>
        </div>
        <polymer-element>2b</polymer-element>
        </body></html>''',
        'a|web/test3a.html': '''
        <!DOCTYPE html><html><head>
        </head><body>
        <polymer-element>3a</polymer-element>
        </body></html>''',
        'a|web/test3b.html': '''
        <!DOCTYPE html><html><head>
        </head><body>
        <polymer-element>3b</polymer-element>
        </body></html>''',
        'a|web/test4a.html': '''
        <!DOCTYPE html><html><head>
        </head><body>
        <polymer-element>4a</polymer-element>
        </body></html>''',
        'a|web/test4b.html': '''
        <!DOCTYPE html><html><head>
        </head><body>
        <polymer-element>4b</polymer-element>
        </body></html>''',
      },
      messages: [],
      formatter: StringFormatter.noNewlinesOrSurroundingWhitespace);

  testPhases(
      'imports cycle, 1-step lasso',
      phases,
      {
        'a|web/test.html': '''
        <!DOCTYPE html><html><head>
        <link rel="import" href="test_1.html">
        </head></html>''',
        'a|web/test_1.html': '''
        <!DOCTYPE html><html><head>
        <link rel="import" href="test_2.html">
        </head><body><polymer-element>1</polymer-element></html>''',
        'a|web/test_2.html': '''
        <!DOCTYPE html><html><head>
        <link rel="import" href="test_1.html">
        </head><body><polymer-element>2</polymer-element></html>''',
      },
      {
        'a|web/test.html': '''
        <!DOCTYPE html><html><head>
        </head><body>
        <div hidden="">
        <polymer-element>2</polymer-element>
        <polymer-element>1</polymer-element>
        </div>
        </body></html>''',
        'a|web/test_1.html': '''
        <!DOCTYPE html><html><head>
        </head><body>
        <div hidden="">
        <polymer-element>2</polymer-element>
        </div>
        <polymer-element>1</polymer-element></body></html>''',
        'a|web/test_2.html': '''
        <!DOCTYPE html><html><head>
        </head><body>
        <div hidden="">
        <polymer-element>1</polymer-element>
        </div>
        <polymer-element>2</polymer-element></body></html>''',
      },
      messages: [],
      formatter: StringFormatter.noNewlinesOrSurroundingWhitespace);

  testPhases(
      'imports cycle, 1-step lasso, scripts too',
      phases,
      {
        'a|web/test.html': '''
        <!DOCTYPE html><html><head>
        <link rel="import" href="test_1.html">
        </head></html>''',
        'a|web/test_1.html': '''
        <!DOCTYPE html><html><head>
        <link rel="import" href="test_2.html">
        </head><body><polymer-element>1</polymer-element>
        <script src="s1"></script></html>''',
        'a|web/test_2.html': '''
        <!DOCTYPE html><html><head>
        <link rel="import" href="test_1.html">
        </head><body><polymer-element>2</polymer-element>
        <script src="s2"></script></html>''',
      },
      {
        'a|web/test.html': '''
        <!DOCTYPE html><html><head>
        </head><body>
        <div hidden="">
        <polymer-element>2</polymer-element>
        <script src="s2"></script>
        <polymer-element>1</polymer-element>
        <script src="s1"></script>
        </div>
        </body></html>''',
        'a|web/test_1.html': '''
        <!DOCTYPE html><html><head>
        </head><body>
        <div hidden="">
        <polymer-element>2</polymer-element>
        <script src="s2"></script>
        </div>
        <polymer-element>1</polymer-element>
        <script src="s1"></script></body></html>''',
        'a|web/test_2.html': '''
        <!DOCTYPE html><html><head>
        </head><body>
        <div hidden="">
        <polymer-element>1</polymer-element>
        <script src="s1"></script>
        </div>
        <polymer-element>2</polymer-element>
        <script src="s2"></script></body></html>''',
      },
      messages: [],
      formatter: StringFormatter.noNewlinesOrSurroundingWhitespace);

  testPhases(
      'imports cycle, 1-step lasso, Dart scripts too',
      phases,
      {
        'a|web/test.html': '''
        <!DOCTYPE html><html><head>
        <link rel="import" href="test_1.html">
        </head></html>''',
        'a|web/test_1.html': '''
        <!DOCTYPE html><html><head>
        <link rel="import" href="test_2.html">
        </head><body><polymer-element>1</polymer-element>
        <script type="application/dart" src="s1.dart"></script>
        </html>''',
        'a|web/test_2.html': '''
        <!DOCTYPE html><html><head>
        <link rel="import" href="test_1.html">
        </head><body><polymer-element>2
        <script type="application/dart" src="s2.dart"></script>
        </polymer-element>
        </html>''',
        'a|web/s1.dart': '',
        'a|web/s2.dart': '',
      },
      {
        'a|web/test.html': '''
        <!DOCTYPE html><html><head>
        </head><body>
        <div hidden="">
        <polymer-element>2</polymer-element>
        <polymer-element>1</polymer-element>
        </div>
        </body></html>''',
        'a|web/test_1.html': '''
        <!DOCTYPE html><html><head>
        </head><body>
        <div hidden="">
        <polymer-element>2</polymer-element>
        </div>
        <polymer-element>1</polymer-element>
        <script type="application/dart" src="s1.dart"></script>
        </body></html>''',
        'a|web/test_2.html': '''
        <!DOCTYPE html><html><head>
        </head><body>
        <div hidden="">
        <polymer-element>1</polymer-element>
        </div>
        <polymer-element>2
        <script type="application/dart" src="s2.dart"></script>
        </polymer-element>
        </body></html>''',
      },
      messages: [],
      formatter: StringFormatter.noNewlinesOrSurroundingWhitespace);

  testPhases(
      'imports with Dart script after JS script',
      phases,
      {
        'a|web/test.html': '''
        <!DOCTYPE html><html><head>
        <link rel="import" href="test_1.html">
        </head></html>''',
        'a|web/test_1.html': '''
        <!DOCTYPE html><html><head>
        <link rel="import" href="test_1.html">
        </head><body>
        <foo>42</foo><bar-baz></bar-baz>
        <polymer-element>1'
        <script src="s1.js"></script>
        <script type="application/dart" src="s1.dart"></script>
        </polymer-element>
        'FOO'</body></html>''',
        'a|web/s1.dart': '',
      },
      {
        'a|web/test.html': '''
        <!DOCTYPE html><html><head>
        </head><body>
        <div hidden="">
        <foo>42</foo><bar-baz></bar-baz>
        <polymer-element>1'
        <script src="s1.js"></script>
        </polymer-element>
        'FOO'
        </div>
        </body></html>''',
        'a|web/test_1.html': '''
        <!DOCTYPE html><html><head>
        </head><body>
        <foo>42</foo><bar-baz></bar-baz>
        <polymer-element>1'
        <script src="s1.js"></script>
        <script type="application/dart" src="s1.dart"></script>
        </polymer-element>
        'FOO'</body></html>''',
      },
      messages: [],
      formatter: StringFormatter.noNewlinesOrSurroundingWhitespace);

  testPhases(
      'imports cycle, 2-step lasso',
      phases,
      {
        'a|web/test.html': '''
        <!DOCTYPE html><html><head>
        <link rel="import" href="test_1.html">
        </head></html>''',
        'a|web/test_1.html': '''
        <!DOCTYPE html><html><head>
        <link rel="import" href="test_2.html">
        </head><body><polymer-element>1</polymer-element></html>''',
        'a|web/test_2.html': '''
        <!DOCTYPE html><html><head>
        <link rel="import" href="test_3.html">
        </head><body><polymer-element>2</polymer-element></html>''',
        'a|web/test_3.html': '''
        <!DOCTYPE html><html><head>
        <link rel="import" href="test_1.html">
        </head><body><polymer-element>3</polymer-element></html>''',
      },
      {
        'a|web/test.html': '''
        <!DOCTYPE html><html><head>
        </head><body>
        <div hidden="">
        <polymer-element>3</polymer-element>
        <polymer-element>2</polymer-element>
        <polymer-element>1</polymer-element>
        </div>
        </body></html>''',
        'a|web/test_1.html': '''
        <!DOCTYPE html><html><head>
        </head><body>
        <div hidden="">
        <polymer-element>3</polymer-element>
        <polymer-element>2</polymer-element>
        </div>
        <polymer-element>1</polymer-element></body></html>''',
        'a|web/test_2.html': '''
        <!DOCTYPE html><html><head>
        </head><body>
        <div hidden="">
        <polymer-element>1</polymer-element>
        <polymer-element>3</polymer-element>
        </div>
        <polymer-element>2</polymer-element></body></html>''',
        'a|web/test_3.html': '''
        <!DOCTYPE html><html><head>
        </head><body>
        <div hidden="">
        <polymer-element>2</polymer-element>
        <polymer-element>1</polymer-element>
        </div>
        <polymer-element>3</polymer-element></body></html>''',
      },
      messages: [],
      formatter: StringFormatter.noNewlinesOrSurroundingWhitespace);

  testPhases(
      'imports cycle, self cycle',
      phases,
      {
        'a|web/test.html': '''
        <!DOCTYPE html><html><head>
        <link rel="import" href="test_1.html">
        </head></html>''',
        'a|web/test_1.html': '''
        <!DOCTYPE html><html><head>
        <link rel="import" href="test_1.html">
        </head><body><polymer-element>1</polymer-element></html>''',
      },
      {
        'a|web/test.html': '''
        <!DOCTYPE html><html><head>
        </head><body>
        <div hidden="">
        <polymer-element>1</polymer-element>
        </div>
        </body></html>''',
        'a|web/test_1.html': '''
        <!DOCTYPE html><html><head>
        </head><body>
        <polymer-element>1</polymer-element></body></html>''',
      },
      messages: [],
      formatter: StringFormatter.noNewlinesOrSurroundingWhitespace);

  testPhases(
      'imports DAG',
      phases,
      {
        'a|web/test.html': '''
        <!DOCTYPE html><html><head>
        <link rel="import" href="test_1.html">
        <link rel="import" href="test_2.html">
        </head></html>''',
        'a|web/test_1.html': '''
        <!DOCTYPE html><html><head>
        <link rel="import" href="test_3.html">
        </head><body><polymer-element>1</polymer-element></body></html>''',
        'a|web/test_2.html': '''
        <!DOCTYPE html><html><head>
        <link rel="import" href="test_3.html">
        </head><body><polymer-element>2</polymer-element></body></html>''',
        'a|web/test_3.html': '''
        <!DOCTYPE html><html><head>
        </head><body><polymer-element>3</polymer-element></body></html>''',
      },
      {
        'a|web/test.html': '''
        <!DOCTYPE html><html><head>
        </head><body>
        <div hidden="">
        <polymer-element>3</polymer-element>
        <polymer-element>1</polymer-element>
        <polymer-element>2</polymer-element>
        </div>
        </body></html>''',
        'a|web/test_1.html': '''
        <!DOCTYPE html><html><head>
        </head><body>
        <div hidden="">
        <polymer-element>3</polymer-element>
        </div>
        <polymer-element>1</polymer-element></body></html>''',
        'a|web/test_2.html': '''
        <!DOCTYPE html><html><head>
        </head><body>
        <div hidden="">
        <polymer-element>3</polymer-element>
        </div>
        <polymer-element>2</polymer-element></body></html>''',
        'a|web/test_3.html': '''
        <!DOCTYPE html><html><head>
        </head><body>
        <polymer-element>3</polymer-element></body></html>''',
      },
      messages: [],
      formatter: StringFormatter.noNewlinesOrSurroundingWhitespace);

  testPhases(
      'missing html imports throw errors',
      phases,
      {
        'a|web/test.html': '''
        <!DOCTYPE html><html><head>
        <link rel="import" href="foo.html">
        </head></html>''',
      },
      {},
      messages: [
        'warning: ${inlineImportFail.create({
          'error': 'Could not find asset a|web/foo.html.'
      }).snippet} '
            '(web/test.html 1 8)',
      ],
      formatter: StringFormatter.noNewlinesOrSurroundingWhitespace);

  testPhases(
      'absolute uri',
      phases,
      {
        'a|web/test.html': '''
        <!DOCTYPE html><html><head>
        <link rel="stylesheet" href="/foo.css">
        </head></html>''',
        'a|web/test2.html': '''
        <!DOCTYPE html><html><head>
        <link rel="stylesheet" href="http:example.com/bar.css">
        </head></html>''',
      },
      {
        'a|web/test.html': '''
        <!DOCTYPE html><html><head>
        <link rel="stylesheet" href="/foo.css">
        </head></html>''',
        'a|web/test2.html': '''
        <!DOCTYPE html><html><head>
        <link rel="stylesheet" href="http:example.com/bar.css">
        </head></html>''',
      },
      messages: [],
      formatter: StringFormatter.noNewlinesOrSurroundingWhitespace);
}

void urlAttributeTests() {
  testPhases(
      'url attributes are normalized',
      phases,
      {
        'a|web/test.html': '''
        <!DOCTYPE html><html><head>
        <link rel="import" href="foo/test_1.html">
        <link rel="import" href="foo/test_2.html">
        </head></html>''',
        'a|web/foo/test_1.html': '''
        <script src="baz.jpg"></script>''',
        'a|web/foo/test_2.html': '''
        <foo-element src="baz.jpg"></foo-element>''',
      },
      {
        'a|web/test.html': '''
        <!DOCTYPE html><html><head></head><body>
        <div hidden="">
        <script src="foo/baz.jpg"></script>
        <foo-element src="baz.jpg"></foo-element>
        </div>
        </body></html>''',
        'a|web/foo/test_1.html': '''
        <script src="baz.jpg"></script>''',
        'a|web/foo/test_2.html': '''
        <foo-element src="baz.jpg"></foo-element>''',
      },
      messages: [],
      formatter: StringFormatter.noNewlinesOrSurroundingWhitespace);

  testPhases(
      'paths with an invalid prefix are not normalized',
      phases,
      {
        'a|web/test.html': '''
        <!DOCTYPE html><html><head>
        <link rel="import" href="packages/a/test.html">
        </head></html>''',
        'a|lib/test.html': '''
        <img src="[[bar]]">''',
      },
      {
        'a|web/test.html': '''
        <!DOCTYPE html><html><head></head><body>
        <div hidden="">
        <img src="[[bar]]">
        </div>
        </body></html>''',
      },
      messages: [],
      formatter: StringFormatter.noNewlinesOrSurroundingWhitespace);

  testPhases(
      'relative paths followed by invalid characters are normalized',
      phases,
      {
        'a|web/test.html': '''
        <!DOCTYPE html><html><head>
        <link rel="import" href="foo/test.html">
        </head></html>''',
        'a|web/foo/test.html': '''
        <img src="baz/{{bar}}">
        <img src="./{{bar}}">''',
      },
      {
        'a|web/test.html': '''
        <!DOCTYPE html><html><head></head><body>
        <div hidden="">
        <img src="foo/baz/{{bar}}">
        <img src="foo/{{bar}}">
        </div>
        </body></html>''',
      },
      formatter: StringFormatter.noNewlinesOrSurroundingWhitespace);

  testPhases(
      'relative paths in _* attributes are normalized',
      phases,
      {
        'a|web/test.html': '''
        <!DOCTYPE html><html><head>
        <link rel="import" href="foo/test.html">
        </head></html>''',
        'a|web/foo/test.html': '''
        <img _src="./{{bar}}">
        <a _href="./{{bar}}">test</a>''',
      },
      {
        'a|web/test.html': '''
        <!DOCTYPE html><html><head></head><body>
        <div hidden="">
        <img _src="foo/{{bar}}">
        <a _href="foo/{{bar}}">test</a>
        </div>
        </body></html>''',
      },
      messages: [],
      formatter: StringFormatter.noNewlinesOrSurroundingWhitespace);

  testPhases(
      'paths starting with a binding are treated as absolute',
      phases,
      {
        'a|web/test.html': '''
        <!DOCTYPE html><html><head>
        <link rel="import" href="packages/a/foo.html">
        </head></html>''',
        'a|lib/foo.html': '''
        <img _src="{{bar}}">
        <img _src="[[bar]]">''',
      },
      {
        'a|web/test.html': '''
        <!DOCTYPE html><html><head></head><body>
        <div hidden="">
          <img _src="{{bar}}">
          <img _src="[[bar]]">
        </div>
        </body></html>''',
      },
      messages: [],
      formatter: StringFormatter.noNewlinesOrSurroundingWhitespace);

  testPhases(
      'arbitrary bindings can exist in paths',
      phases,
      {
        'a|web/test.html': '''
        <!DOCTYPE html><html><head></head><body>
        <img src="./{{(bar[2] + baz[\'foo\']) * 14 / foobar() - 0.5}}.jpg">
        <img src="./[[bar[2]]].jpg">
        </body></html>''',
      },
      {
        'a|web/test.html': '''
        <!DOCTYPE html><html><head></head><body>
        <img src="{{(bar[2] + baz[\'foo\']) * 14 / foobar() - 0.5}}.jpg">
        <img src="[[bar[2]]].jpg">
        </body></html>''',
      },
      formatter: StringFormatter.noNewlinesOrSurroundingWhitespace);

  testPhases(
      'multiple bindings can exist in paths',
      phases,
      {
        'a|web/test.html': '''
        <!DOCTYPE html><html><head></head><body>
        <img src="./{{bar[0]}}/{{baz[1]}}.{{extension}}">
        </body></html>''',
      },
      {
        'a|web/test.html': '''
        <!DOCTYPE html><html><head></head><body>
        <img src="{{bar[0]}}/{{baz[1]}}.{{extension}}">
        </body></html>''',
      },
      formatter: StringFormatter.noNewlinesOrSurroundingWhitespace);

  testPhases(
      'relative paths in deep imports',
      phases,
      {
        'a|web/test.html': '''
        <!DOCTYPE html><html><head>
        <link rel="import" href="foo/foo.html">
        </head></html>''',
        'a|web/foo/foo.html': '''
        <link rel="import" href="bar.html">''',
        'a|web/foo/bar.html': '''
        <style rel="stylesheet" href="baz.css"></style>
        <style rel="stylesheet" href="../css/zap.css"></style>''',
        'a|web/foo/baz.css': '',
        'a|web/css/zap.css': '',
      },
      {
        'a|web/test.html': '''
        <!DOCTYPE html><html><head></head><body>
        <div hidden="">
          <style rel="stylesheet" href="foo/baz.css"></style>
          <style rel="stylesheet" href="css/zap.css"></style>
        </div>
        </body></html>''',
      },
      messages: [],
      formatter: StringFormatter.noNewlinesOrSurroundingWhitespace);
}

void entryPointTests() {
  testPhases(
      'one level deep entry points normalize correctly',
      phases,
      {
        'a|web/test/test.html': '''
        <!DOCTYPE html><html><head>
        <link rel="import" href="../../packages/a/foo/foo.html">
        </head></html>''',
        'a|lib/foo/foo.html': '''
        <script rel="import" href="../../../packages/b/bar/bar.js">
        </script>''',
        'b|lib/bar/bar.js': '''
        console.log("here");''',
      },
      {
        'a|web/test/test.html': '''
        <!DOCTYPE html><html><head></head><body>
        <div hidden="">
        <script rel="import" href="../packages/b/bar/bar.js"></script>
        </div>
        </body></html>''',
      },
      messages: [],
      formatter: StringFormatter.noNewlinesOrSurroundingWhitespace);

  testPhases(
      'includes in entry points normalize correctly',
      phases,
      {
        'a|web/test/test.html': '''
        <!DOCTYPE html><html><head>
        <script src="packages/a/foo/bar.js"></script>
        </head></html>''',
        'a|lib/foo/bar.js': '''
        console.log("here");''',
      },
      {
        'a|web/test/test.html': '''
        <!DOCTYPE html><html><head>
        <script src="../packages/a/foo/bar.js"></script>
        </head><body>
        </body></html>''',
      },
      messages: [],
      formatter: StringFormatter.noNewlinesOrSurroundingWhitespace);

  testPhases(
      'two level deep entry points normalize correctly',
      phases,
      {
        'a|web/test/well/test.html': '''
        <!DOCTYPE html><html><head>
        <link rel="import" href="../../../packages/a/foo/foo.html">
        </head></html>''',
        'a|lib/foo/foo.html': '''
        <script rel="import" href="../../../packages/b/bar/bar.js"></script>''',
        'b|lib/bar/bar.js': '''
        console.log("here");''',
      },
      {
        'a|web/test/well/test.html': '''
        <!DOCTYPE html><html><head></head><body>
        <div hidden="">
        <script rel="import" href="../../packages/b/bar/bar.js"></script>
        </div>
        </body></html>''',
      },
      messages: [],
      formatter: StringFormatter.noNewlinesOrSurroundingWhitespace);
}

// void templateTests() {
//   testPhases('allows template inside table', phases, {
//     'a|web/index.html': '''
//         <!DOCTYPE html>
//         <html>
//           <head><link rel="import" href="packages/a/foo.html"></head>
//           <body>
//             <dom-module id="hello-element">
//               <template>
//                 <table>
//                   <thead>
//                     <tr><th>first</th><th>last</th></tr>
//                   </thead>
//                   <tbody>
//                     <template is="dom-repeat" items="{{data}}">
//                       <tr>
//                         <td>{{item.first}}</td>
//                         <td>{{item.last}}</td>
//                       </tr>
//                     </template>
//                   </tbody>
//                 </table>
//               </template>
//             </dom-module>
//           </body>
//         </html>''',
//     'a|lib/foo.html': '''
//         <div>hello!</div>
//         ''',
//   }, {
//     'a|web/index.html': '''
//         <!DOCTYPE html>
//         <html>
//           <head></head>
//           <body>
//             <div hidden="">
//               <div>hello!</div>
//             </div>
//             <dom-module id="hello-element">
//               <template>
//                 <table>
//                   <thead>
//                     <tr><th>first</th><th>last</th></tr>
//                   </thead>
//                   <tbody>
//                     <template is="dom-repeat" items="{{data}}">
//                       <tr>
//                         <td>{{item.first}}</td>
//                         <td>{{item.last}}</td>
//                       </tr>
//                     </template>
//                   </tbody>
//                 </table>
//               </template>
//             </dom-module>
//           </body>
//         </html>''',
//   }, messages: [], formatter: StringFormatter.noNewlinesOrSurroundingWhitespace);
// }
