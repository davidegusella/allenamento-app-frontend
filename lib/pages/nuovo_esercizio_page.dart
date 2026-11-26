import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/workout.dart';
import '../providers/workout_store.dart';
import '../utils/formato.dart';
import '../widgets/campi_form.dart';
import '../widgets/operazioni.dart';

/// Nuovo esercizio di una giornata: nome, modalità di carico, numero di serie, ripetizioni minime e massime,
/// carico previsto, recupero e nota. Ogni serie parte dalle ripetizioni minime e dal carico previsto
class NuovoEsercizioPage extends StatefulWidget {
  final int dayId;

  const NuovoEsercizioPage({super.key, required this.dayId});

  @override
  State<NuovoEsercizioPage> createState() => _NuovoEsercizioPageState();
}

class _NuovoEsercizioPageState extends State<NuovoEsercizioPage> with OperazioneInCorso {
  final _form = GlobalKey<FormState>();
  // Valori proposti: 3 serie da 8–10 ripetizioni con 120 secondi di recupero
  final _nome = TextEditingController();
  final _serie = TextEditingController(text: '3');
  final _min = TextEditingController(text: '8');
  final _max = TextEditingController(text: '10');
  final _carico = TextEditingController();
  final _recupero = TextEditingController(text: '120');
  final _note = TextEditingController();
  String _modalita = 'TOTAL';

  @override
  void dispose() {
    for (final campo in [_nome, _serie, _min, _max, _carico, _recupero, _note]) {
      campo.dispose();
    }
    super.dispose();
  }

  Future<void> _salva() async {
    if (!_form.currentState!.validate()) {
      return;
    }
    if (int.parse(_max.text) < int.parse(_min.text)) {
      mostraErrore(context, 'Il massimo deve essere almeno il minimo.');
      return;
    }
    final store = context.read<WorkoutStore>();
    final salvato = await eseguiBloccando(() => store.aggiungiEsercizio(
          widget.dayId,
          nome: _nome.text.trim(),
          weightMode: _modalita,
          serie: int.parse(_serie.text),
          repsMin: int.parse(_min.text),
          repsMax: int.parse(_max.text),
          carico: parsePeso(_carico.text),
          recupero: int.parse(_recupero.text),
          note: _note.text.trim(),
        ));
    if (salvato && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    CampoIntero ripetizioni(String etichetta, TextEditingController controller) {
      return CampoIntero(etichetta: etichetta, controller: controller, minimo: 1, massimo: Exercise.ripetizioniMassime);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Nuovo esercizio')),
      body: FormScorrevole(
        chiave: _form,
        children: [
          CampoNomeEsercizio(controller: _nome),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _modalita,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Come registri il carico?'),
            items: [
              for (final modalita in modalitaPeso)
                DropdownMenuItem(value: modalita, child: Text(etichettaCarico(modalita))),
            ],
            onChanged: (valore) => setState(() => _modalita = valore!),
          ),
          const SizedBox(height: 16),
          CampoIntero(etichetta: 'Numero di serie', controller: _serie, minimo: 1, massimo: Exercise.serieMassime),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: ripetizioni('Ripetizioni min', _min)),
              const SizedBox(width: 12),
              Expanded(child: ripetizioni('Ripetizioni max', _max)),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _carico,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: 'Carico previsto (${etichettaCarico(_modalita)})'),
            validator: validaPeso,
          ),
          const SizedBox(height: 16),
          CampoRecupero(controller: _recupero),
          const SizedBox(height: 16),
          CampoNote(controller: _note),
          const SizedBox(height: 12),
          PulsanteInvio(testo: 'Salva esercizio', busy: busy, onPressed: _salva),
        ],
      ),
    );
  }
}
