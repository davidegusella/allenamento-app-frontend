import 'package:allenamentofrontend/models/workout.dart';
import 'package:allenamentofrontend/pages/day_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dati_di_prova.dart';
import 'server_di_prova.dart';

/// La pagina della giornata mostra ogni esercizio con nome, serie e ripetizioni,
/// i pulsanti per spostarlo, modificarlo ed eliminarlo e il pulsante "Aggiungi esercizio" in fondo all'elenco
void main() {
  testWidgets('Day page lists exercises with sets and reps preview', (tester) async {
    telefonoPiccolo(tester);

    final store = storeDiProva({}, []);
    store.impostaPerTest(
        plans: Plan.listaDaJson([
      schedaDiProva(1, 'Forza', [
        [esercizioDiProva(1, 'Squat', serie: 4, min: 6, max: 8), esercizioDiProva(2, 'Panca', min: 10, max: 10)],
      ]),
    ]));

    await tester.pumpWidget(
      appDiProva(store, const DayPage(planId: 1, dayId: 10)),
    );

    expect(find.text('Forza: Giorno 1'), findsOneWidget);
    expect(find.text('Squat'), findsOneWidget);
    expect(find.text('4 serie × 6–8 ripetizioni'), findsOneWidget);
    expect(find.text('3 serie × 10 ripetizioni'), findsOneWidget);
    expect(find.textContaining('Nota tecnica'), findsNothing);

    // Il primo esercizio non può salire, l'ultimo non può scendere
    final su = tester.widgetList<IconButton>(find.widgetWithIcon(IconButton, Icons.arrow_upward)).toList();
    final giu = tester.widgetList<IconButton>(find.widgetWithIcon(IconButton, Icons.arrow_downward)).toList();
    expect(su[0].onPressed, isNull);
    expect(su[1].onPressed, isNotNull);
    expect(giu[0].onPressed, isNotNull);
    expect(giu[1].onPressed, isNull);
    expect(find.byTooltip('Modifica esercizio'), findsNWidgets(2));
    expect(find.byTooltip('Elimina esercizio'), findsNWidgets(2));

    // Niente più pulsante di avvio dell'allenamento; in fondo c'è "Aggiungi esercizio", come per le giornate
    expect(find.text('Apri allenamento di oggi'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'Aggiungi esercizio'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);

    // Toccando la riga si apre la pagina dell'esercizio (senza "Aggiungi serie")
    await tester.tap(find.text('Squat'));
    await tester.pumpAndSettle();
    expect(find.text('Serie 4'), findsOneWidget);
    expect(find.text('Aggiungi serie'), findsNothing);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Con la matita si apre la pagina di modifica (con "Aggiungi serie")
    await tester.tap(find.byTooltip('Modifica esercizio').first);
    await tester.pumpAndSettle();
    expect(find.text('Aggiungi serie'), findsOneWidget);
  });
}
