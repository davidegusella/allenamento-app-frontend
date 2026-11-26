import 'package:allenamentofrontend/models/workout.dart';
import 'package:allenamentofrontend/pages/home_page.dart';
import 'package:allenamentofrontend/providers/workout_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dati_di_prova.dart';
import 'server_di_prova.dart';

/// Su un telefono piccolo la barra in basso mostra le quattro voci senza errori di layout
/// e "Le mie" contiene Schede, Bacheca ed Esercizi.
/// Che le etichette stiano su una riga si vede solo sul telefono: nei test ogni lettera è larga come un quadrato
void main() {
  testWidgets('Bottom bar has four items and "Le mie" groups plans, bacheca and exercises', (tester) async {
    telefonoPiccolo(tester);

    await tester.pumpWidget(appDiProva(WorkoutStore(), const HomePage()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(find.byType(NavigationDestination), findsNWidgets(4));
    for (final voce in ['Le mie', 'Per te', 'Classifica', 'Messaggi']) {
      expect(find.text(voce), findsOneWidget);
    }
    expect(find.byType(Tab), findsNWidgets(3));
    expect(find.text('La tua prima scheda'), findsOneWidget);

    await tester.tap(find.text('Esercizi'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Nessun esercizio'), findsOneWidget);

    await tester.tap(find.text('Bacheca'));
    await tester.pumpAndSettle();
    expect(find.text('Le statistiche delle tue schede pubblicate'), findsOneWidget);
  });

  testWidgets('The bottom bar stays visible on the pages opened from a tab', (tester) async {
    final store = storeDiProva({}, []);
    store.impostaPerTest(
        plans: Plan.listaDaJson([
      schedaDiProva(1, 'Forza', [[]]),
    ]));

    await tester.pumpWidget(appDiProva(store, const HomePage()));

    // Scheda e giornata si aprono sopra la barra in basso
    await tester.tap(find.text('Forza'));
    await tester.pumpAndSettle();
    expect(find.text('Aggiungi giornata'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.tap(find.text('Giorno 1'));
    await tester.pumpAndSettle();
    expect(find.text('Aggiungi esercizio'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    // Indietro torna alla scheda, toccando "Le mie" si torna all'elenco
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Aggiungi giornata'), findsOneWidget);
    await tester.tap(find.text('Le mie'));
    await tester.pumpAndSettle();
    expect(find.text('Nuova scheda'), findsOneWidget);
  });
}
