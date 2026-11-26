import 'package:allenamentofrontend/models/chat.dart';
import 'package:allenamentofrontend/models/workout.dart';
import 'package:allenamentofrontend/pages/chat_list_page.dart';
import 'package:allenamentofrontend/pages/chat_page.dart';
import 'package:allenamentofrontend/pages/home_page.dart';
import 'package:allenamentofrontend/pages/plans_page.dart';
import 'package:allenamentofrontend/providers/chat_store.dart';
import 'package:allenamentofrontend/services/socket_chat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dati_di_prova.dart';
import 'server_di_prova.dart';

void main() {
  late SocketChatFinto socket;
  late ChatStore chat;
  late List<Map<String, dynamic>> richieste;

  setUp(() {
    socket = SocketChatFinto();
    chat = ChatStore(socket: socket);
    richieste = [];
  });

  testWidgets('The chat list shows previews and unread counts and updates in real time', (tester) async {
    telefonoPiccolo(tester);
    final store = storeDiProva({
      'GET /api/chat/conversazioni': [
        conversazioneDiProva('marco', messaggioDiProva(5, 'marco', 'marco', 'Ci vediamo alle 18?'), nonLetti: 2),
        conversazioneDiProva('giulia', messaggioDiProva(3, 'giulia', 'davide', 'Ok'), lettoDallAltro: 3),
      ],
    }, richieste);

    await tester.pumpWidget(appDiProva(store, const HomePage(), chat: chat));
    expect(socket.aperto, isTrue);
    await tester.tap(find.text('Messaggi'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(find.text('@marco'), findsOneWidget);
    expect(find.text('Ci vediamo alle 18?'), findsOneWidget);
    expect(find.text('Tu: Ok'), findsOneWidget);
    expect(find.byIcon(Icons.done_all), findsOneWidget);
    // Il numero dei non letti nella riga e sulla barra in basso
    expect(find.text('2'), findsNWidgets(2));

    socket.evento({'tipo': 'NUOVO', 'messaggio': messaggioDiProva(6, 'giulia', 'giulia', 'Arrivo!')});
    await tester.pumpAndSettle();

    expect(find.text('Arrivo!'), findsOneWidget);
    expect(find.text('Tu: Ok'), findsNothing);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    final righe = tester.widgetList<Text>(find.textContaining(RegExp(r'^@'))).map((testo) => testo.data).toList();
    expect(righe, ['@giulia', '@marco']);
    expect(chiavi(richieste), ['GET /api/chat/conversazioni']);
  });

  testWidgets('An open chat sends, receives, shows reads and deletions without reloading', (tester) async {
    telefonoPiccolo(tester);
    final store = storeDiProva({
      'GET /api/chat/marco/messaggi': [
        messaggioDiProva(5, 'marco', 'marco', 'Ci vediamo alle 18?'),
        messaggioDiProva(4, 'marco', 'davide', 'Allenamento oggi?'),
      ],
      'POST /api/chat/marco/letti': null,
      'POST /api/chat/marco/messaggi': messaggioDiProva(7, 'marco', 'davide', 'Perfetto'),
      'DELETE /api/chat/messaggi/4': null,
    }, richieste);

    await tester.pumpWidget(appDiProva(store, const ChatPage(username: 'marco'), chat: chat));
    await tester.pumpAndSettle();
    chat.impostaPerTest([
      Conversazione.fromJson(
          conversazioneDiProva('marco', messaggioDiProva(5, 'marco', 'marco', 'Ci vediamo alle 18?'))),
    ]);

    expect(chiavi(richieste), ['GET /api/chat/marco/messaggi', 'POST /api/chat/marco/letti']);
    expect(find.text('Allenamento oggi?'), findsOneWidget);
    expect(find.byIcon(Icons.done), findsOneWidget);

    socket.evento({'tipo': 'LETTI', 'conPersona': 'marco', 'finoA': 4});
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.done_all), findsOneWidget);

    await tester.enterText(find.byType(TextField), '  Perfetto ');
    await tester.pump();
    await tester.tap(find.byTooltip('Invia messaggio'));
    await tester.pumpAndSettle();
    expect(richieste.last['body'], {'text': 'Perfetto'});
    // Lo stesso messaggio arriva anche dal WebSocket: resta uno solo
    socket.evento({'tipo': 'NUOVO', 'messaggio': messaggioDiProva(7, 'marco', 'davide', 'Perfetto')});
    await tester.pumpAndSettle();
    expect(find.text('Perfetto'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);

    // Con la chat aperta un messaggio di marco è subito letto
    socket.evento({'tipo': 'NUOVO', 'messaggio': messaggioDiProva(8, 'marco', 'marco', 'A dopo')});
    await tester.pumpAndSettle();
    expect(find.text('A dopo'), findsOneWidget);
    expect(chiavi(richieste).last, 'POST /api/chat/marco/letti');
    expect(chat.totaleNonLetti, 0);

    socket.evento({'tipo': 'ELIMINATO', 'conPersona': 'marco', 'id': 5});
    await tester.pumpAndSettle();
    expect(find.text('Ci vediamo alle 18?'), findsNothing);
    expect(find.text('Messaggio eliminato'), findsOneWidget);

    await tester.longPress(find.text('Allenamento oggi?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Conferma'));
    await tester.pumpAndSettle();
    expect(chiavi(richieste).last, 'DELETE /api/chat/messaggi/4');
    expect(find.text('Messaggio eliminato'), findsNWidgets(2));
  });

  testWidgets('Scrolling to the top of a chat loads the older messages', (tester) async {
    telefonoPiccolo(tester);
    final store = storeDiProva({
      'GET /api/chat/marco/messaggi': [
        for (int id = 60; id > 30; id--) messaggioDiProva(id, 'marco', 'marco', 'Messaggio $id'),
      ],
      'POST /api/chat/marco/letti': null,
      'GET /api/chat/marco/messaggi?prima=31': [messaggioDiProva(30, 'marco', 'marco', 'Il più vecchio')],
    }, richieste);

    await tester.pumpWidget(appDiProva(store, const ChatPage(username: 'marco'), chat: chat));
    await tester.pumpAndSettle();
    expect(chiavi(richieste), isNot(contains('GET /api/chat/marco/messaggi?prima=31')));

    await tester.fling(find.byType(ListView), const Offset(0, 3000), 5000);
    await tester.pumpAndSettle();
    expect(chiavi(richieste), contains('GET /api/chat/marco/messaggi?prima=31'));
    expect(find.text('Il più vecchio'), findsOneWidget);
  });

  testWidgets('A new chat opens only with an existing username', (tester) async {
    final store = storeDiProva({
      'GET /api/chat/conversazioni': [],
      'GET /api/chat/nessuno/messaggi': jsonUtf8({'message': 'Utente non trovato: nessuno'}, 404),
      'GET /api/chat/marco/messaggi': [],
      'POST /api/chat/marco/letti': null,
    }, richieste);

    await tester.pumpWidget(appDiProva(store, const Scaffold(body: ChatListPage()), chat: chat));
    await tester.pumpAndSettle();
    expect(find.text('Nessuna chat'), findsOneWidget);

    await tester.tap(find.text('Nuova chat'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Nessuno');
    await tester.tap(find.text('Scrivi'));
    await tester.pumpAndSettle();
    expect(find.text('Utente non trovato: nessuno'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'Marco');
    await tester.pumpAndSettle();
    expect(find.text('Utente non trovato: nessuno'), findsNothing);
    await tester.tap(find.text('Scrivi'));
    await tester.pumpAndSettle();
    expect(find.text('@marco'), findsOneWidget);
    expect(find.text('Scrivi il primo messaggio a @marco'), findsOneWidget);
  });

  testWidgets('The socket follows the logged user: it reloads on connect and closes on logout', (tester) async {
    final store = storeDiProva({
      'GET /api/chat/conversazioni': [
        conversazioneDiProva('marco', messaggioDiProva(5, 'marco', 'marco', 'Ciao'), nonLetti: 1),
      ],
    }, richieste);

    await tester.pumpWidget(appDiProva(store, const SizedBox(), chat: chat));
    expect(socket.aperto, isTrue);
    expect(richieste, isEmpty);

    socket.onCollegato!();
    await tester.pumpAndSettle();
    expect(chat.totaleNonLetti, 1);

    await store.esci();
    await tester.pumpAndSettle();
    expect(socket.aperto, isFalse);
    expect(chat.conversazioni, isEmpty);
  });

  testWidgets('A plan is sent from Schede to an existing chat', (tester) async {
    telefonoPiccolo(tester);
    final store = storeDiProva({
      'POST /api/chat/marco/schede': messaggioSchedaDiProva(9, 'marco', 'davide', 'Forza', planId: 1),
    }, richieste);
    store.impostaPerTest(plans: Plan.listaDaJson([forza()]));

    await tester.pumpWidget(appDiProva(store, const Scaffold(body: PlansPage()), chat: chat));
    // Dopo pumpWidget: all'accesso ChatStore si svuota
    chat.impostaPerTest(
        [Conversazione.fromJson(conversazioneDiProva('marco', messaggioDiProva(5, 'marco', 'marco', 'Ciao')))]);
    await tester.tap(find.byTooltip('Invia in chat'));
    await tester.pumpAndSettle();
    expect(find.text('Nuova chat'), findsOneWidget);
    await tester.tap(find.text('@marco'));
    await tester.pumpAndSettle();

    expect(richieste.single['chiave'], 'POST /api/chat/marco/schede');
    expect(richieste.single['body'], {'planId': 1, 'postId': null});
    expect(find.text('Scheda inviata a @marco'), findsOneWidget);
    expect(chat.conversazione('marco')!.anteprima, 'Tu: Scheda: Forza');
  });

  testWidgets('A received plan opens as it is now and can be imported', (tester) async {
    telefonoPiccolo(tester);
    final store = storeDiProva({
      'GET /api/chat/marco/messaggi': [messaggioSchedaDiProva(9, 'marco', 'marco', 'Forza', planId: 1)],
      'POST /api/chat/marco/letti': null,
      'GET /api/chat/messaggi/9/scheda': forza(),
      'POST /api/chat/messaggi/9/import': forza(importedFrom: 'marco'),
      'GET /api/plans': [forza(importedFrom: 'marco')],
    }, richieste);

    await tester.pumpWidget(appDiProva(store, const ChatPage(username: 'marco'), chat: chat));
    await tester.pumpAndSettle();
    expect(find.text('Scheda di @marco · tocca per aprire'), findsOneWidget);

    await tester.tap(find.text('Forza'));
    await tester.pumpAndSettle();
    expect(find.text('Inviata da @marco'), findsOneWidget);
    expect(find.text('Panca'), findsOneWidget);

    await tester.tap(find.text('Importa nelle mie schede'));
    await tester.pumpAndSettle();
    expect(chiavi(richieste), containsAllInOrder(['POST /api/chat/messaggi/9/import', 'GET /api/plans']));
    expect(find.text('Scheda importata nelle tue schede'), findsOneWidget);
    expect(store.plans.single.importedFrom, 'marco');
  });

  testWidgets('A deleted plan or post shows the warning instead of opening', (tester) async {
    telefonoPiccolo(tester);
    // Il server finto risponde 404 a scheda e post, che non sono tra le risposte
    final store = storeDiProva({
      'GET /api/chat/marco/messaggi': [
        messaggioSchedaDiProva(10, 'marco', 'marco', 'Ipertrofia', postId: 4),
        messaggioSchedaDiProva(9, 'marco', 'marco', 'Forza', planId: 1),
      ],
      'POST /api/chat/marco/letti': null,
    }, richieste);

    await tester.pumpWidget(appDiProva(store, const ChatPage(username: 'marco'), chat: chat));
    await tester.pumpAndSettle();
    expect(find.text('Post di @marco · tocca per aprire'), findsOneWidget);

    for (final nome in ['Forza', 'Ipertrofia']) {
      await tester.tap(find.text(nome));
      await tester.pumpAndSettle();
      expect(find.text(SchedaInviata.avvisoEliminata), findsOneWidget);
      await tester.tap(find.text('Ok'));
      await tester.pumpAndSettle();
    }
    expect(chiavi(richieste), containsAll(['GET /api/chat/messaggi/9/scheda', 'GET /api/posts/4']));
    expect(find.text('Inviata da @marco'), findsNothing);
  });

  test('The WebSocket address is derived from the API address', () {
    expect(
      SocketChatVero.indirizzo('http://192.168.1.5:8080/api', 'abc'),
      Uri.parse('ws://192.168.1.5:8080/ws/chat?token=abc'),
    );
    expect(
        SocketChatVero.indirizzo('https://palestra.it/api', 'abc'), Uri.parse('wss://palestra.it/ws/chat?token=abc'));
  });
}
