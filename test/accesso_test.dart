import 'package:allenamentofrontend/main.dart';
import 'package:allenamentofrontend/pages/accesso_page.dart';
import 'package:allenamentofrontend/pages/home_page.dart';
import 'package:allenamentofrontend/pages/registrazione_page.dart';
import 'package:allenamentofrontend/providers/workout_store.dart';
import 'package:allenamentofrontend/services/api_service.dart';
import 'package:allenamentofrontend/services/archivio_token.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'dati_di_prova.dart';
import 'server_di_prova.dart';

/// Risposta di accesso e registrazione, come la restituisce il backend
http.Response rispostaAccesso([int status = 200]) {
  return jsonUtf8({'token': 'token-nuovo', 'user': utenteDiProva()}, status);
}

http.Response accessoRichiesto() {
  return jsonUtf8({'message': 'Accesso richiesto.'}, 401);
}

/// Compila la pagina di registrazione e preme "Crea account"
Future<void> registra(WidgetTester tester, String username, String email, String password, String conferma) async {
  await tester.enterText(find.widgetWithText(TextFormField, 'Username'), username);
  await tester.enterText(find.widgetWithText(TextFormField, 'Email'), email);
  await tester.enterText(find.widgetWithText(TextFormField, 'Password'), password);
  await tester.enterText(find.widgetWithText(TextFormField, 'Conferma password'), conferma);
  await tester.tap(find.widgetWithText(ElevatedButton, 'Crea account'));
}

void main() {
  group('Store', () {
    test('Without a saved token the app asks to log in, without calling the server', () async {
      final richieste = <Map<String, dynamic>>[];
      final store = WorkoutStore(api: apiDiProva({}, richieste), archivio: ArchivioTokenInMemoria());

      await store.avvia();

      expect(store.booting, isFalse);
      expect(store.utente, isNull);
      expect(store.error, isNull);
      expect(richieste, isEmpty);
    });

    test('A saved valid token logs in and loads the plans', () async {
      final richieste = <Map<String, dynamic>>[];
      final api = apiDiProva({
        'GET /api/auth/me': jsonUtf8(utenteDiProva()),
        'GET /api/plans': jsonUtf8([schedaDiProva(1, 'Forza', [])]),
      }, richieste);
      final store = WorkoutStore(api: api, archivio: ArchivioTokenInMemoria('token-salvato'));

      await store.avvia();

      expect(store.utente!.username, 'davide');
      expect(store.plans.single.name, 'Forza');
      expect(richieste.first['auth'], 'Bearer token-salvato');
    });

    test('An expired saved token is forgotten and the app asks to log in', () async {
      final archivio = ArchivioTokenInMemoria('token-scaduto');
      final api = apiDiProva({
        'GET /api/auth/me': accessoRichiesto(),
      }, []);
      final store = WorkoutStore(api: api, archivio: archivio);

      await store.avvia();

      expect(store.utente, isNull);
      expect(store.error, isNull);
      expect(archivio.token, isNull);
      expect(api.token, isNull);
    });

    test('Backend unreachable at startup shows the connection error', () async {
      final api = ApiService(
        client: MockClient((richiesta) async => throw http.ClientException('rete assente')),
        baseUrl: 'http://localhost/api',
      );
      final archivio = ArchivioTokenInMemoria('token-salvato');
      final store = WorkoutStore(api: api, archivio: archivio);

      await store.avvia();

      expect(store.utente, isNull);
      expect(store.error, contains('Backend non raggiungibile'));
      // Il token resta salvato: quando il backend torna raggiungibile l'utente è ancora collegato
      expect(archivio.token, 'token-salvato');
    });

    test('A 401 while logged in logs out and explains that the session expired', () async {
      final archivio = ArchivioTokenInMemoria();
      final api = apiDiProva({
        'POST /api/auth/login': rispostaAccesso(),
        'GET /api/plans': jsonUtf8([]),
      }, []);
      final store = WorkoutStore(api: api, archivio: archivio);
      await store.accedi('davide@example.com', 'password-di-prova');
      expect(archivio.token, 'token-nuovo');

      // Il server non riconosce più il token
      final scaduto = apiDiProva({'POST /api/plans': accessoRichiesto()}, []);
      final storeScaduto = WorkoutStore(api: scaduto, archivio: archivio);
      storeScaduto.impostaPerTest(utente: store.utente);
      scaduto.token = 'token-nuovo';

      await expectLater(
        storeScaduto.creaScheda('Nuova'),
        throwsA(isA<ApiFailure>().having((e) => e.message, 'message', 'Sessione scaduta. Accedi di nuovo.')),
      );
      expect(storeScaduto.utente, isNull);
      expect(archivio.token, isNull);
      // Nessun avviso nella home: si torna alla pagina di accesso
      expect(storeScaduto.error, isNull);
    });
  });

  group('Pages', () {
    testWidgets('Login validates the fields and sends the trimmed email', (tester) async {
      final richieste = <Map<String, dynamic>>[];
      final archivio = ArchivioTokenInMemoria();
      final api = apiDiProva({
        'POST /api/auth/login': rispostaAccesso(),
        'GET /api/plans': jsonUtf8([]),
      }, richieste);
      final store = WorkoutStore(api: api, archivio: archivio);
      await tester.pumpWidget(appDiProva(store, const AccessoPage()));

      // Con i campi vuoti non parte nessuna richiesta
      await tester.tap(find.widgetWithText(ElevatedButton, 'Accedi'));
      await tester.pump();
      expect(find.text('Inserisci l\'email'), findsOneWidget);
      expect(find.text('Inserisci la password'), findsOneWidget);
      expect(richieste, isEmpty);

      await tester.enterText(find.widgetWithText(TextFormField, 'Email'), '  davide@example.com ');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'password-di-prova');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Accedi'));
      await tester.pumpAndSettle();

      expect(richieste.first['chiave'], 'POST /api/auth/login');
      expect(richieste.first['body'], {'email': 'davide@example.com', 'password': 'password-di-prova'});
      expect(store.utente!.username, 'davide');
      expect(archivio.token, 'token-nuovo');
    });

    testWidgets('Wrong credentials show the server message', (tester) async {
      final api = apiDiProva({
        'POST /api/auth/login': jsonUtf8({'message': 'Email o password non corretti.'}, 401),
      }, []);
      final store = WorkoutStore(api: api, archivio: ArchivioTokenInMemoria());
      await tester.pumpWidget(appDiProva(store, const AccessoPage()));

      await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'davide@example.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'sbagliata');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Accedi'));
      await tester.pumpAndSettle();

      expect(find.text('Email o password non corretti.'), findsOneWidget);
      expect(store.utente, isNull);
    });

    testWidgets('Registration checks the fields and shows server conflicts', (tester) async {
      final richieste = <Map<String, dynamic>>[];
      final api = apiDiProva({
        'POST /api/auth/register': jsonUtf8({'message': 'Username già in uso.'}, 409),
      }, richieste);
      final store = WorkoutStore(api: api, archivio: ArchivioTokenInMemoria());
      await tester.pumpWidget(appDiProva(store, const RegistrazionePage()));

      await registra(tester, 'ab', 'non-una-email', 'corta', 'diversa');
      await tester.pump();

      expect(find.text('Da 3 a 30 caratteri tra lettere, numeri, . e _'), findsOneWidget);
      expect(find.text('Email non valida'), findsOneWidget);
      expect(find.text('Da 8 a 64 caratteri'), findsOneWidget);
      expect(find.text('Le password non coincidono'), findsOneWidget);
      expect(richieste, isEmpty);

      await registra(tester, 'davide', 'davide@example.com', 'password-di-prova', 'password-di-prova');
      await tester.pumpAndSettle();

      expect(richieste.single['body'],
          {'username': 'davide', 'email': 'davide@example.com', 'password': 'password-di-prova'});
      expect(find.text('Username già in uso.'), findsOneWidget);
      expect(store.utente, isNull);
    });

    testWidgets('From login to home and back with "Esci"', (tester) async {
      final archivio = ArchivioTokenInMemoria();
      final api = apiDiProva({
        'POST /api/auth/register': rispostaAccesso(201),
        'GET /api/plans': jsonUtf8([schedaDiProva(1, 'Forza', [])]),
      }, []);
      final store = WorkoutStore(api: api, archivio: archivio);
      await store.avvia();
      await tester.pumpWidget(appDiProva(store, const SplashPage()));
      await tester.pumpAndSettle();

      // Nessun token salvato: si vede l'accesso, da cui si apre la registrazione
      expect(find.byType(AccessoPage), findsOneWidget);
      await tester.tap(find.text('Non hai un account? Registrati'));
      await tester.pumpAndSettle();

      await registra(tester, 'davide', 'davide@example.com', 'password-di-prova', 'password-di-prova');
      await tester.pumpAndSettle();

      // La registrazione si chiude e si vede la home con le schede dell'utente
      expect(find.byType(RegistrazionePage), findsNothing);
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.text('Forza'), findsOneWidget);

      // Il menu dell'account mostra lo username e permette di uscire
      await tester.tap(find.byTooltip('Account'));
      await tester.pumpAndSettle();
      expect(find.text('@davide'), findsOneWidget);
      await tester.tap(find.text('Esci'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Conferma'));
      await tester.pumpAndSettle();

      expect(find.byType(AccessoPage), findsOneWidget);
      expect(store.plans, isEmpty);
      expect(archivio.token, isNull);
    });

    testWidgets('An expired session while a page is open goes back to login', (tester) async {
      final api = apiDiProva({
        'POST /api/auth/login': rispostaAccesso(),
        'GET /api/plans': jsonUtf8([schedaDiProva(1, 'Forza', [])]),
        'PUT /api/plans/1': accessoRichiesto(),
      }, []);
      final store = WorkoutStore(api: api, archivio: ArchivioTokenInMemoria());
      await store.avvia();
      await store.accedi('davide@example.com', 'password-di-prova');
      await tester.pumpWidget(appDiProva(store, const SplashPage()));
      await tester.pumpAndSettle();

      // La scheda è una pagina sopra la home
      await tester.tap(find.text('Forza'));
      await tester.pumpAndSettle();
      expect(find.text('Aggiungi giornata'), findsOneWidget);

      // Una modifica riceve 401: tutte le pagine si chiudono e resta l'accesso
      await tester.runAsync(() async {
        try {
          await store.rinominaScheda(1, 'X');
        } on ApiFailure {
          // Atteso: sessione scaduta
        }
      });
      await tester.pumpAndSettle();

      expect(find.text('Aggiungi giornata'), findsNothing);
      expect(find.byType(AccessoPage), findsOneWidget);
    });
  });
}
