import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/workout.dart';
import '../providers/workout_store.dart';
import '../theme/app_theme.dart';
import '../widgets/dialoghi.dart';
import '../widgets/operazioni.dart';
import '../widgets/pannelli.dart';
import 'day_page.dart';

/// Giornate di una scheda: si aggiungono, si riordinano, si rinominano e si eliminano.
/// Toccando una giornata si aprono i suoi esercizi
class PlanPage extends StatefulWidget {
  final int planId;

  const PlanPage({super.key, required this.planId});

  @override
  State<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends State<PlanPage> with OperazioneInCorso {
  WorkoutStore get _store => context.read<WorkoutStore>();

  Future<void> _nuovaGiornata(Plan plan) async {
    final nome = await chiediTesto(context, 'Nuova giornata', initial: 'Giorno ${plan.days.length + 1}');
    if (nome != null) {
      await _store.creaGiornata(plan.id, nome);
    }
  }

  Future<void> _rinomina(Day day) async {
    final nome = await chiediTesto(context, 'Nome della giornata', initial: day.name);
    if (nome != null) {
      await _store.rinominaGiornata(day.id, nome);
    }
  }

  Future<void> _elimina(Day day) {
    return seConfermato(context, 'Eliminare ${day.name}?', 'La giornata e i suoi esercizi verranno eliminati.',
        () => _store.eliminaGiornata(day.id));
  }

  @override
  Widget build(BuildContext context) {
    final plan = context.watch<WorkoutStore>().cercaScheda(widget.planId);
    if (plan == null) {
      return const PaginaEliminata(titolo: 'Scheda', messaggio: 'Scheda eliminata.');
    }

    final contenuto = <Widget>[
      if (plan.days.isEmpty) const EmptyState('Nessuna giornata', 'Aggiungi la prima giornata di lavoro della scheda.'),
      for (final (i, day) in plan.days.indexed)
        PannelloConAzioni(
          titolo: day.name,
          sottotitolo: '${day.exercises.length} esercizi',
          onApri: () => apriPagina(context, DayPage(planId: plan.id, dayId: day.id)),
          azioni: [
            ...azioniSpostamento(i, plan.days.length,
                (delta, abilitato) => azione(() => _store.spostaGiornata(plan, i, i + delta), abilitato: abilitato)),
            AzionePannello('Rinomina giornata', Icons.edit_outlined, azione(() => _rinomina(day))),
            AzionePannello('Elimina giornata', Icons.delete_outline, azione(() => _elimina(day))),
          ],
        ),
      OutlinedButton.icon(
        onPressed: azione(() => _nuovaGiornata(plan)),
        icon: const Icon(Icons.add),
        label: const Text('Aggiungi giornata'),
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(plan.name)),
      body: ListView(padding: marginePagina, children: contenuto),
    );
  }
}
