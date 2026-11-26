import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/post.dart';
import '../providers/workout_store.dart';
import 'dialoghi.dart';
import 'operazioni.dart';

/// Messaggio dopo l'importazione di una scheda, da un post o dalla chat
const messaggioImportata = 'Scheda importata nelle tue schede';

/// Importa la scheda di un post tra le proprie; sui propri post non compare.
/// Con una copia già presente chiede se sostituirla o crearne una nuova.
/// [compatto] è la versione con testo delle card, altrimenti l'icona accanto al cuore nella pagina del post
class PulsanteImporta extends StatefulWidget {
  final Post post;
  final bool compatto;

  const PulsanteImporta({super.key, required this.post, this.compatto = false});

  @override
  State<PulsanteImporta> createState() => _PulsanteImportaState();
}

class _PulsanteImportaState extends State<PulsanteImporta> with OperazioneInCorso {
  Future<void> _importa() async {
    final store = context.read<WorkoutStore>();
    final post = widget.post;
    final copia = post.myCopyPlanId;
    var sostituisci = false;
    if (copia != null) {
      final scelta = await scegli(
        context,
        post.copia.avviso!,
        'Sostituendo la tua copia, le modifiche che ci hai fatto (kg compresi) andranno perse.',
        const [Scelta('Importa come nuova', false), Scelta('Sostituisci la mia copia', true, principale: true)],
      );
      if (scelta == null) {
        return;
      }
      sostituisci = scelta;
    }

    await store.importa(post.id, sostituisci: sostituisci ? copia : null);
    if (mounted) {
      mostraMessaggio(context, sostituisci ? 'Copia sostituita' : messaggioImportata);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (context.read<WorkoutStore>().eMio(widget.post)) {
      return const SizedBox.shrink();
    }
    if (widget.compatto) {
      return TextButton.icon(
        onPressed: azione(_importa),
        icon: const Icon(Icons.download_outlined),
        label: const Text('Importa'),
      );
    }

    return IconButton(
      tooltip: 'Importa nelle mie schede',
      icon: const Icon(Icons.download_outlined),
      onPressed: azione(_importa),
    );
  }
}
