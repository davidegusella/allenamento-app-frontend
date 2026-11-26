import 'package:flutter/material.dart';

import '../models/post.dart';
import '../pages/post_page.dart';
import 'elenco_aggiornabile.dart';
import 'operazioni.dart';
import 'pannelli.dart';
import 'pannello_post.dart';

/// Card dei post, comuni a "Per te", Bacheca e Classifica; mostra [vuoto] se non ci sono post
class ElencoPost extends StatelessWidget {
  /// In cima all'elenco, per esempio il titolo della pagina
  final List<Widget> intestazione;
  final List<Post> post;
  final Future<void> Function() carica;
  final EmptyState vuoto;

  /// Nelle classifiche ogni card mostra la sua posizione
  final bool conPosizione;

  const ElencoPost({
    super.key,
    required this.intestazione,
    required this.post,
    required this.carica,
    required this.vuoto,
    this.conPosizione = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElencoAggiornabile(
      carica: carica,
      costruisci: (caricamento) => [
        ...intestazione,
        if (caricamento) const LinearProgressIndicator() else if (post.isEmpty) vuoto,
        for (final (i, elemento) in post.indexed)
          PannelloPost(
            post: elemento,
            posizione: conPosizione ? i + 1 : null,
            onApri: () => apriPagina(context, PostPage(post: elemento)),
          ),
      ],
    );
  }
}
