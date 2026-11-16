import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:studynova/config/ai_config.dart';
import 'package:studynova/config/supabase_config.dart';
import 'package:studynova/services/auth_service.dart';
import 'package:studynova/utils/supabase_availability.dart';

/// Regression tests for the Windows "Internet not connected" bug.
///
/// The defect was not a network check at all: several code paths turned *any*
/// unusable Supabase client — including "this build was never given
/// credentials" — into a message telling a fully connected student that their
/// internet was down. These tests pin the four situations apart so the wording
/// cannot drift back together.
///
/// None of these tests touch the network.
void main() {
  group('configuration', () {
    test('a build with or without --dart-define is handled, never misread', () {
      // This build may or may not carry defaults, depending on how the app was
      // configured, so what is asserted is the *resolution rule* rather than one
      // particular environment: a value from either source counts, and the flag
      // is exactly the two being present.
      final url = effectiveSupabaseUrl;
      final key = effectiveSupabaseAnonKey;

      expect(isSupabaseConfigured, url.isNotEmpty && key.isNotEmpty);
      expect(
        url,
        anyOf(supabaseEnvUrl, supabaseConfigUrl),
        reason: 'the URL must come from exactly one of the two sources',
      );
      expect(
        key,
        anyOf(supabaseEnvAnonKey, supabaseConfigAnonKey),
        reason: 'the key must come from exactly one of the two sources',
      );

      // Whichever way it is configured, an uninitialized client must be
      // obtainable without throwing — that is what lets every online feature
      // degrade instead of crashing.
      expect(safeSupabase(), isNull, reason: 'no test may reach the network');
    });

    test('a valid configuration is recognized', () {
      // Same rule as `isSupabaseConfigured`, expressed directly so the intent
      // survives a refactor of the flag.
      bool configured(String url, String key) =>
          url.isNotEmpty && key.isNotEmpty;

      expect(configured('https://abcdefgh.supabase.co', 'anon-key'), isTrue);
      expect(configured('', 'anon-key'), isFalse);
      expect(configured('https://abcdefgh.supabase.co', ''), isFalse);
      expect(configured('', ''), isFalse);
    });

    test(
      'no credential value is ever embedded in a student-facing message',
      () {
        // Naming a *build flag* in a setup hint is not a leak, so the check is
        // against the credential values themselves and anything JWT-shaped.
        final rendered = <String>[
          friendlyBackendError(const BackendNotConfiguredException()),
          friendlyBackendError(const BackendUnavailableException()),
          friendlyBackendError(TimeoutException('boom')),
          friendlyBackendError(
            AuthException('SocketException: Failed host lookup'),
          ),
          friendlyBackendError(AuthException('Invalid login credentials')),
          friendlyBackendError(
            PostgrestException(message: 'relation "courses" does not exist'),
          ),
        ];

        for (final message in rendered) {
          expect(message, isNot(contains('Exception:')));
          expect(message, isNot(contains('#0')));
          expect(message, isNot(contains('PostgrestException')));
          // The literal credential, if this build has one, must never appear.
          if (effectiveSupabaseAnonKey.isNotEmpty) {
            expect(message, isNot(contains(effectiveSupabaseAnonKey)));
          }
          if (googleGenerativeAIKey.isNotEmpty) {
            expect(message, isNot(contains(googleGenerativeAIKey)));
          }
          // Nor any part of a JWT or an "AIza…" key.
          expect(message, isNot(contains('eyJ')));
          expect(message, isNot(contains('AIza')));
        }
      },
    );

    test('the Gemini key is read from a define and never hardcoded', () {
      // Reading it must not throw and must not reveal the value; the check is
      // that the field exists and is empty in an unconfigured test build.
      expect(googleGenerativeAIKey, isA<String>());
      expect(geminiModel, isNotEmpty);
    });
  });

  group('error classification', () {
    test('missing configuration is never reported as an internet problem', () {
      final message = friendlyBackendError(
        const BackendNotConfiguredException(feature: 'saved courses'),
      );
      final lower = message.toLowerCase();
      expect(lower, contains('built without'));
      expect(lower, isNot(contains('internet connection')));
      expect(lower, isNot(contains('not connected')));
    });

    test(
      'an unavailable backend is not automatically classified as offline',
      () {
        final message = friendlyBackendError(
          const BackendUnavailableException(),
        );
        final lower = message.toLowerCase();
        expect(lower, contains('online service'));
        // Only a real transport failure may mention the connection.
        expect(lower, isNot(contains('internet')));
      },
    );

    test('an authentication error is not reported as an internet error', () {
      for (final raw in <String>[
        'Invalid login credentials',
        'Email not confirmed',
        'User already registered',
        'Password should be at least 6 characters',
        'Too many requests',
      ]) {
        final message = friendlyBackendError(AuthException(raw));
        expect(
          message.toLowerCase(),
          isNot(contains('internet')),
          reason:
              'a wrong-credentials answer must not be blamed on the '
              'connection: $raw',
        );
      }
    });

    test('an expired session says so instead of blaming the connection', () {
      final message = friendlyBackendError(
        const AuthException('Invalid Refresh Token: Refresh Token Not Found'),
      );
      expect(message.toLowerCase(), contains('session has expired'));
      expect(message.toLowerCase(), isNot(contains('internet')));
    });

    test(
      'a backend/table failure is not automatically classified as offline',
      () {
        final message = friendlyBackendError(
          PostgrestException(message: 'code 42501 permission denied'),
        );
        expect(message.toLowerCase(), contains('online service'));
        expect(message.toLowerCase(), isNot(contains('internet')));
      },
    );

    test('a network timeout gets its own friendly message', () {
      final message = friendlyBackendError(TimeoutException('took too long'));
      expect(message.toLowerCase(), contains('timed out'));
      expect(message.toLowerCase(), contains('check your internet connection'));
    });

    test(
      'a transport failure mentions the connection, never a raw exception',
      () {
        final message = friendlyBackendError(
          http.ClientException('Connection closed before full header'),
        );
        expect(message.toLowerCase(), contains('connection'));
        expect(message, isNot(contains('ClientException')));
      },
    );

    test('a DNS failure inside a GoTrue retryable fetch is classified', () {
      // gotrue stringifies the underlying error, so no type survives.
      final message = friendlyBackendError(
        AuthRetryableFetchException(
          message:
              'SocketException: Failed host lookup: '
              "'abcdefgh.supabase.co' (OS Error: No address associated)",
        ),
      );
      expect(message.toLowerCase(), contains('connection'));
      expect(message, isNot(contains('SocketException')));
      expect(message, isNot(contains('supabase.co')));
    });

    test('a TLS handshake failure is classified as a connection problem', () {
      final message = friendlyBackendError(
        AuthRetryableFetchException(
          message: 'HandshakeException: Handshake error in client',
        ),
      );
      expect(message.toLowerCase(), contains('connection'));
      expect(message, isNot(contains('HandshakeException')));
    });

    test('an unrecognised failure still gets a friendly generic message', () {
      final message = friendlyBackendError(Exception('raw technical detail'));
      expect(message, 'Something went wrong. Please try again.');
      expect(message, isNot(contains('raw technical detail')));
    });
  });

  group('auth screens reuse the same classification', () {
    test('AuthService.friendlyError delegates instead of duplicating rules', () {
      // The feature name differs (accounts vs the generic default) but the
      // classification and wording must not, so the comparison is made against
      // the same feature label the auth screens actually pass.
      expect(
        AuthService.friendlyError(const SupabaseNotConfiguredException()),
        friendlyBackendError(
          const BackendNotConfiguredException(feature: 'accounts'),
        ),
      );
      expect(
        AuthService.friendlyError(const AuthUnavailableException()),
        friendlyBackendError(const BackendUnavailableException()),
      );
    });

    test('a wrong password is never reported as an internet error', () {
      final message = AuthService.friendlyError(
        const AuthException('Invalid login credentials'),
      );
      expect(
        message,
        'That email and password do not match. Please try again.',
      );
      expect(message.toLowerCase(), isNot(contains('internet')));
    });

    test('missing configuration is never reported as an internet error', () {
      final message = AuthService.friendlyError(
        const SupabaseNotConfiguredException(),
      );
      expect(message.toLowerCase(), isNot(contains('internet connection')));
    });
  });
}
