import 'package:flutter/material.dart';

import '../models/workout.dart';
import '../theme/app_theme.dart';
import '../utils/formato.dart';
import 'pannelli.dart';

/// Scheda in sola lettura, anche di un altro utente: un riquadro per giornata con esercizi e serie
class VistaScheda extends StatelessWidget {
  final Plan plan;

  const VistaScheda({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final giornate = <Widget>[];
    for (final day in plan.days) {
      giornate.add(VistaGiornata(day: day));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: giornate);
  }
}

class VistaGiornata extends StatelessWidget {
  final Day day;

  const VistaGiornata({super.key, required this.day});

  @override
  Widget build(BuildContext context) {
    final righe = <Widget>[Text(day.name, style: Theme.of(context).textTheme.titleMedium)];
    if (day.exercises.isEmpty) {
      righe.add(const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Text('Nessun esercizio', style: testoSecondario),
      ));
    }
    for (final exercise in day.exercises) {
      righe.add(const Divider(height: 24));
      righe.add(VistaEsercizio(exercise: exercise));
    }
    return Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: righe));
  }
}

class VistaEsercizio extends StatelessWidget {
  final Exercise exercise;

  const VistaEsercizio({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    final righe = <Widget>[
      Text(exercise.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      Text('${exercise.prescription} · recupero ${exercise.restSeconds} s', style: testoSecondario),
    ];
    for (final serie in exercise.sets) {
      righe.add(Text(descriviSerie(serie.number, serie.reps, serie.weight, exercise.weightMode)));
    }
    if (exercise.notes.isNotEmpty) {
      righe.add(Padding(padding: const EdgeInsets.only(top: 4), child: Text(exercise.notes, style: testoSecondario)));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: righe);
  }
}
