import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Design §13 is only real if it is enforced. This scans the primitive library
/// itself and fails on any hardcoded colour, so the token layer stays the only
/// place a colour can be written down.
///
/// `Colors.transparent` is exempt: it carries no hue, it is only an alpha
/// channel (the sheet's modal barrier background).
void main() {
  test('no inline color literals in lib/widgets/ui', () {
    final dir = Directory('lib/widgets/ui');
    expect(
      dir.existsSync(),
      isTrue,
      reason: 'the primitive library should exist at lib/widgets/ui',
    );

    final patterns = <RegExp>[
      RegExp(r'Color\(0x'),
      // A word boundary before `Colors` keeps the identifier
      // `AppSemanticColors.` (which legally ends the same way) out of the
      // match; only the `Colors` class itself is banned.
      RegExp(r'(?<![A-Za-z0-9_])Colors\.(?!transparent)'),
    ];

    final offenders = <String>[];
    for (final file in dir.listSync().whereType<File>().where(
      (f) => f.path.endsWith('.dart'),
    )) {
      final source = file.readAsStringSync();
      for (final pattern in patterns) {
        if (pattern.hasMatch(source)) {
          offenders.add('${file.path}: ${pattern.pattern}');
        }
      }
    }

    expect(offenders, isEmpty, reason: 'Use PlayTorrioTokens or AppSemanticColors');
  });
}
