import 'package:flutter/foundation.dart';

import '../models/commento.dart';
import '../models/post.dart';
import '../models/utente.dart';
import '../models/workout.dart';
import '../services/api_service.dart';
import '../services/archivio_token.dart';

/// Stato condiviso dell'app: l'utente collegato, le sue schede e i post caricati.
/// Ogni modifica alle schede ricarica l'elenco da GET /plans, così l'app resta allineata al server.
class WorkoutStore extends ChangeNotifier {
  final ApiService api;
  final ArchivioToken _archivio;

  bool _booting = true;
  String? _error;
  Utente? _utente;
  List<Plan> _plans = [];
  List<Post> _perTe = [];

  /// I post dell'utente collegato per ogni classifica della Bacheca
  final Map<OrdineClassifica, List<Post>> bacheca = {for (final ordine in OrdineClassifica.values) ordine: []};

  /// I post di tutti per ogni classifica della voce Classifica
  final Map<OrdineClassifica, List<Post>> classifica = {for (final ordine in OrdineClassifica.values) ordine: []};

  /// Post aperti fuori dagli elenchi (per esempio la versione nuova di una scheda), per id
  final Map<int, Post> postAperti = {};

  /// Commenti per id del post; manca la chiave se non sono ancora stati caricati
  final Map<int, List<Commento>> commenti = {};

  WorkoutStore({ApiService? api, ArchivioToken? archivio})
      : api = api ?? ApiService(),
        _archivio = archivio ?? ArchivioTokenSicuro();

  /// true finché [avvia] non ha finito
  bool get booting => _booting;

  /// Errore dell'ultimo caricamento delle schede, mostrato con "Riprova"
  String? get error => _error;

  /// null finché l'utente non fa accesso e dopo che esce
  Utente? get utente => _utente;
  List<Plan> get plans => _plans;
  List<Post> get perTe => _perTe;

  /// Dati già caricati, per i test delle pagine
  @visibleForTesting
  void impostaPerTest({Utente? utente, List<Plan>? plans, List<Post>? perTe}) {
    _utente = utente ?? _utente;
    _plans = plans ?? _plans;
    _perTe = perTe ?? _perTe;
    notifyListeners();
  }

  /// Primo caricamento all'avvio. Con un token salvato controlla che sia ancora valido e scarica le schede:
  /// - token assente, scaduto o non valido: [utente] resta null e si vede la pagina di accesso
  /// - backend non raggiungibile: l'errore resta in [error] e si vede la pagina di connessione
  Future<void> avvia() async {
    try {
      final token = await _leggiTokenSalvato();
      if (token != null) {
        api.token = token;
        _utente = Utente.fromJson(comeJson(await api.request('GET', '/auth/me')));
        await ricarica();
      }
    } on ApiFailure catch (e) {
      if (e.status == 401) {
        await _dimentica();
      } else {
        _error = e.toString();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _booting = false;
      notifyListeners();
    }
  }

  Future<String?> _leggiTokenSalvato() async {
    try {
      return await _archivio.leggi();
    } catch (e) {
      // Se il portachiavi non è leggibile l'utente rifà semplicemente l'accesso
      return null;
    }
  }

  /// Lancia [ApiFailure] se le credenziali sono sbagliate o il server non risponde
  Future<void> accedi(String email, String password) async {
    await _collega(await api.request('POST', '/auth/login', {'email': email, 'password': password}));
  }

  /// "Password dimenticata?": il backend non verifica l'identità, per scelta (vedi AuthServiceImpl)
  Future<void> reimpostaPassword(String email, String password) async {
    await api.request('POST', '/auth/reset-password', {'email': email, 'password': password});
  }

  /// Lancia [ApiFailure] se username o email sono già usati o il server non risponde
  Future<void> registrati(String username, String email, String password) async {
    final dati = {'username': username, 'email': email, 'password': password};
    await _collega(await api.request('POST', '/auth/register', dati));
  }

  /// Salva token e utente di accesso o registrazione, poi scarica le schede.
  /// Se lo scaricamento fallisce l'utente resta collegato: la home mostra l'errore con "Riprova"
  Future<void> _collega(dynamic json) async {
    final risposta = comeJson(json);
    final token = risposta['token'] as String;
    api.token = token;
    _utente = Utente.fromJson(comeJson(risposta['user']));
    _plans = [];
    _error = null;
    try {
      await _archivio.salva(token);
    } catch (e) {
      // Senza portachiavi l'accesso vale solo finché l'app resta aperta
    }
    try {
      await ricarica();
    } catch (e) {
      // L'errore è già in [error]
    }
  }

  /// Esce dall'account: l'app torna alla pagina di accesso
  Future<void> esci() async {
    await _dimentica();
    notifyListeners();
  }

  /// Dimentica utente, token e dati, senza avvisare le pagine
  Future<void> _dimentica() async {
    api.token = null;
    _utente = null;
    _plans = [];
    _svuotaPost();
    _error = null;
    try {
      await _archivio.cancella();
    } catch (e) {
      // Il token in memoria è già stato tolto: al prossimo avvio verrà rifiutato o riletto
    }
  }

  /// Le pagine ricaricano post e commenti quando si aprono
  void _svuotaPost() {
    _perTe = [];
    bacheca.updateAll((ordine, post) => []);
    classifica.updateAll((ordine, post) => []);
    commenti.clear();
    postAperti.clear();
  }

  /// I post caricati hanno il vecchio username, che serve a riconoscere i propri ([eMio]): si ricaricano.
  /// Se il ricaricamento fallisce l'account è comunque cambiato e gli elenchi si aggiornano trascinandoli
  /// Lancia [ApiFailure] se username o email sono di un altro utente.
  Future<void> modificaAccount(String username, String email) async {
    final json = await richiestaUtente('PUT', '/account', {'username': username, 'email': email});
    _utente = Utente.fromJson(comeJson(json));
    _svuotaPost();
    notifyListeners();
    try {
      await caricaPerTe();
      await _caricaTutte(caricaBacheca);
      await _caricaTutte(caricaClassifica);
    } on ApiFailure {
      // Gli elenchi restano vuoti finché non vengono ricaricati
    }
  }

  /// Lancia [ApiFailure] se la password è uguale a quella attuale
  Future<void> cambiaPassword(String password) async {
    await richiestaUtente('PUT', '/account/password', {'password': password});
  }

  Future<void> eliminaAccount() async {
    await richiestaUtente('DELETE', '/account');
    await esci();
  }

  /// Richiesta dell'utente collegato. Un 401 vuol dire token scaduto o non più valido:
  /// esce dall'account, così l'app torna alla pagina di accesso
  Future<dynamic> richiestaUtente(String method, String path, [Object? body]) async {
    try {
      return await api.request(method, path, body);
    } on ApiFailure catch (e) {
      if (e.status == 401) {
        await esci();
        throw ApiFailure('Sessione scaduta. Accedi di nuovo.', 401);
      }
      rethrow;
    }
  }

  /// Scarica di nuovo le schede con giornate, esercizi e serie
  Future<void> ricarica() async {
    try {
      _plans = Plan.listaDaJson(await richiestaUtente('GET', '/plans'));
      _error = null;
    } on ApiFailure catch (e) {
      // Con la sessione scaduta si torna alla pagina di accesso: non serve l'avviso nella home
      if (e.status != 401) {
        _error = e.toString();
      }
      rethrow;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  /// Modifica una scheda, una giornata o un esercizio e ricarica le schede
  Future<dynamic> _modifica(String method, String path, [Object? body]) async {
    final risposta = await richiestaUtente(method, path, body);
    await ricarica();
    return risposta;
  }

  Future<void> creaScheda(String nome) => _modifica('POST', '/plans', {'name': nome});

  Future<void> rinominaScheda(int id, String nome) => _modifica('PUT', '/plans/$id', {'name': nome});

  /// Il backend elimina anche tutti i post della scheda, che spariscono dalla Bacheca ricaricandola
  Future<void> eliminaScheda(int id) async {
    await _modifica('DELETE', '/plans/$id');
    postAperti.clear();
    await _caricaTutte(caricaBacheca);
  }

  Future<void> creaGiornata(int planId, String nome) => _modifica('POST', '/plans/$planId/days', {'name': nome});

  Future<void> rinominaGiornata(int id, String nome) => _modifica('PUT', '/days/$id', {'name': nome});

  Future<void> eliminaGiornata(int id) => _modifica('DELETE', '/days/$id');

  Future<void> spostaGiornata(Plan plan, int da, int a) {
    return _riordina('/plans/${plan.id}/day-order', [for (final day in plan.days) day.id], da, a);
  }

  /// Ogni serie parte da [repsMin] ripetizioni e da [carico]
  Future<void> aggiungiEsercizio(
    int dayId, {
    required String nome,
    required String weightMode,
    required int serie,
    required int repsMin,
    required int repsMax,
    required num carico,
    required int recupero,
    required String note,
  }) {
    return _modifica('POST', '/days/$dayId/exercises', {
      'name': nome,
      'weightMode': weightMode,
      'setCount': serie,
      'repsMin': repsMin,
      'repsMax': repsMax,
      'targetWeight': carico,
      'restSeconds': recupero,
      'notes': note,
    });
  }

  /// [serie] sostituiscono quelle salvate; nome, recupero e note restano quelli attuali se non indicati,
  /// perché il backend li vuole sempre tutti
  Future<void> salvaEsercizio(
    Exercise exercise, {
    required List<Map<String, Object>> serie,
    String? nome,
    int? recupero,
    String? note,
  }) {
    return _modifica('PUT', '/exercises/${exercise.id}', {
      'name': nome ?? exercise.name,
      'restSeconds': recupero ?? exercise.restSeconds,
      'notes': note ?? exercise.notes,
      'sets': serie,
    });
  }

  Future<void> eliminaEsercizio(int id) => _modifica('DELETE', '/exercises/$id');

  Future<void> spostaEsercizio(Day day, int da, int a) {
    return _riordina('/days/${day.id}/exercise-order', [for (final exercise in day.exercises) exercise.id], da, a);
  }

  /// Sposta l'elemento in posizione [da] alla posizione [a] e invia il nuovo ordine di [ids]
  Future<void> _riordina(String path, List<int> ids, int da, int a) async {
    final nuovoOrdine = List<int>.from(ids);
    nuovoOrdine.insert(a, nuovoOrdine.removeAt(da));
    await _modifica('PUT', path, {'ids': nuovoOrdine});
  }

  /// "Per te", le classifiche della Bacheca e quelle della Classifica
  Iterable<List<Post>> get _elenchi => [_perTe, ...bacheca.values, ...classifica.values];

  Future<void> caricaPerTe() async {
    _perTe = Post.listaDaJson(await richiestaUtente('GET', '/posts/per-te'));
    notifyListeners();
  }

  Future<void> caricaBacheca(OrdineClassifica ordine) => _caricaClassifica(bacheca, '/posts/mine', ordine);

  Future<void> caricaClassifica(OrdineClassifica ordine) => _caricaClassifica(classifica, '/posts/classifica', ordine);

  Future<void> _caricaClassifica(
      Map<OrdineClassifica, List<Post>> elenchi, String path, OrdineClassifica ordine) async {
    elenchi[ordine] = Post.listaDaJson(await richiestaUtente('GET', '$path?ordine=${ordine.parametro}'));
    notifyListeners();
  }

  Future<void> _caricaTutte(Future<void> Function(OrdineClassifica ordine) carica) async {
    for (final ordine in OrdineClassifica.values) {
      await carica(ordine);
    }
  }

  /// Le sessioni dello storico dell'esercizio, dalla più recente
  Future<List<Sessione>> caricaStorico(int exerciseId) async {
    return Sessione.listaDaJson(await richiestaUtente('GET', '/exercises/$exerciseId/history'));
  }

  /// Pubblica una copia della scheda così com'è adesso: compare nella Bacheca e in "Per te" degli altri
  Future<void> pubblica(int planId) async {
    await richiestaUtente('POST', '/plans/$planId/publish');
    await _caricaTutte(caricaBacheca);
  }

  /// Copia la scheda del post tra le proprie, oppure sostituisce la propria copia [sostituisci].
  /// Si ricaricano anche "Per te" e il post aperto: importazioni e copia del post cambiano
  Future<void> importa(int postId, {int? sostituisci}) async {
    final query = sostituisci == null ? '' : '?replace=$sostituisci';
    await _modifica('POST', '/posts/$postId/import$query');
    await caricaPerTe();
    if (postAperti.containsKey(postId)) {
      await caricaPost(postId);
    }
  }

  /// Copia tra le proprie la scheda personale ricevuta nel messaggio [messaggioId]
  Future<void> importaDaChat(int messaggioId) => _modifica('POST', '/chat/messaggi/$messaggioId/import');

  /// Le copie importate dagli altri restano
  Future<void> eliminaPost(int id) async {
    await richiestaUtente('DELETE', '/posts/$id');
    for (final elenco in _elenchi) {
      elenco.removeWhere((post) => post.id == id);
    }
    postAperti.remove(id);
    commenti.remove(id);
    notifyListeners();
  }

  /// Il post, salvato anche in [postAperti]
  Future<Post> caricaPost(int id) async {
    final post = await _leggiPost(id);
    postAperti[id] = post;
    notifyListeners();
    return post;
  }

  Future<Post> _leggiPost(int id) async {
    return Post.fromJson(comeJson(await richiestaUtente('GET', '/posts/$id')));
  }

  bool eMio(Post post) {
    return utente?.username == post.author;
  }

  /// Mette o toglie il like, secondo lo stato attuale del post
  Future<void> cambiaLike(Post post) async {
    final json = await richiestaUtente(post.likedByMe ? 'DELETE' : 'PUT', '/posts/${post.id}/like');
    _sostituisciPost(Post.fromJson(comeJson(json)));
  }

  /// Aggiorna il post in tutti gli elenchi senza cambiarne l'ordine: la classifica si riordina al prossimo
  /// caricamento
  void _sostituisciPost(Post aggiornato) {
    if (postAperti.containsKey(aggiornato.id)) {
      postAperti[aggiornato.id] = aggiornato;
    }
    for (final elenco in _elenchi) {
      for (int i = 0; i < elenco.length; i++) {
        if (elenco[i].id == aggiornato.id) {
          elenco[i] = aggiornato;
        }
      }
    }
    notifyListeners();
  }

  Future<void> caricaCommenti(int postId) async {
    commenti[postId] = Commento.listaDaJson(await richiestaUtente('GET', '/posts/$postId/comments'));
    notifyListeners();
  }

  Future<void> commenta(int postId, String testo) async {
    await richiestaUtente('POST', '/posts/$postId/comments', {'text': testo});
    await _commentiCambiati(postId);
  }

  Future<void> eliminaCommento(int postId, int commentoId) async {
    await richiestaUtente('DELETE', '/comments/$commentoId');
    await _commentiCambiati(postId);
  }

  /// Ricarica commenti e post, così anche il numero di commenti sulle card è aggiornato
  Future<void> _commentiCambiati(int postId) async {
    await caricaCommenti(postId);
    _sostituisciPost(await _leggiPost(postId));
  }

  /// Il post negli elenchi o tra quelli aperti, oppure null
  Post? cercaPost(int id) {
    return _elenchi.expand((elenco) => elenco).where((post) => post.id == id).firstOrNull ?? postAperti[id];
  }

  /// La scheda, oppure null se non esiste più
  Plan? cercaScheda(int id) {
    return _plans.where((plan) => plan.id == id).firstOrNull;
  }

  @override
  void dispose() {
    api.dispose();
    super.dispose();
  }
}
