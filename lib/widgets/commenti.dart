import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/commento.dart';
import '../models/post.dart';
import '../providers/workout_store.dart';
import '../theme/app_theme.dart';
import 'campo_invio.dart';
import 'dialoghi.dart';
import 'operazioni.dart';
import 'pannelli.dart';

/// Un commento: testo, autore e data; con [onElimina] mostra il cestino (solo sui propri)
class PannelloCommento extends StatelessWidget {
  final Commento commento;
  final VoidCallback? onElimina;

  const PannelloCommento({super.key, required this.commento, this.onElimina});

  @override
  Widget build(BuildContext context) {
    Widget? cestino;
    if (onElimina != null) {
      cestino = IconButton(
        tooltip: 'Elimina commento',
        icon: const Icon(Icons.delete_outline),
        onPressed: onElimina,
      );
    }
    return Panel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(commento.text),
        subtitle: Text('@${commento.author} · ${commento.data}'),
        trailing: cestino,
      ),
    );
  }
}

/// Commenti di un post: titolo, elenco dal più vecchio (cestino sui propri) e campo per scriverne uno.
/// Li carica da solo all'apertura; usata nella pagina del post e nel pannello dal basso delle card.
class SezioneCommenti extends StatefulWidget {
  final int postId;

  const SezioneCommenti({super.key, required this.postId});

  @override
  State<SezioneCommenti> createState() => _SezioneCommentiState();
}

class _SezioneCommentiState extends State<SezioneCommenti> with OperazioneInCorso {
  @override
  void initState() {
    super.initState();
    eseguiDopoIlPrimoFrame(context, () => context.read<WorkoutStore>().caricaCommenti(widget.postId));
  }

  Future<void> _elimina(Commento commento) {
    final store = context.read<WorkoutStore>();
    return seConfermato(
        context, 'Eliminare il commento?', commento.text, () => store.eliminaCommento(widget.postId, commento.id));
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WorkoutStore>();
    final righe = <Widget>[
      Text('Commenti', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
    ];
    // null finché non arrivano dal server
    final elenco = store.commenti[widget.postId];
    if (elenco != null && elenco.isEmpty) {
      righe.add(const Text('Nessun commento', style: testoSecondario));
    }
    for (final commento in elenco ?? <Commento>[]) {
      final mio = store.utente?.username == commento.author;
      righe.add(PannelloCommento(commento: commento, onElimina: mio ? azione(() => _elimina(commento)) : null));
    }
    righe.add(CampoInvio(
      suggerimento: 'Scrivi un commento',
      tooltip: 'Invia commento',
      lunghezzaMassima: Commento.lunghezzaMassima,
      onInvia: (testo) => esegui(context, () => store.commenta(widget.postId, testo)),
    ));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: righe);
  }
}

/// Fumetto con il numero di commenti: apre i commenti in un pannello dal basso, senza cambiare pagina
class PulsanteCommenti extends StatelessWidget {
  final Post post;

  const PulsanteCommenti({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return PulsanteConNumero(
      tooltip: 'Commenti',
      icona: const Icon(Icons.mode_comment_outlined),
      numero: post.commentCount,
      onPressed: () => mostraPannelloDalBasso<void>(
        context,
        maniglia: true,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        contenuto: (pannello) => [SezioneCommenti(postId: post.id)],
      ),
    );
  }
}
