import 'package:allenamentofrontend/pages/accesso_page.dart';
import 'package:allenamentofrontend/pages/recupero_password_page.dart';
import 'package:allenamentofrontend/providers/workout_store.dart';
import 'package:allenamentofrontend/services/archivio_token.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'server_di_prova.dart';

/// Pagina Accedi con uno store senza utente collegato e un server finto
Future<List<Map<String, dynamic>>> apriAccesso(WidgetTester tester) async {
  final richieste = <Map<String, dynamic>>[];
  final store = WorkoutStore(
    api: apiDiProva({'POST /api/auth/reset-password': jsonUtf8(null)}, richieste),
    archivio: ArchivioTokenInMemoria(),
  );
  await tester.pumpWidget(appDiProva(store, const AccessoPage()));
  return richieste;
}

void main() {
  testWidgets('Without an email the link shows the error and opens nothing', (tester) async {
    await apriAccesso(tester);

    await tester.tap(find.text('Password dimenticata?'));
    await tester.pumpAndSettle();

    expect(find.byType(RecuperoPasswordPage), findsNothing);
    expect(find.text('Inserisci l\'email'), findsOneWidget);
  });

  testWidgets('The new password is typed twice and sent with the login email', (tester) async {
    final richieste = await apriAccesso(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), '  davide@example.com ');
    await tester.tap(find.text('Password dimenticata?'));
    await tester.pumpAndSettle();

    expect(find.byType(RecuperoPasswordPage), findsOneWidget);
    expect(find.text('davide@example.com'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));

    await tester.enterText(find.widgetWithText(TextFormField, 'Nuova password'), 'nuova-password');
    await tester.enterText(find.widgetWithText(TextFormField, 'Ripeti la nuova password'), 'altra-password');
    await tester.tap(find.text('Cambia password'));
    await tester.pumpAndSettle();
    expect(find.text('Le password non coincidono'), findsOneWidget);
    expect(richieste, isEmpty);

    await tester.enterText(find.widgetWithText(TextFormField, 'Ripeti la nuova password'), 'nuova-password');
    await tester.tap(find.text('Cambia password'));
    await tester.pumpAndSettle();

    expect(richieste.single['chiave'], 'POST /api/auth/reset-password');
    expect(richieste.single['body'], {'email': 'davide@example.com', 'password': 'nuova-password'});
    expect(find.byType(RecuperoPasswordPage), findsNothing);
    expect(find.text('Password aggiornata: accedi con la nuova password'), findsOneWidget);
  });
}
