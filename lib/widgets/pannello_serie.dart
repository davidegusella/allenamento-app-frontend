import 'package:flutter/material.dart';

import '../models/workout.dart';
import '../utils/formato.dart';
import 'pannelli.dart';

/// Campi di testo di una serie: aggiungere o eliminare una serie aggiunge o toglie una sola riga
class RigaSerie {
  final TextEditingController reps;
  final TextEditingController weight;

  RigaSerie(int reps, num weight)
      : reps = TextEditingController(text: '$reps'),
        weight = TextEditingController(text: formattaNumero(weight));

  /// Da usare solo dopo aver validato il form, per esempio { "reps": 10, "weight": 20.5 }
  Map<String, Object> toJson() {
    return {'reps': int.parse(reps.text), 'weight': parsePeso(weight.text)};
  }

  void dispose() {
    reps.dispose();
    weight.dispose();
  }
}

/// Serie di un esercizio mentre l'utente le modifica, comuni alla pagina dell'esercizio e a quella di modifica
class ElencoSerie {
  final List<RigaSerie> righe;

  /// Parte dagli ultimi valori salvati
  ElencoSerie(Exercise exercise) : righe = [for (final serie in exercise.sets) RigaSerie(serie.reps, serie.weight)];

  /// Aggiunge in fondo una serie con i valori dell'ultima; [repsPredefinite] se l'ultima non ha un numero valido
  void aggiungiCopiaUltima(int repsPredefinite) {
    final ultima = righe.last;
    righe.add(RigaSerie(int.tryParse(ultima.reps.text) ?? repsPredefinite, leggiPeso(ultima.weight.text) ?? 0));
  }

  void elimina(RigaSerie riga) {
    righe.remove(riga);
    riga.dispose();
  }

  /// Da usare solo dopo aver validato il form
  List<Map<String, Object>> toJson() {
    return [for (final riga in righe) riga.toJson()];
  }

  void dispose() {
    for (final riga in righe) {
      riga.dispose();
    }
  }
}

/// Pannello "Serie N" con i campi ripetizioni e kg; nella pagina di modifica anche il cestino
class PannelloSerie extends StatelessWidget {
  final int numero;
  final RigaSerie riga;
  final String weightMode;

  final bool mostraElimina;

  /// Funzione del cestino; null lo mostra disabilitato
  final VoidCallback? onElimina;

  const PannelloSerie({
    super.key,
    required this.numero,
    required this.riga,
    required this.weightMode,
    this.mostraElimina = false,
    this.onElimina,
  });

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Serie $numero', style: Theme.of(context).textTheme.titleMedium)),
              if (mostraElimina)
                IconButton(
                  tooltip: 'Elimina serie',
                  onPressed: onElimina,
                  icon: const Icon(Icons.delete_outline, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: riga.reps,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Ripetizioni'),
                  validator: (valore) => validaIntero(valore, 0, Exercise.ripetizioniMassime),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: riga.weight,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: etichettaCarico(weightMode)),
                  validator: validaPeso,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
