import 'package:allenamentofrontend/models/workout.dart';
import 'package:allenamentofrontend/pages/exercise_catalog_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dati_di_prova.dart';
import 'server_di_prova.dart';

/// "I miei esercizi" mostra in sola lettura gli esercizi delle schede.
/// Due esercizi sono lo stesso solo se hanno nome, carico, serie e ripetizioni uguali.
void main() {
  testWidgets('Same name, sets and reps is one exercise; different sets is another', (tester) async {
    final store = storeDiProva({}, []);
    store.impostaPerTest(
        plans: Plan.listaDaJson([
      schedaDiProva(1, 'Forza', [
        [esercizioDiProva(1, 'Squat'), esercizioDiProva(2, 'Panca')],
        [esercizioDiProva(3, 'squat'), esercizioDiProva(4, 'Squat', serie: 5)],
      ]),
    ]));

    await tester.pumpWidget(
      appDiProva(store, const Scaffold(body: ExerciseCatalogPage())),
    );

    // "Squat" e "squat" con 3 serie sono lo stesso esercizio; "Squat" con 5 serie è un altro
    expect(find.textContaining('3 serie × 8–10 ripetizioni'), findsNWidgets(2));
    expect(find.textContaining('5 serie × 8–10 ripetizioni'), findsOneWidget);
    expect(find.text('Panca'), findsOneWidget);
    // Ordine alfabetico: Panca prima di Squat
    expect(tester.getTopLeft(find.text('Panca')).dy, lessThan(tester.getTopLeft(find.text('Squat').first).dy));

    // Nessun comando per aggiungere, modificare o eliminare
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byIcon(Icons.delete_outline), findsNothing);
    expect(find.byIcon(Icons.edit_outlined), findsNothing);
  });
}
