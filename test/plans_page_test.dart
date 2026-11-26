import 'package:allenamentofrontend/models/workout.dart';
import 'package:allenamentofrontend/pages/plans_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dati_di_prova.dart';
import 'server_di_prova.dart';

/// Scheda con una giornata chiamata "Giorno 1 di [name]"
Map<String, dynamic> scheda(int id, String name, String createdAt) {
  return schedaDiProva(id, name, [[]], createdAt: createdAt)..['days'][0]['name'] = 'Giorno 1 di $name';
}

/// La pagina Schede mostra una riga per scheda, dalla più recente,
/// con matita e cestino; toccando una scheda si aprono le sue giornate
void main() {
  testWidgets('Plans are listed newest first and open their days', (tester) async {
    final store = storeDiProva({}, []);
    store.impostaPerTest(
        plans: Plan.listaDaJson([
      scheda(1, 'Vecchia', '2026-09-01T08:00:00Z'),
      scheda(2, 'Recente', '2026-10-17T08:00:00Z'),
    ]));

    await tester.pumpWidget(
      appDiProva(store, const Scaffold(body: PlansPage())),
    );

    // La scheda più recente è in alto
    expect(tester.getTopLeft(find.text('Recente')).dy, lessThan(tester.getTopLeft(find.text('Vecchia')).dy));
    // Ogni riga ha la matita e il cestino
    expect(find.byTooltip('Rinomina scheda'), findsNWidgets(2));
    expect(find.byTooltip('Elimina scheda'), findsNWidgets(2));
    // Le giornate non sono più nella pagina Schede
    expect(find.text('Giorno 1 di Recente'), findsNothing);

    await tester.tap(find.text('Recente'));
    await tester.pumpAndSettle();

    // Si apre la pagina della scheda con le sue giornate
    expect(find.text('Giorno 1 di Recente'), findsOneWidget);
    expect(find.text('Aggiungi giornata'), findsOneWidget);
    expect(find.byTooltip('Sposta su'), findsOneWidget);
  });
}
