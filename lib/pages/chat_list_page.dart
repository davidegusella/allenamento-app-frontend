import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/chat_store.dart';
import '../widgets/chat.dart';
import '../widgets/elenco_aggiornabile.dart';
import '../widgets/operazioni.dart';
import '../widgets/pannelli.dart';
import 'chat_page.dart';

/// Voce "Messaggi" della barra in basso: le chat dalla più recente, come su WhatsApp.
/// Si aggiorna da sola quando arriva un messaggio; "Nuova chat" chiede lo username di chi contattare
class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  Future<void> _nuovaChat(BuildContext context) async {
    final username = await chiediNuovaChat(context);
    if (username != null && context.mounted) {
      apriPagina(context, ChatPage(username: username));
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatStore>();
    return ElencoAggiornabile(
      carica: context.read<ChatStore>().carica,
      costruisci: (caricamento) => [
        const Intestazione('Messaggi', sottotitolo: 'Le tue chat con gli altri utenti'),
        ElevatedButton.icon(
          onPressed: () => _nuovaChat(context),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Nuova chat'),
        ),
        const SizedBox(height: 16),
        if (chat.conversazioni.isEmpty)
          caricamento
              ? const LinearProgressIndicator()
              : const EmptyState('Nessuna chat', 'Tocca "Nuova chat" e scrivi lo username di chi vuoi contattare.'),
        for (final conversazione in chat.conversazioni)
          RigaChat(
            chat: conversazione,
            onApri: () => apriPagina(context, ChatPage(username: conversazione.username)),
          ),
      ],
    );
  }
}
