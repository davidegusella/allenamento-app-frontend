import 'package:allenamentofrontend/models/workout.dart';
import 'package:flutter_test/flutter_test.dart';

/// La data di creazione inviata dal backend (Instant di Java, in UTC)
/// si legge correttamente e si mostra come "gg/mm/aaaa"
void main() {
  test('Plan reads createdAt from the backend and shows the date', () {
    final plan = Plan.fromJson({
      'id': 1,
      'name': 'Forza',
      'createdAt': '2026-10-17T10:15:30.123456789Z',
      'days': [],
    });

    final atteso = DateTime.utc(2026, 10, 17, 10, 15, 30).toLocal();
    expect(plan.createdAt.year, atteso.year);
    expect(plan.createdAt.month, atteso.month);
    expect(plan.createdAt.day, atteso.day);
    expect(plan.data, endsWith('/10/2026'));
  });
}
