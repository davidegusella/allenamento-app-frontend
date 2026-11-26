import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/workout_store.dart';
import '../widgets/pagina_classifica.dart';
import '../widgets/pannelli.dart';

/// Scheda "Bacheca" di "Le mie": le statistiche delle mie schede pubblicate,
/// in classifica per numero di importazioni o di like.
class BachecaPage extends StatelessWidget {
  const BachecaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WorkoutStore>();
    return PaginaClassifica(
      sottotitolo: 'Le statistiche delle tue schede pubblicate',
      post: store.bacheca,
      carica: store.caricaBacheca,
      vuoto: const EmptyState('Nessuna tua scheda pubblicata', 'Pubblica una tua scheda dalla pagina Schede.'),
    );
  }
}
