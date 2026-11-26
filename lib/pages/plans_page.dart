import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/workout.dart';
import '../providers/workout_store.dart';
import '../theme/app_theme.dart';
import '../widgets/dialoghi.dart';
import '../widgets/invio_scheda.dart';
import '../widgets/operazioni.dart';
import '../widgets/pannelli.dart';
import '../widgets/pannello_scheda.dart';
import 'plan_page.dart';
import 'post_page.dart';

/// Scheda "Schede" di "Le mie": le schede dalla più recente, da creare, pubblicare, inviare in chat,
/// rinominare ed eliminare. Toccando una scheda si aprono le sue giornate
class PlansPage extends StatefulWidget {
  const PlansPage({super.key});

  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> with OperazioneInCorso {
  WorkoutStore get _store => context.read<WorkoutStore>();

  Future<void> _nuovaScheda() async {
    final nome = await chiediTesto(context, 'Nuova scheda');
    if (nome != null) {
      await _store.creaScheda(nome);
    }
  }

  Future<void> _rinomina(Plan plan) async {
    final nome = await chiediTesto(context, 'Nome della scheda', initial: plan.name);
    if (nome != null) {
      await _store.rinominaScheda(plan.id, nome);
    }
  }

  Future<void> _pubblica(Plan plan) {
    return seConfermato(
      context,
      'Pubblicare ${plan.name}?',
      'Gli altri vedranno in "Per te" una copia della scheda con i tuoi carichi. '
          'Le modifiche successive non cambiano il post.',
      () async {
        await _store.pubblica(plan.id);
        if (mounted) {
          mostraMessaggio(context, 'Scheda pubblicata');
        }
      },
    );
  }

  Future<void> _apriNuovaVersione(int postId) async {
    final post = await _store.caricaPost(postId);
    if (mounted) {
      apriPagina(context, PostPage(post: post));
    }
  }

  Future<void> _elimina(Plan plan) {
    return seConfermato(
      context,
      'Eliminare ${plan.name}?',
      'La scheda, le sue giornate e i loro esercizi verranno eliminati, '
          'insieme a tutti i post con cui l\'hai pubblicata (like e commenti compresi). '
          'Chi l\'ha già importata conserva la sua copia.',
      () => _store.eliminaScheda(plan.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    // L'id cresce a ogni nuova scheda, come la data di creazione
    final plans = List<Plan>.from(context.watch<WorkoutStore>().plans)
      ..sort((prima, seconda) => seconda.createdAt.compareTo(prima.createdAt));

    final contenuto = <Widget>[
      if (plans.isEmpty) const EmptyState('La tua prima scheda', 'Crea una scheda e aggiungi le giornate.'),
      for (final plan in plans)
        PannelloScheda(
          plan: plan,
          onApri: () => apriPagina(context, PlanPage(planId: plan.id)),
          onPubblica: azione(() => _pubblica(plan), abilitato: plan.pubblicabile),
          onInvia: azione(() => inviaSchedaInChat(context, planId: plan.id), abilitato: plan.pubblicabile),
          onRinomina: azione(() => _rinomina(plan)),
          onElimina: azione(() => _elimina(plan)),
          onNuovaVersione:
              azione(() => _apriNuovaVersione(plan.newVersionPostId!), abilitato: plan.newVersionPostId != null),
        ),
      const SizedBox(height: 8),
      ElevatedButton.icon(
          onPressed: azione(_nuovaScheda), icon: const Icon(Icons.add), label: const Text('Nuova scheda')),
    ];
    return ListView(padding: marginePagina, children: contenuto);
  }
}
