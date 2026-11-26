import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/workout_store.dart';
import '../widgets/elenco_post.dart';
import '../widgets/pannelli.dart';

/// Voce "Per te" della barra in basso: le schede pubblicate dagli altri utenti, dalla più recente.
/// Dalle card si mette like, si commenta e si importa la scheda tra le proprie.
class PerTePage extends StatelessWidget {
  const PerTePage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WorkoutStore>();
    return ElencoPost(
      intestazione: const [Intestazione('Per te', sottotitolo: 'Le schede pubblicate dagli altri')],
      post: store.perTe,
      carica: store.caricaPerTe,
      vuoto: const EmptyState('Nessuna scheda degli altri, per ora', 'Le schede pubblicate dagli altri compaiono qui.'),
    );
  }
}
