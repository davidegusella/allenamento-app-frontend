import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/workout.dart';
import '../providers/workout_store.dart';
import '../theme/app_theme.dart';
import '../widgets/dialoghi.dart';
import '../widgets/operazioni.dart';
import '../widgets/pannelli.dart';
import 'esercizio_page.dart';
import 'modifica_esercizio_page.dart';
import 'nuovo_esercizio_page.dart';

/// Esercizi di una giornata: si aggiungono, si riordinano, si modificano e si eliminano.
/// Toccando un esercizio si apre la sua pagina con le serie e il timer di recupero
class DayPage extends StatefulWidget {
  final int planId;
  final int dayId;

  const DayPage({super.key, required this.planId, required this.dayId});

  @override
  State<DayPage> createState() => _DayPageState();
}

class _DayPageState extends State<DayPage> with OperazioneInCorso {
  WorkoutStore get _store => context.read<WorkoutStore>();

  Future<void> _elimina(Exercise exercise) {
    return seConfermato(context, 'Eliminare ${exercise.name}?',
        'L\'esercizio e le sue serie verranno eliminati dalla giornata.', () => _store.eliminaEsercizio(exercise.id));
  }

  @override
  Widget build(BuildContext context) {
    // Scheda e giornata possono essere state eliminate mentre la pagina era aperta
    final plan = context.watch<WorkoutStore>().cercaScheda(widget.planId);
    final day = plan?.giornata(widget.dayId);
    if (plan == null || day == null) {
      return const PaginaEliminata(titolo: 'Giornata', messaggio: 'Giornata eliminata.');
    }

    final contenuto = <Widget>[
      if (day.exercises.isEmpty) const EmptyState('Giornata vuota', 'Aggiungi il primo esercizio della giornata.'),
      for (final (i, exercise) in day.exercises.indexed)
        PannelloConAzioni(
          titolo: exercise.name,
          sottotitolo: exercise.prescription,
          onApri: () => apriPagina(context, EsercizioPage(exercise: exercise)),
          azioni: [
            ...azioniSpostamento(i, day.exercises.length,
                (delta, abilitato) => azione(() => _store.spostaEsercizio(day, i, i + delta), abilitato: abilitato)),
            AzionePannello('Modifica esercizio', Icons.edit_outlined,
                () => apriPagina(context, ModificaEsercizioPage(exercise: exercise))),
            AzionePannello('Elimina esercizio', Icons.delete_outline, azione(() => _elimina(exercise))),
          ],
        ),
      OutlinedButton.icon(
        onPressed: () => apriPagina(context, NuovoEsercizioPage(dayId: day.id)),
        icon: const Icon(Icons.add),
        label: const Text('Aggiungi esercizio'),
      ),
    ];
    return Scaffold(
      // Per esempio "Forza: Giorno 1"; un testo troppo lungo finisce con i puntini
      appBar: AppBar(title: Text('${plan.name}: ${day.name}')),
      body: ListView(padding: marginePagina, children: contenuto),
    );
  }
}
