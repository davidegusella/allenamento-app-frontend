import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/chat_store.dart';
import 'chat.dart';
import 'operazioni.dart';

/// Invia in chat una propria scheda ([planId]) oppure un post ([postId]) a chi sceglie l'utente
Future<void> inviaSchedaInChat(BuildContext context, {int? planId, int? postId}) async {
  final chat = context.read<ChatStore>();
  final username = await scegliDestinatario(context);
  if (username == null) {
    return;
  }
  await chat.inviaScheda(username, planId: planId, postId: postId);
  if (context.mounted) {
    mostraMessaggio(context, 'Scheda inviata a @$username');
  }
}

/// Icona per inviare un post in chat, nelle card e nella pagina del post
class PulsanteInviaPost extends StatefulWidget {
  final int postId;

  const PulsanteInviaPost({super.key, required this.postId});

  @override
  State<PulsanteInviaPost> createState() => _PulsanteInviaPostState();
}

class _PulsanteInviaPostState extends State<PulsanteInviaPost> with OperazioneInCorso {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Invia in chat',
      icon: const Icon(Icons.send_outlined),
      onPressed: azione(() => inviaSchedaInChat(context, postId: widget.postId)),
    );
  }
}
