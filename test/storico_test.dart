import 'package:allenamentofrontend/models/workout.dart';
import 'package:allenamentofrontend/pages/esercizio_page.dart';
import 'package:allenamentofrontend/pages/storico_esercizio_page.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dati_di_prova.dart';
import 'server_di_prova.dart';

Map<String, dynamic> sessione(String data, List<List<num>> serie) {
  return {
    'date': data,
    'sets': [
      for (final s in serie) {'reps': s[0], 'weight': s[1]}
    ],
  };
}

void main() {
  final panca = Exercise.fromJson(esercizioDiProva(7, 'Panca', serie: 2, weightMode: 'PER_SIDE'));

  testWidgets('The history shows the chart and the sessions, newest first', (tester) async {
    telefonoPiccolo(tester);
    final richieste = <Map<String, dynamic>>[];
    final store = storeDiProva({
      'GET /api/exercises/7/history': [
        sessione('2026-11-25', [
          [8, 22.5],
          [6, 25]
        ]),
        sessione('2026-11-18', [
          [8, 20]
        ]),
      ],
    }, richieste);

    await tester.pumpWidget(appDiProva(store, EsercizioPage(exercise: panca)));
    await tester.tap(find.byTooltip('Storico'));
    await tester.pumpAndSettle();

    expect(richieste.single['chiave'], 'GET /api/exercises/7/history');
    expect(find.byType(LineChart), findsOneWidget);
    expect(find.text('Kg più alti di ogni giorno'), findsOneWidget);
    expect(find.text('Serie 1: 8 × 22,5 kg per lato'), findsOneWidget);
    expect(find.text('Serie 2: 6 × 25 kg per lato'), findsOneWidget);
    expect(tester.getTopLeft(find.text('25/11/2026').last).dy,
        lessThan(tester.getTopLeft(find.text('18/11/2026').last).dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Without sessions the history explains how to create one, without chart', (tester) async {
    final store = storeDiProva({'GET /api/exercises/7/history': []}, []);

    await tester.pumpWidget(appDiProva(store, StoricoEsercizioPage(exercise: panca)));
    await tester.pumpAndSettle();

    expect(find.text('Nessuna sessione'), findsOneWidget);
    expect(find.byType(LineChart), findsNothing);
  });

  test('The chart value of a session is its heaviest set', () {
    final giorno = Sessione.fromJson(sessione('2026-11-25', [
      [8, 20],
      [6, 27.5],
      [4, 25]
    ]));
    expect(giorno.kgMassimo, 27.5);
    expect(giorno.data, '25/11/2026');
  });
}
