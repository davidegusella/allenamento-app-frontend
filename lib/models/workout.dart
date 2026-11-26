/// Modelli che rispecchiano i DTO del backend: una scheda (Plan) contiene giornate (Day),
/// che contengono esercizi (Exercise) con le loro serie (ExerciseSet).
/// L'app non li crea mai da sola: li riceve dal server, per questo hanno solo fromJson.
library;

import '../utils/formato.dart';

/// Oggetto JSON decodificato
typedef Json = Map<String, dynamic>;

/// Converte un elemento di una lista JSON, che Dart vede come dynamic, in [Json]
Json comeJson(dynamic elemento) {
  return Json.from(elemento as Map);
}

/// Converte una lista JSON in una lista di oggetti, con [converti] per ogni elemento
List<T> convertiLista<T>(dynamic lista, T Function(Json json) converti) {
  return [for (final elemento in lista) converti(comeJson(elemento))];
}

/// Data e ora del backend, in ISO 8601 e in UTC (per esempio "2026-10-17T08:30:00Z"), nel fuso del telefono
DateTime dataLocale(dynamic testo) {
  return DateTime.parse(testo as String).toLocal();
}

/// Serie di un esercizio con gli ultimi valori inseriti
class ExerciseSet {
  /// Numero della serie, da 1 in su
  final int number;
  final int reps;
  final num weight;

  ExerciseSet.fromJson(Json json)
      : number = json['number'],
        reps = json['reps'],
        weight = json['weight'];

  static List<ExerciseSet> listaDaJson(dynamic lista) {
    return convertiLista(lista, ExerciseSet.fromJson);
  }
}

/// Esercizio di una giornata con le sue serie. I limiti sono quelli delle costanti di Exercise nel backend
class Exercise {
  static const lunghezzaNome = Plan.lunghezzaNome;
  static const lunghezzaNote = 4000;
  static const recuperoMassimo = 7200;
  static const serieMassime = 50;
  static const ripetizioniMassime = 1000;

  final int id;
  final String name;
  final String weightMode;
  final int repsMin;
  final int repsMax;
  final int restSeconds;
  final String notes;
  final List<ExerciseSet> sets;

  Exercise.fromJson(Json json)
      : id = json['id'],
        name = json['name'],
        weightMode = json['weightMode'],
        repsMin = json['repsMin'],
        repsMax = json['repsMax'],
        restSeconds = json['restSeconds'],
        notes = json['notes'],
        sets = ExerciseSet.listaDaJson(json['sets']);

  static List<Exercise> listaDaJson(dynamic lista) {
    return convertiLista(lista, Exercise.fromJson);
  }

  /// Per esempio "3 serie × 8–10 ripetizioni": il numero di serie è quello delle righe salvate
  String get prescription {
    return '${sets.length} serie × ${rangeRipetizioni(repsMin, repsMax)} ripetizioni';
  }

  /// Per esempio "8–10 ripetizioni previste · kg per lato"
  String get previste {
    return '${rangeRipetizioni(repsMin, repsMax)} ripetizioni previste · ${etichettaCarico(weightMode)}';
  }
}

/// Serie di una sessione dello storico
class SerieSvolta {
  final int reps;
  final num weight;

  SerieSvolta.fromJson(Json json)
      : reps = json['reps'],
        weight = json['weight'];
}

/// Sessione dello storico di un esercizio: i valori salvati in un giorno
class Sessione {
  final DateTime date;
  final List<SerieSvolta> sets;

  /// Il backend invia solo il giorno, per esempio "2026-11-25"
  Sessione.fromJson(Json json)
      : date = DateTime.parse(json['date']),
        sets = convertiLista(json['sets'], SerieSvolta.fromJson);

  static List<Sessione> listaDaJson(dynamic lista) {
    return convertiLista(lista, Sessione.fromJson);
  }

  String get data {
    return dataItaliana(date);
  }

  /// Il carico più alto tra le serie, mostrato nel grafico dei progressi
  num get kgMassimo {
    return sets.fold<num>(0, (massimo, serie) => serie.weight > massimo ? serie.weight : massimo);
  }
}

/// Giornata di una scheda (Giorno 1, Giorno 2...)
class Day {
  final int id;
  final String name;
  final List<Exercise> exercises;

  Day.fromJson(Json json)
      : id = json['id'],
        name = json['name'],
        exercises = Exercise.listaDaJson(json['exercises']);

  static List<Day> listaDaJson(dynamic lista) {
    return convertiLista(lista, Day.fromJson);
  }
}

/// Scheda di allenamento, composta da più giornate
class Plan {
  /// Come WorkoutPlan.LUNGHEZZA_NOME nel backend, anche per giornate ed esercizi
  static const lunghezzaNome = 120;

  final int id;
  final String name;
  final DateTime createdAt;

  /// Username di chi ha pubblicato il post o inviato in chat la scheda copiata; null se creata dall'utente
  final String? importedFrom;

  /// Post con una versione più recente della scheda importata, pubblicata dallo stesso autore; altrimenti null
  final int? newVersionPostId;
  final List<Day> days;

  Plan.fromJson(Json json)
      : id = json['id'],
        name = json['name'],
        createdAt = dataLocale(json['createdAt']),
        importedFrom = json['importedFrom'],
        newVersionPostId = json['newVersionPostId'],
        days = Day.listaDaJson(json['days']);

  static List<Plan> listaDaJson(dynamic lista) {
    return convertiLista(lista, Plan.fromJson);
  }

  /// Data di creazione, per esempio "17/10/2026"
  String get data {
    return dataItaliana(createdAt);
  }

  /// Si pubblica o si invia in chat solo con almeno un esercizio, come controlla il backend
  bool get pubblicabile {
    return days.any((day) => day.exercises.isNotEmpty);
  }

  Day? giornata(int id) {
    return days.where((day) => day.id == id).firstOrNull;
  }
}
