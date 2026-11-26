/// Dati JSON di prova, nello stesso formato restituito dal backend.
library;

/// L'utente "davide" collegato nei test
Map<String, dynamic> utenteDiProva() {
  return {'id': 1, 'username': 'davide', 'email': 'davide@example.com'};
}

/// Esercizio con [serie] serie da [reps] ripetizioni e [kg] kg
Map<String, dynamic> esercizioDiProva(int id, String name,
    {int serie = 3, int min = 8, int max = 10, int reps = 8, num kg = 20, String weightMode = 'TOTAL'}) {
  final sets = <Map<String, dynamic>>[];
  for (int i = 0; i < serie; i++) {
    sets.add({'id': id * 100 + i, 'number': i + 1, 'reps': reps, 'weight': kg});
  }
  return {
    'id': id,
    'name': name,
    'weightMode': weightMode,
    'repsMin': min,
    'repsMax': max,
    'restSeconds': 120,
    'notes': 'Nota tecnica',
    'sets': sets,
  };
}

/// Scheda con una giornata per ogni lista di esercizi in [giornate]
Map<String, dynamic> schedaDiProva(int id, String name, List<List<Map<String, dynamic>>> giornate,
    {String createdAt = '2026-10-17T08:00:00Z', String? importedFrom, int? importedPostId, int? newVersionPostId}) {
  final days = <Map<String, dynamic>>[];
  for (int i = 0; i < giornate.length; i++) {
    days.add({'id': id * 10 + i, 'name': 'Giorno ${i + 1}', 'exercises': giornate[i]});
  }
  return {
    'id': id,
    'name': name,
    'createdAt': createdAt,
    'importedFrom': importedFrom,
    'importedPostId': importedPostId,
    'newVersionPostId': newVersionPostId,
    'days': days,
  };
}

/// Scheda "Forza" con una giornata e una Panca per lato da 10 × 20 kg
Map<String, dynamic> forza({String? importedFrom}) {
  final panca = esercizioDiProva(7, 'Panca', serie: 1, reps: 10, kg: 20, weightMode: 'PER_SIDE');
  return schedaDiProva(
      1,
      'Forza',
      [
        [panca],
      ],
      importedFrom: importedFrom);
}

/// Post di [author] con la copia di [scheda]
Map<String, dynamic> postDiProva(int id, String author, Map<String, dynamic> scheda,
    {int importCount = 0,
    int likeCount = 0,
    int commentCount = 0,
    bool likedByMe = false,
    int? myCopyPlanId,
    int? myCopyPostId}) {
  return {
    'id': id,
    'author': author,
    'createdAt': '2026-11-20T09:00:00Z',
    'importCount': importCount,
    'likeCount': likeCount,
    'commentCount': commentCount,
    'likedByMe': likedByMe,
    'myCopyPlanId': myCopyPlanId,
    'myCopyPostId': myCopyPostId,
    'plan': scheda,
  };
}

/// Commento di [author]
Map<String, dynamic> commentoDiProva(int id, String author, String text) {
  return {'id': id, 'author': author, 'text': text, 'createdAt': '2026-11-21T09:00:00Z'};
}

/// Messaggio della chat con [conPersona], scritto da [mittente]
Map<String, dynamic> messaggioDiProva(int id, String conPersona, String mittente, String? text) {
  return {
    'id': id,
    'conPersona': conPersona,
    'mittente': mittente,
    'text': text,
    'eliminato': text == null,
    'createdAt': '2026-11-21T09:00:00Z',
  };
}

/// Riga dell'elenco delle chat con [username]
Map<String, dynamic> conversazioneDiProva(
  String username,
  Map<String, dynamic> ultimoMessaggio, {
  int nonLetti = 0,
  int lettoDallAltro = 0,
}) {
  return {
    'username': username,
    'ultimoMessaggio': ultimoMessaggio,
    'nonLetti': nonLetti,
    'lettoDallAltro': lettoDallAltro,
  };
}

/// Messaggio della chat con [conPersona] in cui [mittente] invia una scheda personale ([planId]) o un post ([postId])
Map<String, dynamic> messaggioSchedaDiProva(int id, String conPersona, String mittente, String nome,
    {int? planId, int? postId}) {
  return {
    ...messaggioDiProva(id, conPersona, mittente, null),
    'eliminato': false,
    'scheda': {'planId': planId, 'postId': postId, 'nome': nome, 'autore': mittente},
  };
}
