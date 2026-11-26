import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/api_config.dart';
import '../models/workout.dart';

/// WebSocket della chat, da cui il backend invia gli eventi in tempo reale (nuovo messaggio, letti, eliminato).
/// L'app usa [SocketChatVero], i test un socket finto
abstract class SocketChat {
  /// La connessione resta aperta finché non si chiama [chiudi] e si ricollega se cade.
  /// [onEvento] riceve ogni evento, per esempio {"tipo": "NUOVO", "messaggio": {...}};
  /// [onCollegato] arriva a ogni connessione riuscita, anche dopo una caduta: è il momento di ricaricare
  /// quello che può essere arrivato nel frattempo
  void collega(String token, {required void Function(Json evento) onEvento, required void Function() onCollegato});

  void chiudi();
}

class SocketChatVero implements SocketChat {
  static const Duration attesaRiconnessione = Duration(seconds: 3);

  final String baseUrl;
  WebSocketChannel? _canale;
  StreamSubscription<dynamic>? _ascolto;
  Timer? _riconnessione;

  SocketChatVero({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  /// Da http://localhost:8080/api a ws://localhost:8080/ws/chat?token=...
  static Uri indirizzo(String baseUrl, String token) {
    final api = Uri.parse(baseUrl);
    final radice = api.path.endsWith('/api') ? api.path.substring(0, api.path.length - 4) : api.path;
    return api.replace(
      scheme: api.scheme == 'https' ? 'wss' : 'ws',
      path: '$radice/ws/chat',
      queryParameters: {'token': token},
    );
  }

  @override
  void collega(String token, {required void Function(Json evento) onEvento, required void Function() onCollegato}) {
    chiudi();
    final nuovo = WebSocketChannel.connect(indirizzo(baseUrl, token));
    _canale = nuovo;
    // Se la connessione non riesce l'errore arriva anche sullo stream, che poi si chiude e fa riprovare
    nuovo.ready.then((valore) => onCollegato(), onError: (Object errore) {});
    _ascolto = nuovo.stream.listen(
      (dato) {
        try {
          onEvento(comeJson(jsonDecode(dato as String)));
        } on FormatException {
          // Un evento illeggibile non deve chiudere la chat
        }
      },
      onError: (Object errore) {},
      onDone: () {
        _riconnessione = Timer(attesaRiconnessione, () => collega(token, onEvento: onEvento, onCollegato: onCollegato));
      },
    );
  }

  @override
  void chiudi() {
    _riconnessione?.cancel();
    _riconnessione = null;
    // L'ascolto si toglie prima di chiudere: così onDone non programma una nuova connessione
    _ascolto?.cancel();
    _ascolto = null;
    _canale?.sink.close();
    _canale = null;
  }
}
