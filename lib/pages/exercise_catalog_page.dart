import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/workout.dart';
import '../providers/workout_store.dart';
import '../theme/app_theme.dart';
import '../utils/formato.dart';
import '../widgets/pannelli.dart';

/// Scheda "Esercizi" di "Le mie": in sola lettura gli esercizi delle giornate di tutte le schede,
/// senza ripetizioni e in ordine alfabetico. Si gestiscono dalle giornate
class ExerciseCatalogPage extends StatelessWidget {
  const ExerciseCatalogPage({super.key});

  /// Due esercizi sono lo stesso se hanno uguali nome (senza distinguere maiuscole e minuscole),
  /// modalità di carico, numero di serie e ripetizioni; per esempio "panca|PER_SIDE|3|8|10"
  String _chiave(Exercise exercise) {
    final nome = exercise.name.trim().toLowerCase();
    return '$nome|${exercise.weightMode}|${exercise.sets.length}|${exercise.repsMin}|${exercise.repsMax}';
  }

  List<Exercise> _esercizi(List<Plan> plans) {
    final giaAggiunti = <String>{};
    final esercizi = [
      for (final plan in plans)
        for (final day in plan.days)
          for (final exercise in day.exercises)
            if (giaAggiunti.add(_chiave(exercise))) exercise,
    ];
    return esercizi..sort((primo, secondo) => primo.name.toLowerCase().compareTo(secondo.name.toLowerCase()));
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WorkoutStore>();
    final esercizi = _esercizi(store.plans);
    return ListView(
      padding: marginePagina,
      children: [
        if (esercizi.isEmpty)
          const EmptyState('Nessun esercizio', 'Gli esercizi aggiunti alle giornate delle schede compaiono qui.'),
        for (final exercise in esercizi)
          Panel(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(exercise.name),
              subtitle: Text('${exercise.prescription} · ${etichettaCarico(exercise.weightMode)}'),
            ),
          ),
      ],
    );
  }
}
