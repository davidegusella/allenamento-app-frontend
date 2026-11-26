import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat.dart';
import '../providers/chat_store.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/formato.dart';
import 'campi_account.dart';
import 'dialoghi.dart';
import 'pannelli.dart';

/// Iniziale dello username in un cerchio
class AvatarUtente extends StatelessWidget {
  final String username;

  const AvatarUtente({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(child: Text(username.substring(0, 1).toUpperCase()));
  }
}

/// Spunta di un proprio messaggio: una se inviato, due azzurre se l'altro l'ha letto
class SpuntaLettura extends StatelessWidget {
  final bool letto;

  const SpuntaLettura({super.key, required this.letto});

  @override
  Widget build(BuildContext context) {
    return Icon(
      letto ? Icons.done_all : Icons.done,
      size: 16,
      color: letto ? Colors.lightBlueAccent : grigioTesto,
      semanticLabel: letto ? 'Letto' : 'Inviato',
    );
  }
}

/// Riga dell'elenco delle chat: @username, anteprima dell'ultimo messaggio, ora e numero di non letti
class RigaChat extends StatelessWidget {
  final Conversazione chat;
  final VoidCallback onApri;

  const RigaChat({super.key, required this.chat, required this.onApri});

  @override
  Widget build(BuildContext context) {
    final ultimo = chat.ultimoMessaggio;
    final anteprima = <Widget>[];
    if (ultimo.mio && !ultimo.eliminato) {
      anteprima.add(SpuntaLettura(letto: chat.letto(ultimo)));
      anteprima.add(const SizedBox(width: 4));
    }
    anteprima.add(Flexible(
      child: Text(
        chat.anteprima,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: ultimo.eliminato ? const TextStyle(fontStyle: FontStyle.italic) : null,
      ),
    ));

    final destra = <Widget>[Text(oraOData(ultimo.createdAt), style: testoSecondario)];
    if (chat.nonLetti > 0) {
      destra.add(const SizedBox(height: 6));
      destra.add(Badge(label: Text('${chat.nonLetti}')));
    }

    return Panel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        onTap: onApri,
        leading: AvatarUtente(username: chat.username),
        title: Text('@${chat.username}'),
        subtitle: Row(children: anteprima),
        trailing: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: destra),
      ),
    );
  }
}

/// Fumetto di un messaggio: i propri a destra con la spunta, quelli dell'altro a sinistra.
/// Con [onElimina] una pressione lunga elimina il messaggio (solo sui propri);
/// toccando una scheda inviata si chiama [onApriScheda]
class BollaMessaggio extends StatelessWidget {
  final Messaggio messaggio;
  final bool letto;
  final VoidCallback? onElimina;
  final VoidCallback? onApriScheda;

  const BollaMessaggio({super.key, required this.messaggio, required this.letto, this.onElimina, this.onApriScheda});

  @override
  Widget build(BuildContext context) {
    final mio = messaggio.mio;
    final colori = Theme.of(context).colorScheme;
    final scheda = messaggio.scheda;
    final Widget testo;
    if (messaggio.eliminato) {
      testo = const Text('Messaggio eliminato', style: TextStyle(fontStyle: FontStyle.italic, color: grigioTesto));
    } else if (scheda != null) {
      testo = CardSchedaInviata(scheda: scheda);
    } else {
      testo = Text(messaggio.text!);
    }
    final dettagli = <Widget>[
      Text(orarioMessaggio(messaggio.createdAt), style: testoSecondario.copyWith(fontSize: 11)),
    ];
    if (mio && !messaggio.eliminato) {
      dettagli.add(const SizedBox(width: 4));
      dettagli.add(SpuntaLettura(letto: letto));
    }

    return Align(
      alignment: mio ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.75),
        child: GestureDetector(
          onTap: scheda == null ? null : onApriScheda,
          onLongPress: onElimina,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 3),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
            decoration: BoxDecoration(
              color: mio ? colori.secondaryContainer : colori.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(alignment: Alignment.centerLeft, widthFactor: 1, child: testo),
                const SizedBox(height: 2),
                Row(mainAxisSize: MainAxisSize.min, children: dettagli),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Contenuto del fumetto di una scheda inviata: icona, nome e autore
class CardSchedaInviata extends StatelessWidget {
  final SchedaInviata scheda;

  const CardSchedaInviata({super.key, required this.scheda});

  @override
  Widget build(BuildContext context) {
    final tipo = scheda.postId == null ? 'Scheda' : 'Post';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.fitness_center),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(scheda.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('$tipo di @${scheda.autore} · tocca per aprire',
                  style: const TextStyle(fontSize: 12, color: Colors.white70)),
            ],
          ),
        ),
      ],
    );
  }
}

/// A chi inviare qualcosa: una delle chat esistenti oppure una nuova chat (con [chiediNuovaChat]).
/// Restituisce lo username scelto, oppure null se l'utente chiude senza scegliere
Future<String?> scegliDestinatario(BuildContext context) async {
  final conversazioni = context.read<ChatStore>().conversazioni;
  final scelta = await mostraPannelloDalBasso<String>(
    context,
    altezzaMassima: 0.7,
    contenuto: (pannello) => [
      const ListTile(title: Text('Invia a', style: TextStyle(fontWeight: FontWeight.w600))),
      ListTile(
        leading: const Icon(Icons.edit_outlined),
        title: const Text('Nuova chat'),
        // Stringa vuota: si chiude il pannello e si chiede lo username con il dialog
        onTap: () => Navigator.pop(pannello, ''),
      ),
      for (final chat in conversazioni)
        ListTile(
          leading: AvatarUtente(username: chat.username),
          title: Text('@${chat.username}'),
          onTap: () => Navigator.pop(pannello, chat.username),
        ),
    ],
  );
  if (scelta == '' && context.mounted) {
    return chiediNuovaChat(context);
  }
  return scelta;
}

/// Lo username di chi contattare, in minuscolo; il dialog si chiude solo se l'utente esiste e non è quello
/// collegato. null se il dialog viene annullato
Future<String?> chiediNuovaChat(BuildContext context) {
  return showDialog<String>(context: context, builder: (dialogContext) => const DialogoNuovaChat());
}

class DialogoNuovaChat extends StatefulWidget {
  const DialogoNuovaChat({super.key});

  @override
  State<DialogoNuovaChat> createState() => _DialogoNuovaChatState();
}

class _DialogoNuovaChatState extends State<DialogoNuovaChat> {
  final form = GlobalKey<FormState>();
  final username = TextEditingController();

  /// Risposta del server, per esempio "Utente non trovato: marco"
  String? errore;
  bool verifica = false;

  @override
  void dispose() {
    username.dispose();
    super.dispose();
  }

  Future<void> conferma() async {
    if (!form.currentState!.validate()) {
      return;
    }
    final nome = username.text.trim().toLowerCase();
    setState(() => verifica = true);
    try {
      await context.read<ChatStore>().verifica(nome);
      if (mounted) {
        Navigator.pop(context, nome);
      }
    } on ApiFailure catch (e) {
      if (mounted) {
        setState(() {
          errore = e.message;
          verifica = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuova chat'),
      content: Form(
        key: form,
        child: CampoUsername(
          controller: username,
          mio: false,
          helperText: 'Lo username esatto di chi vuoi contattare',
          errore: errore,
          onChanged: (valore) {
            if (errore != null) {
              setState(() => errore = null);
            }
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
        FilledButton(onPressed: verifica ? null : conferma, child: const Text('Scrivi')),
      ],
    );
  }
}
