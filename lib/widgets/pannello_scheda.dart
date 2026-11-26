import 'package:flutter/material.dart';

import '../models/workout.dart';
import '../utils/formato.dart';
import 'pannelli.dart';

/// Card di una scheda nella pagina Schede: data, giornate, eventuale autore da cui è stata copiata,
/// l'avviso di una versione nuova e i pulsanti pubblica, invia in chat, rinomina ed elimina
class PannelloScheda extends StatelessWidget {
  final Plan plan;
  final VoidCallback onApri;
  final VoidCallback? onPubblica;
  final VoidCallback? onInvia;
  final VoidCallback? onRinomina;
  final VoidCallback? onElimina;

  /// Apre la versione nuova della scheda importata; serve solo se [Plan.newVersionPostId] esiste
  final VoidCallback? onNuovaVersione;

  const PannelloScheda({
    super.key,
    required this.plan,
    required this.onApri,
    required this.onPubblica,
    required this.onInvia,
    required this.onRinomina,
    required this.onElimina,
    this.onNuovaVersione,
  });

  @override
  Widget build(BuildContext context) {
    var dettagli = 'Creata il ${plan.data} · ${conteggio(plan.days.length, 'giornata', 'giornate')}';
    final autore = plan.importedFrom;
    if (autore != null) {
      dettagli += '\nda @$autore';
    }

    return PannelloConAzioni(
      titolo: plan.name,
      sottotitolo: dettagli,
      onApri: onApri,
      extra: [
        if (plan.newVersionPostId != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onNuovaVersione,
              icon: const Icon(Icons.new_releases_outlined, size: 18),
              label: Text('Nuova versione di @$autore disponibile'),
            ),
          ),
      ],
      azioni: [
        AzionePannello('Pubblica', Icons.ios_share, onPubblica),
        AzionePannello('Invia in chat', Icons.send_outlined, onInvia),
        AzionePannello('Rinomina scheda', Icons.edit_outlined, onRinomina),
        AzionePannello('Elimina scheda', Icons.delete_outline, onElimina),
      ],
    );
  }
}
