import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/workout.dart';
import '../providers/workout_store.dart';
import '../theme/app_theme.dart';
import '../widgets/campi_form.dart';
import '../widgets/operazioni.dart';
import '../widgets/pannello_serie.dart';

/// Modifica di un esercizio (matita nella giornata): nome, serie da aggiungere, eliminare o cambiare,
/// recupero e nota. La modalità di carico resta quella scelta alla creazione
class ModificaEsercizioPage extends StatefulWidget {
  final Exercise exercise;

  const ModificaEsercizioPage({super.key, required this.exercise});

  @override
  State<ModificaEsercizioPage> createState() => _ModificaEsercizioPageState();
}

class _ModificaEsercizioPageState extends State<ModificaEsercizioPage> with OperazioneInCorso {
  final _form = GlobalKey<FormState>();
  late final ElencoSerie _serie = ElencoSerie(widget.exercise);
  late final _nome = TextEditingController(text: widget.exercise.name);
  late final _recupero = TextEditingController(text: '${widget.exercise.restSeconds}');
  late final _note = TextEditingController(text: widget.exercise.notes);

  @override
  void dispose() {
    _serie.dispose();
    _nome.dispose();
    _recupero.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _salva() async {
    if (!_form.currentState!.validate()) {
      return;
    }
    final store = context.read<WorkoutStore>();
    final salvato = await eseguiBloccando(() => store.salvaEsercizio(
          widget.exercise,
          serie: _serie.toJson(),
          nome: _nome.text.trim(),
          recupero: int.parse(_recupero.text),
          note: _note.text.trim(),
        ));
    if (salvato && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercise;
    final righe = _serie.righe;
    return Scaffold(
      appBar: AppBar(title: Text(exercise.name)),
      body: FormScorrevole(
        chiave: _form,
        children: [
          CampoNomeEsercizio(controller: _nome),
          Text(exercise.previste, style: testoSecondario),
          const SizedBox(height: 16),
          for (final (i, riga) in righe.indexed)
            PannelloSerie(
              // Lega il pannello alla sua riga: eliminando una serie centrale i valori non si scambiano
              key: ObjectKey(riga),
              numero: i + 1,
              riga: riga,
              weightMode: exercise.weightMode,
              mostraElimina: true,
              // Deve restare almeno una serie
              onElimina: righe.length == 1 ? null : () => setState(() => _serie.elimina(riga)),
            ),
          OutlinedButton.icon(
            onPressed: righe.length >= Exercise.serieMassime
                ? null
                : () => setState(() => _serie.aggiungiCopiaUltima(exercise.repsMin)),
            icon: const Icon(Icons.add),
            label: const Text('Aggiungi serie'),
          ),
          const SizedBox(height: 20),
          CampoRecupero(controller: _recupero),
          const SizedBox(height: 16),
          CampoNote(controller: _note),
          const SizedBox(height: 12),
          PulsanteInvio(testo: 'Salva', busy: busy, onPressed: _salva),
        ],
      ),
    );
  }
}
