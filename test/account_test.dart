import 'package:allenamentofrontend/models/post.dart';
import 'package:allenamentofrontend/pages/account_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dati_di_prova.dart';
import 'server_di_prova.dart';

void main() {
  testWidgets('Username and email are saved and the posts are reloaded with the new name', (tester) async {
    telefonoPiccolo(tester);
    final richieste = <Map<String, dynamic>>[];
    final mioPost = postDiProva(9, 'davide.g', forza());
    final store = storeDiProva({
      'PUT /api/account': {'id': 1, 'username': 'davide.g', 'email': 'nuova@example.com'},
      'GET /api/posts/per-te': [],
      'GET /api/posts/mine?ordine=IMPORTATE': [mioPost],
      'GET /api/posts/mine?ordine=PIACIUTE': [mioPost],
      'GET /api/posts/classifica?ordine=IMPORTATE': [],
      'GET /api/posts/classifica?ordine=PIACIUTE': [mioPost],
    }, richieste);
    store.bacheca[OrdineClassifica.importate] = Post.listaDaJson([postDiProva(9, 'davide', forza())]);

    await tester.pumpWidget(appDiProva(store, const AccountPage()));
    expect(find.text('davide'), findsOneWidget);
    expect(find.text('davide@example.com'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Username'), 'davide.g');
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), ' nuova@example.com ');
    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();

    expect(richieste.first['chiave'], 'PUT /api/account');
    expect(richieste.first['body'], {'username': 'davide.g', 'email': 'nuova@example.com'});
    expect(store.utente!.username, 'davide.g');
    expect(store.eMio(store.bacheca[OrdineClassifica.importate]!.single), isTrue);
    expect(store.eMio(store.classifica[OrdineClassifica.piaciute]!.single), isTrue);
    expect(find.text('Account aggiornato'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('The new password must be written twice the same way', (tester) async {
    telefonoPiccolo(tester);
    final richieste = <Map<String, dynamic>>[];
    final store = storeDiProva({'PUT /api/account/password': null}, richieste);

    await tester.pumpWidget(appDiProva(store, const AccountPage()));
    await tester.enterText(find.widgetWithText(TextFormField, 'Nuova password'), 'nuova-password');
    await tester.enterText(find.widgetWithText(TextFormField, 'Ripeti la nuova password'), 'altra-password');
    await tester.tap(find.text('Cambia password'));
    await tester.pumpAndSettle();
    expect(find.text('Le password non coincidono'), findsOneWidget);
    expect(richieste, isEmpty);

    await tester.enterText(find.widgetWithText(TextFormField, 'Ripeti la nuova password'), 'nuova-password');
    await tester.tap(find.text('Cambia password'));
    await tester.pumpAndSettle();
    expect(richieste.single['chiave'], 'PUT /api/account/password');
    expect(richieste.single['body'], {'password': 'nuova-password'});
    expect(find.text('Password cambiata'), findsOneWidget);
  });

  testWidgets('Deleting the account asks for confirmation and signs out', (tester) async {
    telefonoPiccolo(tester);
    final richieste = <Map<String, dynamic>>[];
    final store = storeDiProva({'DELETE /api/account': null}, richieste);

    await tester.pumpWidget(appDiProva(store, const AccountPage()));
    await tester.ensureVisible(find.text('Elimina account'));
    await tester.tap(find.text('Elimina account'));
    await tester.pumpAndSettle();
    expect(find.text('Eliminare l\'account?'), findsOneWidget);
    expect(richieste, isEmpty);

    await tester.tap(find.text('Conferma'));
    await tester.pumpAndSettle();
    expect(richieste.single['chiave'], 'DELETE /api/account');
    expect(store.utente, isNull);
  });
}
