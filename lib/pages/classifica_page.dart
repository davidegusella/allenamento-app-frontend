import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/post.dart';
import '../providers/workout_store.dart';
import '../widgets/pagina_classifica.dart';
import '../widgets/pannelli.dart';

/// Voce "Classifica" della barra in basso: le 100 schede con più like e con più importazioni
/// di tutti gli utenti della community, per spingere a migliorare le proprie schede e pubblicarle.
class ClassificaPage extends StatelessWidget {
  const ClassificaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WorkoutStore>();
    return PaginaClassifica(
      titolo: 'Classifica',
      sottotitolo: 'Le 100 schede migliori della community',
      post: store.classifica,
      carica: store.caricaClassifica,
      iniziale: OrdineClassifica.piaciute,
      vuoto: const EmptyState(
        'Ancora nessuna scheda in classifica',
        'Pubblica le tue schede: quelle con più like e importazioni salgono qui.',
      ),
    );
  }
}
