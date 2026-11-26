import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat.dart';
import '../providers/chat_store.dart';
import '../theme/app_theme.dart';
import '../widgets/campo_invio.dart';
import '../widgets/chat.dart';
import '../widgets/dialoghi.dart';
import '../widgets/operazioni.dart';
import 'scheda_ricevuta_page.dart';

/// Chat con [username]: i messaggi dal basso verso l'alto come su WhatsApp, il campo per scrivere in fondo.
/// I messaggi nuovi arrivano in tempo reale e risultano già letti; salendo si caricano quelli più vecchi.
class ChatPage extends StatefulWidget {
  final String username;

  const ChatPage({super.key, required this.username});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  /// Distanza dalla cima della chat a cui iniziano a caricarsi i messaggi precedenti
  static const double _margineCaricamento = 200;

  final _scorrimento = ScrollController();

  // Letto una volta: in dispose il context non si può più usare
  late final ChatStore _chat = context.read<ChatStore>();

  @override
  void initState() {
    super.initState();
    _scorrimento.addListener(_seInCima);
    eseguiDopoIlPrimoFrame(context, () => _chat.apri(widget.username));
  }

  @override
  void dispose() {
    _chat.chiudiChat(widget.username);
    _scorrimento.dispose();
    super.dispose();
  }

  /// La lista è rovesciata: la fine dello scorrimento è la cima della chat, con i messaggi più vecchi
  void _seInCima() {
    final posizione = _scorrimento.position;
    if (posizione.pixels >= posizione.maxScrollExtent - _margineCaricamento) {
      esegui(context, () => _chat.caricaPrecedenti(widget.username));
    }
  }

  Future<void> _elimina(Messaggio messaggio) {
    return seConfermato(context, 'Eliminare il messaggio?', 'Verrà eliminato anche per @${widget.username}.',
        () => esegui(context, () => _chat.elimina(messaggio)));
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ChatStore>();
    final messaggi = store.messaggi[widget.username];
    final conversazione = store.conversazione(widget.username);

    Widget elenco;
    if (messaggi == null) {
      elenco = const Align(alignment: Alignment.topCenter, child: LinearProgressIndicator());
    } else if (messaggi.isEmpty) {
      elenco = Center(
        child: Text('Scrivi il primo messaggio a @${widget.username}', style: testoSecondario),
      );
    } else {
      elenco = ListView.builder(
        controller: _scorrimento,
        reverse: true,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: messaggi.length,
        itemBuilder: (context, indice) {
          final messaggio = messaggi[indice];
          final eliminabile = messaggio.mio && !messaggio.eliminato;
          return BollaMessaggio(
            key: ValueKey(messaggio.id),
            messaggio: messaggio,
            letto: conversazione?.letto(messaggio) ?? false,
            onElimina: eliminabile ? () => _elimina(messaggio) : null,
            onApriScheda: () => apriSchedaInviata(context, messaggio),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('@${widget.username}')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: elenco),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              child: CampoInvio(
                suggerimento: 'Scrivi un messaggio',
                tooltip: 'Invia messaggio',
                lunghezzaMassima: Messaggio.lunghezzaMassima,
                onInvia: (testo) => esegui(context, () => _chat.invia(widget.username, testo)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
