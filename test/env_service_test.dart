import 'package:flutter_test/flutter_test.dart';

import 'package:playtorrio/services/config/env_service.dart';

void main() {
  group('EnvService', () {
    test('tmdbApiKey returns empty string when unconfigured', () {
      expect(EnvService.tmdbApiKey, '');
    });

    test('get returns the provided default for unknown keys', () {
      expect(EnvService.get('PLAYTORRIO_UNSET_TEST_KEY'), '');
      expect(
        EnvService.get('PLAYTORRIO_UNSET_TEST_KEY', defaultValue: 'fallback'),
        'fallback',
      );
    });
  });
}
