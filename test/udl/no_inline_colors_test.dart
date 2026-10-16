import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Widgets migrated onto the token layer. Add to this list from each phase-2b
/// plan as files move across.
const List<String> migratedFiles = [
  'lib/widgets/common/poster_skeleton.dart',
  'lib/widgets/common/error_view.dart',
  'lib/widgets/common/section_header.dart',
  'lib/widgets/common/page_top_bar.dart',
  'lib/widgets/common/modern_toast.dart',
];

/// Matches a `Color(0x…)` literal or a `Colors.<name>` reference, without
/// flagging an identifier that merely ends in those words.
final RegExp _inlineColor = RegExp(
  r'(?<![A-Za-z0-9_])(?:Color\(\s*0x|Colors\.(?!transparent))',
);

void main() {
  test('the guard pattern actually catches literals', () {
    expect(_inlineColor.hasMatch('color: const Color(0xFF171A23),'), isTrue);
    expect(
      _inlineColor.hasMatch('border: Border.all(color: Colors.white),'),
      isTrue,
    );
    expect(_inlineColor.hasMatch('final t = PlayTorrioTokens.of(context);'), isFalse);
    expect(_inlineColor.hasMatch('borderRadius: BorderRadius.circular(18),'), isFalse);
    // `Colors.transparent` is a structural value, not a palette colour.
    expect(_inlineColor.hasMatch('color: Colors.transparent,'), isFalse);
  });

  test('migrated widgets contain no inline colour literals', () {
    final offenders = <String>[];

    for (final path in migratedFiles) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: '$path should exist');

      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (_inlineColor.hasMatch(lines[i])) {
          offenders.add('$path:${i + 1}: ${lines[i].trim()}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Use PlayTorrioTokens/AppSemanticColors instead:\n${offenders.join('\n')}',
    );
  });
}
