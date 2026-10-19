import 'package:flutter_test/flutter_test.dart';
import 'package:lexiec/core/utils/request_id.dart';

void main() {
  test('genera UUID v4 válidos y distintos', () {
    final pattern = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );
    final ids = {for (var i = 0; i < 200; i++) newRequestId()};
    expect(ids.length, 200);
    expect(ids.every(pattern.hasMatch), isTrue);
  });
}
