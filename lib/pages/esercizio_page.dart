import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/workout.dart';
import '../providers/workout_store.dart';
import '../services/avviso_timer.dart';
import '../theme/app_theme.dart';
import '../widgets/campi_form.dart';
import '../widgets/operazioni.dart';
import '../widgets/pannelli.dart';
import '../widgets/pannello_serie.dart';
import '../widgets/timer_recupero.dart';
import 'storico_esercizio_page.dart';

/// Pagina di un esercizio durante l'allenamento: ripetizioni e kg di ogni serie, sempre con gli ultimi valori
/// salvati, e il timer di recupero. Ogni salvataggio aggiorna anche la sessione di oggi dello storico.
/// Le serie si aggiungono o eliminano dalla pagina di modifica
class EsercizioPage extends StatefulWidget {
  final Exercise exercise;

  /// Suono e schermo del timer; nei test una versione finta
  final AvvisoTimer? avviso;

  const EsercizioPage({super.key, required this.exercise, this.avviso});

  @override
  State<EsercizioPage> createState() => _EsercizioPageState();
}

class _EsercizioPageState extends State<EsercizioPage> with OperazioneInCorso {
  final _form = GlobalKey<FormState>();
  late final ElencoSerie _serie = ElencoSerie(widget.exercise);

  @override
  void dispose() {
    _serie.dispose();
    super.dispose();
  }

  /// Resta su questa pagina, così il timer non si interrompe
  Future<void> _salva() async {
    if (!_form.currentState!.validate()) {
      return;
    }
    final store = context.read<WorkoutStore>();
    if (await eseguiBloccando(() => store.salvaEsercizio(widget.exercise, serie: _serie.toJson())) && mounted) {
      mostraMessaggio(context, 'Valori salvati');
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercise;
    return Scaffold(
      appBar: AppBar(
        title: Text(exercise.name),
        actions: [
          IconButton(
            tooltip: 'Storico',
            icon: const Icon(Icons.show_chart),
            onPressed: () => apriPagina(context, StoricoEsercizioPage(exercise: exercise)),
          ),
        ],
      ),
      body: FormScorrevole(
        chiave: _form,
        children: [
          Text(exercise.previste, style: testoSecondario),
          const SizedBox(height: 16),
          if (exercise.notes.isNotEmpty)
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Note tecniche', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(exercise.notes, style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          for (final (i, riga) in _serie.righe.indexed)
            PannelloSerie(numero: i + 1, riga: riga, weightMode: exercise.weightMode),
          PulsanteInvio(testo: 'Salva', busy: busy, onPressed: _salva),
          const SizedBox(height: 24),
          Panel(child: TimerRecupero(secondiIniziali: exercise.restSeconds, avviso: widget.avviso)),
        ],
      ),
    );
  }
}
