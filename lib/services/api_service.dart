import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// Eccezione lanciata quando una chiamata al backend non va a buon fine.
/// Il messaggio è già pronto per essere mostrato all'utente.
class ApiFailure implements Exception {
  final String message;

  /// Codice HTTP della risposta, null se il server non ha risposto
  final int? status;

  ApiFailure(this.message, [this.status]);

  @override
  String toString() {
    return message;
  }
}

/// Client REST verso il backend: aggiunge token e Content-Type, applica un timeout, decodifica il JSON
/// e trasforma gli errori HTTP e di rete in [ApiFailure]
class ApiService {
  static const Duration timeout = Duration(seconds: 20);

  final http.Client _client;
  final String baseUrl;

  /// Ricevuto all'accesso; null finché l'utente non ha fatto accesso
  String? token;

  /// Nei test con un client finto (MockClient) e un indirizzo di prova
  ApiService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? ApiConfig.baseUrl;

  /// Il JSON della risposta, null se non ha corpo (204). Lancia [ApiFailure] se il server non risponde
  /// o restituisce un errore; [path] è relativo, per esempio /plans
  Future<dynamic> request(String method, String path, [Object? body]) async {
    if (baseUrl.isEmpty) {
      throw ApiFailure('Imposta baseUrl in lib/config/api_config.dart.');
    }

    final richiesta = http.Request(method, Uri.parse('$baseUrl$path'));
    richiesta.headers['Content-Type'] = 'application/json';
    // Registrazione e accesso si fanno senza token
    final tokenAttuale = token;
    if (tokenAttuale != null) {
      richiesta.headers['Authorization'] = 'Bearer $tokenAttuale';
    }
    if (body != null) {
      richiesta.body = jsonEncode(body);
    }

    http.Response risposta;
    try {
      risposta = await _invia(richiesta).timeout(timeout);
    } on TimeoutException {
      throw ApiFailure('Tempo scaduto: salvataggio non confermato. Riprova.');
    } on http.ClientException {
      throw ApiFailure('Backend non raggiungibile. Controlla la connessione e riprova.');
    }

    final json = _decodifica(risposta);

    // Fuori dai 2xx il messaggio è quello del GlobalExceptionHandler del backend
    if (risposta.statusCode < 200 || risposta.statusCode >= 300) {
      String messaggio = 'Errore del server.';
      if (json is Map && json['message'] != null) {
        messaggio = json['message'].toString();
      }
      throw ApiFailure(messaggio, risposta.statusCode);
    }

    return json;
  }

  Future<http.Response> _invia(http.Request richiesta) async {
    return http.Response.fromStream(await _client.send(richiesta));
  }

  /// In UTF-8, così le lettere accentate restano corrette; null se il corpo è vuoto
  dynamic _decodifica(http.Response risposta) {
    if (risposta.body.isEmpty) {
      return null;
    }
    try {
      return jsonDecode(utf8.decode(risposta.bodyBytes));
    } on FormatException {
      throw ApiFailure('Il server ha restituito una risposta non valida.', risposta.statusCode);
    }
  }

  void dispose() {
    _client.close();
  }
}
