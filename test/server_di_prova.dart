import 'dart:convert';

import 'package:allenamentofrontend/models/utente.dart';
import 'package:allenamentofrontend/models/workout.dart';
import 'package:allenamentofrontend/providers/chat_store.dart';
import 'package:allenamentofrontend/providers/workout_store.dart';
import 'package:allenamentofrontend/services/api_service.dart';
import 'package:allenamentofrontend/services/archivio_token.dart';
import 'package:allenamentofrontend/services/socket_chat.dart';
import 'package:allenamentofrontend/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'dati_di_prova.dart';

/// Server finto: per ogni "METODO /percorso?query" restituisce la risposta indicata
/// e salva in [richieste] le richieste ricevute, con l'header Authorization.
/// Le richieste non previste ricevono 404. Per esempio {'GET /api/plans': http.Response('[]', 200)}
ApiService apiDiProva(Map<String, http.Response> risposte, List<Map<String, dynamic>> richieste) {
  final server = MockClient((richiesta) async {
    final query = richiesta.url.hasQuery ? '?${richiesta.url.query}' : '';
    final chiave = '${richiesta.method} ${richiesta.url.path}$query';
    dynamic body;
    if (richiesta.body.isNotEmpty) {
      body = jsonDecode(richiesta.body);
    }
    richieste.add({'chiave': chiave, 'auth': richiesta.headers['Authorization'], 'body': body});
    return risposte[chiave] ?? http.Response('{"message":"Indirizzo non trovato."}', 404);
  });
  return ApiService(client: server, baseUrl: 'http://localhost/api');
}

/// Store con "davide" collegato e il server finto di [apiDiProva]. I corpi delle [risposte] sono JSON
/// con status 200 (null diventa 204); un [http.Response] si usa così com'è
WorkoutStore storeDiProva(Map<String, Object?> risposte, List<Map<String, dynamic>> richieste) {
  final server = risposte.map((chiave, corpo) => MapEntry(chiave, corpo is http.Response ? corpo : jsonUtf8(corpo)));
  final store = WorkoutStore(api: apiDiProva(server, richieste), archivio: ArchivioTokenInMemoria());
  store.impostaPerTest(utente: Utente.fromJson(utenteDiProva()));
  return store;
}

/// Le richieste ricevute dal server finto, come "METODO /percorso?query"
List<String> chiavi(List<Map<String, dynamic>> richieste) {
  return [for (final richiesta in richieste) richiesta['chiave'] as String];
}

/// Le richieste che modificano dati, senza le letture (GET)
List<Map<String, dynamic>> modifiche(List<Map<String, dynamic>> richieste) {
  return richieste.where((richiesta) => !(richiesta['chiave'] as String).startsWith('GET ')).toList();
}

/// Schermo da telefono, per accorgersi di testi che escono dallo schermo
void telefonoPiccolo(WidgetTester tester, {double altezza = 844}) {
  tester.view.physicalSize = Size(390, altezza);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Apre [pagina] sopra una pagina vuota con il pulsante "Apri", per controllare che si chiuda da sola
Future<void> apriSopra(WidgetTester tester, WorkoutStore store, Widget pagina) async {
  await tester.pumpWidget(appDiProva(
    store,
    Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (routeContext) => pagina)),
          child: const Text('Apri'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('Apri'));
  await tester.pumpAndSettle();
}

/// Risposta JSON in UTF-8 come nel backend vero: senza, http.Response userebbe latin1 per le lettere accentate.
/// Senza [corpo] è una risposta vuota 204, come le eliminazioni del backend
http.Response jsonUtf8(Object? corpo, [int status = 200]) {
  if (corpo == null) {
    return http.Response('', 204);
  }
  return http.Response.bytes(utf8.encode(jsonEncode(corpo)), status);
}

/// WebSocket finto: il test decide quando la connessione riesce e quali eventi arrivano
class SocketChatFinto implements SocketChat {
  String? token;
  void Function(Json evento)? onEvento;
  void Function()? onCollegato;

  bool get aperto => token != null;

  @override
  void collega(String token, {required void Function(Json evento) onEvento, required void Function() onCollegato}) {
    this.token = token;
    this.onEvento = onEvento;
    this.onCollegato = onCollegato;
  }

  @override
  void chiudi() {
    token = null;
  }

  void evento(Json evento) {
    onEvento!(evento);
  }
}

/// L'app con gli store e il tema, aperta su [pagina]. Senza [chat] la chat usa un socket finto che non si collega
Widget appDiProva(WorkoutStore store, Widget pagina, {ChatStore? chat}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: store),
      providerChat((context) => chat ?? ChatStore(socket: SocketChatFinto())),
    ],
    child: MaterialApp(theme: graphiteTheme(), home: pagina),
  );
}
