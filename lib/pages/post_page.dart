import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/post.dart';
import '../providers/workout_store.dart';
import '../theme/app_theme.dart';
import '../widgets/commenti.dart';
import '../widgets/dialoghi.dart';
import '../widgets/invio_scheda.dart';
import '../widgets/operazioni.dart';
import '../widgets/pulsante_importa.dart';
import '../widgets/pulsante_like.dart';
import '../widgets/vista_scheda.dart';

/// Post: la scheda pubblicata in sola lettura, invio in chat, like, commenti e, per i post degli altri,
/// l'icona accanto al cuore per importarla tra le proprie schede
class PostPage extends StatefulWidget {
  final Post post;

  const PostPage({super.key, required this.post});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> with OperazioneInCorso {
  Future<void> _eliminaPost() {
    final store = context.read<WorkoutStore>();
    return seConfermato(
      context,
      'Eliminare il post?',
      'Sparirà da Per te e dalla Bacheca con like e commenti. Chi ha già importato la scheda la conserva tra le sue.',
      () async {
        await store.eliminaPost(widget.post.id);
        if (!mounted) {
          return;
        }
        // Il messenger va preso prima di chiudere la pagina: dopo, il suo context non è più valido
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        messenger.showSnackBar(const SnackBar(content: Text('Post eliminato')));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WorkoutStore>();
    // Dopo un like o un'importazione lo store ha il post aggiornato
    final post = store.cercaPost(widget.post.id) ?? widget.post;

    final contenuto = <Widget>[
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('@${post.author}', style: Theme.of(context).textTheme.titleMedium),
                Text('Pubblicata il ${post.data} · ${post.importazioni}', style: testoSecondario),
              ],
            ),
          ),
          PulsanteInviaPost(postId: post.id),
          PulsanteImporta(post: post),
          PulsanteLike(post: post),
        ],
      ),
      const SizedBox(height: 16),
      VistaScheda(plan: post.plan),
    ];
    contenuto.add(const SizedBox(height: 24));
    contenuto.add(SezioneCommenti(postId: post.id));

    final azioni = <Widget>[];
    if (store.eMio(post)) {
      azioni.add(
          IconButton(tooltip: 'Elimina post', icon: const Icon(Icons.delete_outline), onPressed: azione(_eliminaPost)));
    }

    return Scaffold(
      appBar: AppBar(title: Text(post.plan.name), actions: azioni),
      body: ListView(padding: marginePagina, children: contenuto),
    );
  }
}
