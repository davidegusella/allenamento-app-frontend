import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../models/chat.dart';
import '../models/workout.dart';
import '../services/api_service.dart';
import '../services/socket_chat.dart';
import 'workout_store.dart';

/// Stato delle chat: elenco, messaggi caricati e non letti, aggiornato in tempo reale dal WebSocket.
/// Segue l'utente di [WorkoutStore] con [segui]: si collega all'accesso e si svuota all'uscita
class ChatStore extends ChangeNotifier {
  static const int _messaggiPerPagina = 30;

  final SocketChat _socket;
  WorkoutStore? _store;

  /// Utente per cui è aperto il socket, null se nessuno è collegato
  int? _utenteCollegato;

  List<Conversazione> _conversazioni = [];

  /// Messaggi caricati per username dell'altro, dal più recente; manca la chiave se non sono ancora stati caricati
  final Map<String, List<Messaggio>> messaggi = {};

  /// Chat di cui è già caricato anche il primo messaggio
  final Set<String> _complete = {};

  /// Chat visibile in questo momento: i messaggi che arrivano lì sono già letti
  String? _chatAperta;

  bool _caricandoPrecedenti = false;

  ChatStore({SocketChat? socket}) : _socket = socket ?? SocketChatVero();

  /// Chat con almeno un messaggio, dalla più recente
  List<Conversazione> get conversazioni => _conversazioni;

  /// Chat già caricate, per i test delle pagine
  @visibleForTesting
  void impostaPerTest(List<Conversazione> conversazioni) {
    _conversazioni = conversazioni;
    notifyListeners();
  }

  int get totaleNonLetti => _conversazioni.fold(0, (totale, chat) => totale + chat.nonLetti);

  /// null se con [username] non ci sono ancora messaggi
  Conversazione? conversazione(String username) {
    return _conversazioni.where((chat) => chat.username == username).firstOrNull;
  }

  /// Chiamata a ogni cambiamento di [WorkoutStore]: apre il socket all'accesso e lo chiude all'uscita.
  /// Non avvisa le pagine perché viene eseguita mentre il provider si ridisegna
  void segui(WorkoutStore nuovoStore) {
    _store = nuovoStore;
    final utente = nuovoStore.utente?.id;
    if (utente == _utenteCollegato) {
      return;
    }
    _utenteCollegato = utente;
    _socket.chiudi();
    _svuota();
    if (utente != null) {
      _socket.collega(nuovoStore.api.token ?? '', onEvento: _ricevi, onCollegato: _riallinea);
    }
  }

  void _svuota() {
    _conversazioni = [];
    messaggi.clear();
    _complete.clear();
    _chatAperta = null;
  }

  Future<dynamic> _richiesta(String method, String path, [Object? body]) {
    return _store!.richiestaUtente(method, path, body);
  }

  /// Per esempio /chat/marco
  static String _chatCon(String username) {
    return '/chat/${Uri.encodeComponent(username)}';
  }

  Future<void> carica() async {
    _conversazioni = Conversazione.listaDaJson(await _richiesta('GET', '/chat/conversazioni'));
    notifyListeners();
  }

  /// Dopo ogni connessione ricarica elenco e chat aperta: contengono gli eventi che possono essere stati persi
  Future<void> _riallinea() async {
    try {
      await carica();
      final aperta = _chatAperta;
      if (aperta != null) {
        await apri(aperta);
      }
    } on ApiFailure {
      // Si riprova alla prossima connessione o quando l'utente aggiorna l'elenco
    }
  }

  /// Controlla, prima di aprire una nuova chat, che l'utente esista e non sia chi scrive.
  /// Lancia [ApiFailure] con il messaggio del backend, per esempio "Utente non trovato: marco"
  Future<void> verifica(String username) async {
    await _richiesta('GET', '${_chatCon(username)}/messaggi');
  }

  /// Carica gli ultimi messaggi e li segna come letti: da qui i nuovi messaggi della chat arrivano già letti
  Future<void> apri(String username) async {
    _chatAperta = username;
    final pagina = Messaggio.listaDaJson(await _richiesta('GET', '${_chatCon(username)}/messaggi'));
    messaggi[username] = pagina;
    _segnaCompleta(username, pagina);
    notifyListeners();
    await segnaLetti(username);
  }

  void chiudiChat(String username) {
    if (_chatAperta == username) {
      _chatAperta = null;
    }
  }

  /// Carica la pagina di messaggi precedente a quelle già caricate
  Future<void> caricaPrecedenti(String username) async {
    final caricati = messaggi[username];
    if (caricati == null || caricati.isEmpty || _complete.contains(username) || _caricandoPrecedenti) {
      return;
    }
    _caricandoPrecedenti = true;
    try {
      final path = '${_chatCon(username)}/messaggi?prima=${caricati.last.id}';
      final pagina = Messaggio.listaDaJson(await _richiesta('GET', path));
      caricati.addAll(pagina);
      _segnaCompleta(username, pagina);
    } finally {
      _caricandoPrecedenti = false;
      notifyListeners();
    }
  }

  void _segnaCompleta(String username, List<Messaggio> pagina) {
    if (pagina.length < _messaggiPerPagina) {
      _complete.add(username);
    }
  }

  Future<void> segnaLetti(String username) async {
    _aggiornaConversazione(username, (chat) => chat.copia(nonLetti: 0));
    notifyListeners();
    await _richiesta('POST', '${_chatCon(username)}/letti');
  }

  Future<void> invia(String username, String testo) async {
    await _inviaMessaggio('${_chatCon(username)}/messaggi', {'text': testo});
  }

  /// Invia una propria scheda ([planId]) oppure un post ([postId])
  Future<void> inviaScheda(String username, {int? planId, int? postId}) async {
    await _inviaMessaggio('${_chatCon(username)}/schede', {'planId': planId, 'postId': postId});
  }

  Future<void> _inviaMessaggio(String path, Json body) async {
    _aggiungi(Messaggio.fromJson(comeJson(await _richiesta('POST', path, body))));
    notifyListeners();
  }

  /// La versione attuale della scheda personale inviata nel messaggio.
  /// Lancia [ApiFailure] con status 404 se il mittente l'ha eliminata
  Future<Plan> caricaSchedaRicevuta(int messaggioId) async {
    return Plan.fromJson(comeJson(await _richiesta('GET', '/chat/messaggi/$messaggioId/scheda')));
  }

  Future<void> elimina(Messaggio messaggio) async {
    await _richiesta('DELETE', '/chat/messaggi/${messaggio.id}');
    _segnaEliminato(messaggio.conPersona, messaggio.id);
    notifyListeners();
  }

  /// Evento ricevuto dal WebSocket (EventoChat del backend)
  void _ricevi(Json evento) {
    switch (evento['tipo']) {
      case 'NUOVO':
        final messaggio = Messaggio.fromJson(comeJson(evento['messaggio']));
        _aggiungi(messaggio);
        if (!messaggio.mio && _chatAperta == messaggio.conPersona) {
          segnaLetti(messaggio.conPersona).catchError((Object errore) {});
        }
      case 'LETTI':
        _aggiornaConversazione(evento['conPersona'], (chat) => chat.copia(lettoDallAltro: evento['finoA']));
      case 'ELIMINATO':
        _segnaEliminato(evento['conPersona'], evento['id']);
        // I non letti possono essere diminuiti: li ricalcola il backend
        if (_chatAperta != evento['conPersona']) {
          _riallinea();
        }
      default:
        return;
    }
    notifyListeners();
  }

  /// Aggiunge il messaggio alla sua chat e la porta in cima all'elenco.
  /// Lo stesso messaggio può arrivare due volte (risposta dell'invio ed evento): la seconda si ignora
  void _aggiungi(Messaggio messaggio) {
    final username = messaggio.conPersona;
    final caricati = messaggi[username];
    if (caricati != null && !caricati.any((m) => m.id == messaggio.id)) {
      caricati.insert(0, messaggio);
    }

    final esistente = conversazione(username);
    if (esistente != null && esistente.ultimoMessaggio.id >= messaggio.id) {
      return;
    }
    final daLeggere = !messaggio.mio && _chatAperta != username;
    final aggiornata = esistente == null
        ? Conversazione(username: username, ultimoMessaggio: messaggio, nonLetti: daLeggere ? 1 : 0)
        : esistente.copia(ultimoMessaggio: messaggio, nonLetti: daLeggere ? esistente.nonLetti + 1 : 0);
    _conversazioni = [aggiornata, ...conversazioni.where((chat) => chat.username != username)];
  }

  void _segnaEliminato(String username, int id) {
    final caricati = messaggi[username];
    if (caricati != null) {
      final indice = caricati.indexWhere((m) => m.id == id);
      if (indice >= 0) {
        caricati[indice] = caricati[indice].comeEliminato();
      }
    }
    _aggiornaConversazione(username, (chat) {
      if (chat.ultimoMessaggio.id != id) {
        return chat;
      }
      return chat.copia(ultimoMessaggio: chat.ultimoMessaggio.comeEliminato());
    });
  }

  void _aggiornaConversazione(String username, Conversazione Function(Conversazione chat) modifica) {
    _conversazioni = [
      for (final chat in _conversazioni) chat.username == username ? modifica(chat) : chat,
    ];
  }

  @override
  void dispose() {
    _socket.chiudi();
    super.dispose();
  }
}

/// Provider di [ChatStore] che segue [WorkoutStore]: va messo dopo il provider di WorkoutStore
///
/// [crea] crea lo store della chat; nei test con un socket finto
ChangeNotifierProxyProvider<WorkoutStore, ChatStore> providerChat(ChatStore Function(BuildContext context) crea) {
  return ChangeNotifierProxyProvider<WorkoutStore, ChatStore>(
    create: crea,
    // Non pigro: segue l'utente anche quando nessuna pagina legge la chat, per chiudere il socket all'uscita
    lazy: false,
    update: (context, store, chat) => chat!..segui(store),
  );
}
