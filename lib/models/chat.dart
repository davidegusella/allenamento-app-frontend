import 'workout.dart';

/// Scheda inviata in un messaggio (SchedaInviataResponseDto): un collegamento a una scheda
/// personale del mittente ([planId]) oppure a un post ([postId]). Nome e autore sono quelli dell'invio.
class SchedaInviata {
  /// Come SCHEDA_ELIMINATA nel backend: si mostra quando scheda o post non esistono più
  static const avvisoEliminata = 'Questa scheda di allenamento non può più essere usata perché è stata eliminata.';

  final int? planId;
  final int? postId;
  final String nome;
  final String autore;

  SchedaInviata.fromJson(Json json)
      : planId = json['planId'],
        postId = json['postId'],
        nome = json['nome'],
        autore = json['autore'];
}

/// Messaggio di una chat (MessaggioResponseDto): un testo oppure una [SchedaInviata]
class Messaggio {
  /// Come Messaggio.LUNGHEZZA_MASSIMA nel backend
  static const lunghezzaMassima = 1000;

  final int id;

  /// Username dell'altro utente della chat
  final String conPersona;

  /// Username di chi l'ha scritto
  final String mittente;

  /// null se il messaggio è una scheda o il mittente l'ha eliminato
  final String? text;

  /// null se il messaggio è un testo o il mittente l'ha eliminato
  final SchedaInviata? scheda;
  final DateTime createdAt;

  const Messaggio({
    required this.id,
    required this.conPersona,
    required this.mittente,
    required this.text,
    required this.createdAt,
    this.scheda,
  });

  Messaggio.fromJson(Json json)
      : id = json['id'],
        conPersona = json['conPersona'],
        mittente = json['mittente'],
        text = json['text'],
        scheda = json['scheda'] == null ? null : SchedaInviata.fromJson(comeJson(json['scheda'])),
        createdAt = dataLocale(json['createdAt']);

  static List<Messaggio> listaDaJson(dynamic lista) {
    return convertiLista(lista, Messaggio.fromJson);
  }

  bool get eliminato => text == null && scheda == null;

  /// Testo per l'elenco delle chat, per esempio "Scheda: Forza"
  String get contenuto => text ?? 'Scheda: ${scheda!.nome}';

  /// true se l'ha scritto l'utente collegato: l'altro è [conPersona], così il confronto non dipende
  /// dallo username collegato, che può cambiare
  bool get mio => mittente != conPersona;

  Messaggio comeEliminato() {
    return Messaggio(id: id, conPersona: conPersona, mittente: mittente, text: null, createdAt: createdAt);
  }
}

/// Riga dell'elenco delle chat (ConversazioneResponseDto)
class Conversazione {
  /// L'altro utente della chat
  final String username;
  final Messaggio ultimoMessaggio;

  /// Messaggi dell'altro ancora da leggere
  final int nonLetti;

  /// Id dell'ultimo messaggio letto dall'altro: i propri fino a questo hanno la doppia spunta
  final int lettoDallAltro;

  const Conversazione({
    required this.username,
    required this.ultimoMessaggio,
    this.nonLetti = 0,
    this.lettoDallAltro = 0,
  });

  Conversazione.fromJson(Json json)
      : username = json['username'],
        ultimoMessaggio = Messaggio.fromJson(comeJson(json['ultimoMessaggio'])),
        nonLetti = json['nonLetti'],
        lettoDallAltro = json['lettoDallAltro'];

  static List<Conversazione> listaDaJson(dynamic lista) {
    return convertiLista(lista, Conversazione.fromJson);
  }

  Conversazione copia({Messaggio? ultimoMessaggio, int? nonLetti, int? lettoDallAltro}) {
    return Conversazione(
      username: username,
      ultimoMessaggio: ultimoMessaggio ?? this.ultimoMessaggio,
      nonLetti: nonLetti ?? this.nonLetti,
      lettoDallAltro: lettoDallAltro ?? this.lettoDallAltro,
    );
  }

  /// true se l'altro ha letto il proprio [messaggio]
  bool letto(Messaggio messaggio) {
    return messaggio.id <= lettoDallAltro;
  }

  /// Testo dell'ultimo messaggio nell'elenco, per esempio "Tu: Ciao"
  String get anteprima {
    if (ultimoMessaggio.eliminato) {
      return 'Messaggio eliminato';
    }
    if (ultimoMessaggio.mio) {
      return 'Tu: ${ultimoMessaggio.contenuto}';
    }
    return ultimoMessaggio.contenuto;
  }
}
