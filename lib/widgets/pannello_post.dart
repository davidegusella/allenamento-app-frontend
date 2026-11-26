import 'package:flutter/material.dart';

import '../models/post.dart';
import '../utils/formato.dart';
import 'commenti.dart';
import 'invio_scheda.dart';
import 'pannelli.dart';
import 'pulsante_importa.dart';
import 'pulsante_like.dart';

/// Card di un post: nome della scheda, autore, data, giornate, importazioni e invio in chat;
/// sotto, like, commenti e importa.
/// Toccando la parte alta si apre il post. Con [posizione] mostra anche il posto in classifica (1., 2., 3.…).
class PannelloPost extends StatelessWidget {
  final Post post;
  final int? posizione;
  final VoidCallback onApri;

  const PannelloPost({super.key, required this.post, required this.onApri, this.posizione});

  @override
  Widget build(BuildContext context) {
    Widget? classifica;
    final posto = posizione;
    if (posto != null) {
      classifica = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: Colors.white70, borderRadius: BorderRadius.circular(8)),
        child: Text(
          '$posto.',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black, fontWeight: FontWeight.w700),
        ),
      );
    }

    final giornate = conteggio(post.plan.days.length, 'giornata', 'giornate');
    return Panel(
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: classifica,
            title: Text(post.plan.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('@${post.author} · ${post.data}\n$giornate · ${post.importazioni}'),
            isThreeLine: true,
            // In basso non c'è spazio: like, commenti e "Importa" occupano già la riga
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [PulsanteInviaPost(postId: post.id), const Icon(Icons.chevron_right)],
            ),
            onTap: onApri,
          ),
          Row(
            children: [
              PulsanteLike(post: post),
              const SizedBox(width: 12),
              PulsanteCommenti(post: post),
              const Spacer(),
              PulsanteImporta(post: post, compatto: true),
            ],
          ),
        ],
      ),
    );
  }
}
