import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:studynova/services/ai_study_service.dart';
import 'package:studynova/services/study_photo_service.dart';

import 'support/study_photo_service_test_support.dart';

void main() {
  // ---------------------------------------------------------------------------
  // The function name and request contract
  // ---------------------------------------------------------------------------

  test('calls the deployed study-from-photo function by name', () {
    // Renaming this would silently point the app at a function that is not
    // deployed, so the name is asserted rather than trusted.
    expect(StudyPhotoService.functionName, 'study-from-photo');
  });

  test(
    'sends prompt, raw base64 and the MIME type, with no data: prefix',
    () async {
      // A real PNG signature, so the encoding is exercised against bytes that
      // actually begin the "iVBOR" prefix a data URL would contain.
      final bytes = Uint8List.fromList(<int>[
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
      ]);
      final probe = RecordingStudyPhotoService(
        queuedBodies: <Object?>[_onePart('the generated text')],
      );

      await probe.service.requestExplanation(
        prompt: 'Explain this.',
        imageBytes: bytes,
        mimeType: 'image/png',
      );

      final body = probe.lastBody!;
      expect(body['prompt'], 'Explain this.');
      expect(body['mimeType'], 'image/png');

      final base64 = body['imageBase64']! as String;
      // The function wants raw base64. A `data:image/png;base64,` prefix is the
      // single most common way this call gets rejected.
      expect(base64, isNot(contains('data:')));
      expect(base64, isNot(contains('base64,')));
      expect(base64, base64Encode(bytes));
      expect(base64.startsWith('iVBOR'), isTrue);
    },
  );

  test('omits the image entirely for a text-only request', () async {
    final probe = RecordingStudyPhotoService(
      queuedBodies: <Object?>[_onePart('Photosynthesis is...')],
    );

    await probe.service.requestExplanation(prompt: 'What is photosynthesis?');

    final body = probe.lastBody!;
    expect(body['prompt'], 'What is photosynthesis?');
    // The function treats a present-but-empty image differently from no image.
    expect(body.containsKey('imageBase64'), isFalse);
    expect(body.containsKey('mimeType'), isFalse);
  });

  test('defaults a missing or blank MIME type to image/jpeg', () async {
    for (final mime in <String?>[null, '', '   ']) {
      final probe = RecordingStudyPhotoService(
        queuedBodies: <Object?>[_onePart('ok')],
      );

      await probe.service.requestExplanation(
        prompt: 'p',
        imageBytes: Uint8List.fromList(<int>[1, 2, 3]),
        mimeType: mime,
      );

      expect(probe.lastBody!['mimeType'], 'image/jpeg', reason: 'mime=$mime');
    }
  });

  test('the photo never travels as a data URL', () async {
    final bytes = Uint8List.fromList(<int>[
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
    ]);
    final probe = RecordingStudyPhotoService(
      queuedBodies: <Object?>[_onePart('ok')],
    );

    await probe.service.requestExplanation(
      prompt: 'p',
      imageBytes: bytes,
      mimeType: 'image/png',
    );

    final body = probe.lastBody!;
    expect(body['imageBase64'], isA<String>());
    expect(body.toString(), isNot(contains('data:image')));
  });

  // ---------------------------------------------------------------------------
  // Reading the response envelope
  // ---------------------------------------------------------------------------

  test('extracts text from the documented Gemini envelope', () {
    final text = StudyPhotoService.parseResponseBody(
      jsonEncode(<String, dynamic>{
        'status': 200,
        'result': <String, dynamic>{
          'candidates': <dynamic>[
            <String, dynamic>{
              'content': <String, dynamic>{
                'parts': <dynamic>[
                  <String, dynamic>{'text': 'Photosynthesis makes food.'},
                ],
              },
            },
          ],
        },
      }),
    );
    expect(text, 'Photosynthesis makes food.');
  });

  test('joins every text part so a split answer is not truncated', () {
    final text = StudyPhotoService.parseResponseBody(<String, dynamic>{
      'status': 200,
      'result': <String, dynamic>{
        'candidates': <dynamic>[
          <String, dynamic>{
            'content': <String, dynamic>{
              'parts': <dynamic>[
                <String, dynamic>{'text': 'First part.'},
                <String, dynamic>{'text': 'Second part.'},
              ],
            },
          },
        ],
      },
    });
    expect(text, contains('First part.'));
    expect(text, contains('Second part.'));
  });

  test('rejects a malformed or empty response instead of crashing', () {
    // Every one of these is a malformed shape, not a student error.
    final bodies = <Object?>[
      <String, dynamic>{
        'status': 200,
        'result': <String, dynamic>{'candidates': <dynamic>[]},
      },
      <String, dynamic>{
        'status': 200,
        'result': <String, dynamic>{
          'candidates': <dynamic>[
            <String, dynamic>{
              'content': <String, dynamic>{'parts': <dynamic>[]},
            },
          ],
        },
      },
      <String, dynamic>{
        'status': 200,
        'result': <String, dynamic>{
          'candidates': <dynamic>[
            <String, dynamic>{
              'content': <String, dynamic>{
                'parts': <dynamic>[
                  <String, dynamic>{'text': '   '},
                ],
              },
            },
          ],
        },
      },
      <String, dynamic>{'status': 200},
      <String, dynamic>{'status': 200, 'result': 'not an object'},
      null,
      '',
      '<html>gateway timeout</html>',
      42,
    ];

    for (final body in bodies) {
      expect(
        () => StudyPhotoService.parseResponseBody(body),
        throwsA(
          isA<StudyPhotoException>().having(
            (e) => e.message,
            'message',
            isNotEmpty,
          ),
        ),
        reason: 'body $body should be reported as a failure',
      );
    }
  });

  test('no failure message leaks a status code or raw payload', () {
    for (final body in <Object?>[
      <String, dynamic>{'status': 503, 'result': <String, dynamic>{}},
      'not json',
      null,
    ]) {
      try {
        StudyPhotoService.parseResponseBody(body);
        fail('expected a StudyPhotoException');
      } on StudyPhotoException catch (e) {
        expect(e.message, isNot(contains('Exception')));
        expect(e.message, isNot(contains('{')));
        expect(e.message, isNot(contains('null')));
      }
    }
  });

  // ---------------------------------------------------------------------------
  // Error mapping
  // ---------------------------------------------------------------------------

  test('maps the upstream status carried inside an HTTP 200 body', () {
    // This is what the live function does on a Gemini capacity problem, and it
    // is the shape the retry logic has to recognise.
    expect(
      () => StudyPhotoService.parseResponseBody(<String, dynamic>{
        'status': 503,
        'result': <String, dynamic>{
          'error': <String, dynamic>{
            'code': 503,
            'status': 'UNAVAILABLE',
            'message': 'This model is currently experiencing high demand.',
          },
        },
      }),
      throwsA(
        isA<StudyPhotoException>()
            .having((e) => e.status, 'status', 503)
            .having((e) => e.message, 'message', contains('busy'))
            .having((e) => e.message, 'message', isNot(contains('503')))
            .having(
              (e) => e.message,
              'message',
              isNot(contains('UNAVAILABLE')),
            ),
      ),
    );
  });

  test('every HTTP status a function call can return gets a real message', () {
    // The brief requires 400, 401, 403, 404, 429 and 500 to be handled, plus the
    // fact that none of them may surface a raw status or provider payload.
    final messages = <String, String>{};

    for (final status in <int>[400, 401, 403, 404, 429, 500, 502, 503]) {
      final message = StudyPhotoService.friendlyMessageForStatus(
        status,
      ).message;
      expect(message, isNotEmpty, reason: 'status $status needs a message');
      expect(message, isNot(contains('$status')));
      expect(message, isNot(contains('Exception')));
      expect(message, isNot(contains('{')));
      messages['$status'] = message;
    }

    // A quota limit must not be reported as an outage: they need different
    // advice from the student.
    expect(messages['429'], isNot(messages['503']));
    // An expired session and a missing function need different advice too.
    expect(messages['401'], isNot(messages['404']));
    expect(messages['401'], contains('sign in'));
  });

  test('only capacity problems are retried', () {
    // 401/403 mean the session is the problem and 429 means "wait"; retrying any
    // of them would only make the student wait longer for the same error.
    expect(StudyPhotoService.isTransientStatus(401), isFalse);
    expect(StudyPhotoService.isTransientStatus(403), isFalse);
    expect(StudyPhotoService.isTransientStatus(404), isFalse);
    expect(StudyPhotoService.isTransientStatus(429), isFalse);
    expect(StudyPhotoService.isTransientStatus(400), isFalse);
    expect(StudyPhotoService.isTransientStatus(500), isTrue);
    expect(StudyPhotoService.isTransientStatus(503), isTrue);
    expect(StudyPhotoService.isTransientStatus(null), isFalse);
  });

  // ---------------------------------------------------------------------------
  // Retry behaviour
  // ---------------------------------------------------------------------------

  test(
    'a transient capacity failure is retried and can then succeed',
    () async {
      final probe = RecordingStudyPhotoService(
        queuedBodies: <Object?>[
          <String, dynamic>{
            'status': 503,
            'result': <String, dynamic>{
              'error': <String, dynamic>{
                'status': 'UNAVAILABLE',
                'message': 'high demand',
              },
            },
          },
          _onePart('Recovered.'),
        ],
      );

      final text = await probe.service.requestExplanation(
        prompt: 'p',
        imageBytes: Uint8List.fromList(<int>[1]),
      );

      expect(text, 'Recovered.');
      expect(probe.calls, 2, reason: 'the 503 should have been retried once');
    },
  );

  test('repeated capacity failures stop at the attempt limit', () async {
    final probe = RecordingStudyPhotoService(
      queuedBodies: <Object?>[
        <String, dynamic>{
          'status': 503,
          'result': <String, dynamic>{'error': <String, dynamic>{}},
        },
      ],
    );

    await expectLater(
      probe.service.requestExplanation(
        prompt: 'p',
        imageBytes: Uint8List.fromList(<int>[1]),
      ),
      throwsA(
        isA<StudyPhotoException>().having(
          (e) => e.message,
          'message',
          contains('busy'),
        ),
      ),
    );
    // Bounded, so a real outage cannot leave the student waiting forever.
    expect(probe.calls, StudyPhotoService.maxAttempts);
  });

  test(
    'a permanent failure is reported immediately without retrying',
    () async {
      for (final status in <int>[401, 403, 404, 429]) {
        final probe = RecordingStudyPhotoService(httpStatus: status);

        await expectLater(
          probe.service.requestExplanation(
            prompt: 'p',
            imageBytes: Uint8List.fromList(<int>[1]),
          ),
          throwsA(
            isA<StudyPhotoException>().having(
              (e) => e.message,
              'message',
              isNotEmpty,
            ),
          ),
          reason: 'status $status',
        );
        expect(probe.calls, 1, reason: 'status $status must not be retried');
      }
    },
  );

  // ---------------------------------------------------------------------------
  // The full path: service -> parsed analysis -> the shape the screens expect
  // ---------------------------------------------------------------------------

  test(
    'the analysis keeps the shape Study Explanation, Mind Map and Quiz read',
    () async {
      final probe = RecordingStudyPhotoService(
        queuedBodies: <Object?>[
          _onePart(
            jsonEncode(<String, dynamic>{
              'topic': 'Photosynthesis',
              'subject': 'Biology',
              'summary': 'How plants make food.',
              'explanation':
                  'Plants use sunlight to turn water and carbon dioxide into '
                  'glucose. This happens inside the chloroplast.',
              'important_concepts': <String>['chloroplast', 'glucose'],
              'key_definitions': <Map<String, String>>[
                <String, String>{
                  'term': 'Chloroplast',
                  'definition': 'The part of a leaf where it happens.',
                },
              ],
              'common_mistakes': <String>['Plants do not eat soil.'],
              'mind_map_structure': <String, dynamic>{
                'root': 'Photosynthesis',
                'branches': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'name': 'Inputs',
                    'children': <String>['sunlight'],
                  },
                ],
              },
            }),
          ),
        ],
      );

      final result = await AIStudyService(studyPhoto: probe.service)
          .analyzeImage(
            Uint8List.fromList(<int>[1, 2, 3]),
            fileName: 'notes.png',
            explanationLevel: 'normal',
          );

      // Every key the three downstream screens read must be present.
      for (final key in <String>[
        'topic',
        'subject',
        'summary',
        'explanation',
        'important_concepts',
        'common_mistakes',
        'key_points',
        'mind_map_data',
        'quiz_questions',
        'explanation_level',
      ]) {
        expect(result.containsKey(key), isTrue, reason: 'missing $key');
      }

      expect(result['topic'], 'Photosynthesis');
      expect(result['subject'], 'Biology');
      expect(result['explanation_level'], 'normal');
      expect(result['important_concepts'], <String>['chloroplast', 'glucose']);
      expect(result['quiz_questions'], isNotEmpty);

      final mindMap = result['mind_map_data']! as Map<String, dynamic>;
      expect(mindMap['root'], 'Photosynthesis');
      expect(mindMap['branches'], isNotEmpty);

      // The image really did reach the function.
      expect(probe.lastBody!['mimeType'], 'image/png');
    },
  );

  test('a prose answer still produces a usable explanation', () async {
    // Some models answer in prose instead of the requested JSON. The flow must
    // continue to the mind map and quiz instead of ending in an error.
    final probe = RecordingStudyPhotoService(
      queuedBodies: <Object?>[
        _onePart(
          '## Photosynthesis\n\n'
          'Plants make their own food using sunlight. '
          'This happens inside the chloroplast of the leaf. '
          'The glucose produced is used for energy and growth.',
        ),
      ],
    );

    final result = await AIStudyService(
      studyPhoto: probe.service,
    ).analyzeImage(Uint8List.fromList(<int>[1]));

    expect(result['topic'], 'Photosynthesis');
    expect(
      result['explanation'],
      contains('chloroplast'),
      reason: 'the whole answer should be kept as the explanation',
    );
    expect(result['mind_map_data'], isA<Map<String, dynamic>>());
    expect(result['quiz_questions'], isNotEmpty);
  });

  test('an unusable answer produces a friendly message, not a crash', () async {
    final probe = RecordingStudyPhotoService(
      queuedBodies: <Object?>[
        <String, dynamic>{
          'status': 200,
          'result': <String, dynamic>{
            'candidates': <dynamic>[
              <String, dynamic>{
                'content': <String, dynamic>{'parts': <dynamic>[]},
              },
            ],
          },
        },
      ],
    );

    await expectLater(
      AIStudyService(
        studyPhoto: probe.service,
      ).analyzeImage(Uint8List.fromList(<int>[1])),
      throwsA(
        isA<Exception>()
            // `Exception.toString()` always adds the Dart type prefix; what
            // matters is the sentence the screen shows, which is the argument.
            .having(
              (e) => e.toString(),
              'message',
              contains('Please try again'),
            )
            .having(
              (e) => e.toString(),
              'message',
              isNot(contains('StudyPhotoException')),
            )
            .having((e) => e.toString(), 'message', isNot(contains('{'))),
      ),
    );
  });

  test('an empty image is refused before any request is made', () async {
    final probe = RecordingStudyPhotoService(
      queuedBodies: <Object?>[_onePart('should never be read')],
    );

    await expectLater(
      AIStudyService(studyPhoto: probe.service).analyzeImage(Uint8List(0)),
      throwsA(isA<Exception>()),
    );
    expect(probe.calls, 0, reason: 'no image means no request');
  });

  // ---------------------------------------------------------------------------
  // The follow-up question reuses the same endpoint, without an image
  // ---------------------------------------------------------------------------

  test(
    'the follow-up question sends text only and returns the answer',
    () async {
      final probe = RecordingStudyPhotoService(
        queuedBodies: <Object?>[
          _onePart('Leaves are the main site of photosynthesis.'),
        ],
      );

      final answer = await AIStudyService(studyPhoto: probe.service)
          .askFollowUpQuestion(
            topic: 'Photosynthesis',
            explanation: 'Plants use sunlight to make food.',
            question: 'Where does it happen?',
          );

      expect(answer, 'Leaves are the main site of photosynthesis.');
      expect(probe.lastBody!.containsKey('imageBase64'), isFalse);
      expect(probe.lastBody!['prompt'], contains('Where does it happen?'));
      expect(probe.lastBody!['prompt'], contains('Photosynthesis'));
    },
  );

  test('an empty follow-up question is refused before any request', () async {
    final probe = RecordingStudyPhotoService(
      queuedBodies: <Object?>[_onePart('unused')],
    );

    await expectLater(
      AIStudyService(studyPhoto: probe.service).askFollowUpQuestion(
        topic: 'Photosynthesis',
        explanation: 'text',
        question: '   ',
      ),
      throwsA(isA<Exception>()),
    );
    expect(probe.calls, 0);
  });
}

/// Builds the full success envelope the Edge Function returns around `text`.
///
/// The function wraps the Gemini body in `{"status":200,"result":{...}}`, so
/// the helper does too — returning only the inner `result` would not be a shape
/// the app ever receives.
Map<String, dynamic> _onePart(String text) {
  return <String, dynamic>{
    'status': 200,
    'result': <String, dynamic>{
      'candidates': <dynamic>[
        <String, dynamic>{
          'content': <String, dynamic>{
            'parts': <dynamic>[
              <String, dynamic>{'text': text},
            ],
          },
        },
      ],
    },
  };
}
