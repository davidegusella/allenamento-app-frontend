import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/post.dart';
import '../providers/workout_store.dart';
import 'operazioni.dart';
import 'pannelli.dart';

/// Cuore con il numero di like: un tocco mette o toglie il like. Sui propri post è disabilitato
class PulsanteLike extends StatefulWidget {
  final Post post;

  const PulsanteLike({super.key, required this.post});

  @override
  State<PulsanteLike> createState() => _PulsanteLikeState();
}

class _PulsanteLikeState extends State<PulsanteLike> with OperazioneInCorso {
  @override
  Widget build(BuildContext context) {
    final store = context.read<WorkoutStore>();
    final post = widget.post;
    final piaciuto = post.likedByMe;
    return PulsanteConNumero(
      tooltip: piaciuto ? 'Togli mi piace' : 'Mi piace',
      icona: Icon(piaciuto ? Icons.favorite : Icons.favorite_border, color: piaciuto ? Colors.redAccent : null),
      numero: post.likeCount,
      onPressed: azione(() => store.cambiaLike(post), abilitato: !store.eMio(post)),
    );
  }
}
