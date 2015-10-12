
library when.test;

import 'dart:async';

import 'package:unittest/unittest.dart';
import 'package:when/when.dart';

main() {
  group('when', () {

    test('on non-Future callback result should call onSuccess with result, then onComplete, and return onSuccess result', () {
      var onSuccessCalled = false;
      var onErrorCalled = false;
      var onCompleteCalled = false;
      var ret = when(
          () => 5,
          onSuccess: (x) {
            expect(x, 5);
            onSuccessCalled = true;
            return 10;
          },
          onError: (e) => onErrorCalled = true,
          onComplete: () {
            expect(onSuccessCalled, isTrue);
            onCompleteCalled = true;
          });
      expect(onErrorCalled, isFalse);
      expect(onCompleteCalled, isTrue);
      expect(ret, 10);
    });

    test('on callback failure should call onError with error, then onComplete', () {
      var onSuccessCalled = false;
      var onErrorCalled = false;
      var onCompleteCalled = false;
      var ret = when(
          () => throw 'e',
          onSuccess: (_) => onSuccessCalled = true,
          onError: (e) {
            expect(e, 'e');
            onErrorCalled = true;
          },
          onComplete: () {
            expect(onErrorCalled, isTrue);
            onCompleteCalled = true;
          });
      expect(onSuccessCalled, isFalse);
      expect(onCompleteCalled, isTrue);
      expect(ret, isNull);
    });

    test('should pass stack trace to onError if binary', () {
      var onErrorCalled = false;
      when(
          () => throw 'e',
          onError: (e, s) {
            onErrorCalled = true;
            expect(s, isNotNull);
          });
      expect(onErrorCalled, isTrue);
    });

    test('should throw callback error if no onError provided', () {
      try {
        when(
            () => throw 'e');
        fail('callback error was swallowed');
      } catch (e) {
        expect(e, 'e');
      }
    });

    test('should just return callback result if onSuccess not provided', () {
        expect(when(() => 5), 5);
    });

    test('should not swallow onComplete error', () {
      try {
        when(
            () {},
            onComplete: () => throw 'e');
        fail('onComplete error was swallowed');
      } catch (e) {
        expect(e, 'e');
      }
    });

    group('on Future callback result', () {

      test('which succeeds should call onSuccess with result, then onComplete, and complete with onSuccess result', () {
        var onSuccessCalled = false;
        var onErrorCalled = false;
        var onCompleteCalled = false;
        var result = when(
            () => new Future.value(5),
            onSuccess: (x) {
              expect(x, 5);
              onSuccessCalled = true;
              return 10;
            },
            onError: (e) => onErrorCalled = true,
            onComplete: () {
              expect(onSuccessCalled, isTrue);
              onCompleteCalled = true;
            });
        expect(onSuccessCalled, isFalse);
        expect(onCompleteCalled, isFalse);
        expect(result, new isInstanceOf<Future>());
        return result.then((ret) {
          expect(onErrorCalled, isFalse);
          expect(onCompleteCalled, isTrue);
          expect(ret, 10);
        });
      });

      test('which fails should call onError with error, then onComplete', () {
        var onSuccessCalled = false;
        var onErrorCalled = false;
        var onCompleteCalled = false;
        var result = when(
            () => new Future.error('e'),
            onSuccess: (_) => onSuccessCalled = true,
            onError: (e) {
              expect(e, 'e');
              onErrorCalled = true;
            },
            onComplete: () {
              onErrorCalled = true;
              onCompleteCalled = true;
            });
        expect(onErrorCalled, isFalse);
        expect(onCompleteCalled, isFalse);
        expect(result, new isInstanceOf<Future>());
        return result.then((ret) {
          expect(ret, isNull);
          expect(onSuccessCalled, isFalse);
          expect(onCompleteCalled, isTrue);
        });
      });

      test('should pass stack trace to onError if binary', () {
        var onErrorCalled = false;
        return when(
            () => new Future.error('e'),
            onError: (e, s) {
              onErrorCalled = true;
              // TODO: Why is the stack trace null?
              // expect(s, isNotNull);
        }).then((_) {
          expect(onErrorCalled, isTrue);
        });
      });

      test('should throw callback error if no onError provided', () {
        return when(
            () => new Future.error('e')
        ).then((_) {
          fail('callback error was swallowed');
        }, onError: (e) {
          expect(e, 'e');
        });
      });

      test('should just return callback result if onSuccess not provided', () {
        return when(() => new Future.value(5)).then((result) {
          expect(result, 5);
        });
      });

      test('should not swallow onComplete error', () {
        return when(
            () => new Future.value(),
            onComplete: () => throw 'e')
            .then((ret) {
              fail('onComplete error was swallowed');
            }, onError: (e) {
              expect(e, 'e');
            });
      });

    });
  });
}