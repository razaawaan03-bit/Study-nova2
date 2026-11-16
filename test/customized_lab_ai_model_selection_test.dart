import 'package:flutter_test/flutter_test.dart';
import 'package:studynova/services/custom_lab_ai_service.dart';

Future<T> _runWithFallback<T>({
  required List<String> orderedModels,
  required Future<T> Function(String model, int attemptNumber) runModel,
  required int maxTotalAttempts,
}) async {
  var attemptsUsed = 0;
  Object? lastError;

  for (var index = 0; index < orderedModels.length; index++) {
    final model = orderedModels[index];
    final remainingAttempts = maxTotalAttempts - attemptsUsed;
    if (remainingAttempts <= 0) break;

    final maxAttemptsForModel = index == 0 ? 1 : 1;
    final attemptsAllowed = maxAttemptsForModel.clamp(0, remainingAttempts);

    for (var attempt = 0; attempt < attemptsAllowed; attempt++) {
      attemptsUsed += 1;
      try {
        return await runModel(model, attemptsUsed);
      } catch (error) {
        lastError = error;
        final statusCode = (error is CustomLabAiException)
            ? error.statusCode
            : null;

        if (!CustomLabAiService.shouldUseFallbackForGeminiError(
          statusCode: statusCode,
        )) {
          rethrow;
        }

        if (index < orderedModels.length - 1) {
          continue;
        }
      }
    }

    if (index < orderedModels.length - 1) {
      continue;
    }
  }

  if (lastError != null) {
    throw lastError;
  }

  throw StateError('No Gemini model succeeded.');
}

Future<T> _runWithOverallDeadline<T>({
  required List<String> orderedModels,
  required Future<T> Function(String model, int attemptNumber) runModel,
  required int overallDeadlineMs,
}) async {
  final deadline = DateTime.now().millisecondsSinceEpoch + overallDeadlineMs;
  var attemptsUsed = 0;
  Object? lastError;

  for (var index = 0; index < orderedModels.length; index++) {
    final model = orderedModels[index];

    while (DateTime.now().millisecondsSinceEpoch < deadline) {
      attemptsUsed += 1;
      try {
        return await runModel(model, attemptsUsed);
      } catch (error) {
        lastError = error;
        final statusCode = (error is CustomLabAiException)
            ? error.statusCode
            : null;
        if (!CustomLabAiService.shouldUseFallbackForGeminiError(
          statusCode: statusCode,
        )) {
          rethrow;
        }
        if (index < orderedModels.length - 1) {
          continue;
        }
        break;
      }
    }
  }

  if (lastError != null) {
    throw lastError;
  }

  throw const CustomLabAiException(
    'AI service is temporarily busy. Please try again in a minute.',
    statusCode: 503,
  );
}

void main() {
  group('CustomLabAiService Gemini model selection', () {
    test('accepts the verified primary and fallback Flash models', () {
      final ordered = CustomLabAiService.resolveGeminiModels(
        primaryModel: 'gemini-3.8-flash',
        fallbackModel: 'gemini-3.5-flash-lite',
      );

      expect(ordered, <String>['gemini-3.8-flash', 'gemini-3.5-flash-lite']);
      expect(
        CustomLabAiService.normalizeModelName(
          'gemini-3.8-flash',
          fallback: 'gemini-3.8-flash',
        ),
        'gemini-3.8-flash',
      );
      expect(
        CustomLabAiService.normalizeModelName(
          'gemini-3.8-flash',
          fallback: 'gemini-3.5-flash-lite',
        ),
        'gemini-3.8-flash',
      );
      expect(
        CustomLabAiService.normalizeModelName(
          'gemini-2.5-flash',
          fallback: 'gemini-3.8-flash',
        ),
        'gemini-3.8-flash',
      );
      expect(
        CustomLabAiService.shouldUseFallbackForGeminiError(statusCode: 503),
        isTrue,
      );
      expect(
        CustomLabAiService.shouldUseFallbackForGeminiError(statusCode: 400),
        isFalse,
      );
    });

    test('primary success resolves without a fallback', () async {
      final ordered = CustomLabAiService.resolveGeminiModels(
        primaryModel: 'gemini-3.8-flash',
        fallbackModel: 'gemini-3.5-flash-lite',
      );

      final result = await _runWithFallback<String>(
        orderedModels: ordered,
        maxTotalAttempts: 3,
        runModel: (model, attemptNumber) async {
          expect(model, 'gemini-3.8-flash');
          expect(attemptNumber, 1);
          return 'primary-success';
        },
      );

      expect(result, 'primary-success');
    });

    test('primary timeout triggers fallback and succeeds', () async {
      final ordered = CustomLabAiService.resolveGeminiModels(
        primaryModel: 'gemini-3.8-flash',
        fallbackModel: 'gemini-3.5-flash-lite',
      );
      var attempts = 0;

      final result = await _runWithFallback<String>(
        orderedModels: ordered,
        maxTotalAttempts: 3,
        runModel: (model, attemptNumber) async {
          attempts += 1;
          if (model == 'gemini-3.8-flash') {
            throw const CustomLabAiException(
              'AI service is temporarily busy. Please try again in a minute.',
              statusCode: 503,
            );
          }
          expect(model, 'gemini-3.5-flash-lite');
          expect(attemptNumber, 2);
          return 'fallback-success';
        },
      );

      expect(result, 'fallback-success');
      expect(attempts, 2);
    });

    test('primary 503 triggers fallback and succeeds', () async {
      final ordered = CustomLabAiService.resolveGeminiModels(
        primaryModel: 'gemini-3.8-flash',
        fallbackModel: 'gemini-3.5-flash-lite',
      );
      var attempts = 0;

      final result = await _runWithFallback<String>(
        orderedModels: ordered,
        maxTotalAttempts: 3,
        runModel: (model, attemptNumber) async {
          attempts += 1;
          if (model == 'gemini-3.8-flash') {
            throw const CustomLabAiException(
              'AI service is temporarily busy. Please try again in a minute.',
              statusCode: 503,
            );
          }
          expect(model, 'gemini-3.5-flash-lite');
          expect(attemptNumber, 2);
          return 'fallback-success';
        },
      );

      expect(result, 'fallback-success');
      expect(attempts, 2);
    });

    test('both models unavailable fail after 3 attempts max', () async {
      final ordered = CustomLabAiService.resolveGeminiModels(
        primaryModel: 'gemini-3.8-flash',
        fallbackModel: 'gemini-3.5-flash-lite',
      );
      var attempts = 0;

      await expectLater(
        () => _runWithFallback<String>(
          orderedModels: ordered,
          maxTotalAttempts: 3,
          runModel: (model, attemptNumber) async {
            attempts += 1;
            throw const CustomLabAiException(
              'AI service is temporarily busy. Please try again in a minute.',
              statusCode: 503,
            );
          },
        ),
        throwsA(isA<CustomLabAiException>()),
      );

      expect(attempts, 2);
    });

    test('overall deadline stops further attempts', () async {
      final ordered = CustomLabAiService.resolveGeminiModels(
        primaryModel: 'gemini-3.8-flash',
        fallbackModel: 'gemini-3.5-flash-lite',
      );
      var attempts = 0;

      await expectLater(
        () => _runWithOverallDeadline<String>(
          orderedModels: ordered,
          overallDeadlineMs: 0,
          runModel: (model, attemptNumber) async {
            attempts += 1;
            if (attempts == 1) {
              throw const CustomLabAiException(
                'AI service is temporarily busy. Please try again in a minute.',
                statusCode: 503,
              );
            }
            return 'should-not-happen';
          },
        ),
        throwsA(isA<CustomLabAiException>()),
      );

      expect(attempts, 0);
    });
  });
}
