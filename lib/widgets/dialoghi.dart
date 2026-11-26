import 'package:flutter/material.dart';

import '../models/workout.dart';

/// Pulsante di [scegli]: il testo mostrato e il valore restituito quando viene premuto
class Scelta<T> {
  final String testo;
  final T valore;

  /// Il pulsante principale è evidenziato (va messo per ultimo, come Conferma)
  final bool principale;

  const Scelta(this.testo, this.valore, {this.principale = false});
}

/// Dialog con Annulla e un pulsante per ogni [scelte].
/// Restituisce il valore della scelta premuta, null con Annulla o toccando fuori dal dialog
Future<T?> scegli<T>(BuildContext context, String titolo, String messaggio, List<Scelta<T>> scelte) {
  return showDialog<T>(
    context: context,
    builder: (dialogContext) {
      final pulsanti = <Widget>[
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annulla')),
      ];
      for (final scelta in scelte) {
        void scegliQuesta() => Navigator.pop(dialogContext, scelta.valore);
        pulsanti.add(scelta.principale
            ? FilledButton(onPressed: scegliQuesta, child: Text(scelta.testo))
            : TextButton(onPressed: scegliQuesta, child: Text(scelta.testo)));
      }
      return AlertDialog(title: Text(titolo), content: Text(messaggio), actions: pulsanti);
    },
  );
}

/// Restituisce true solo se l'utente preme Conferma
Future<bool> chiediConferma(BuildContext context, String titolo, String messaggio) async {
  final risposta = await scegli(context, titolo, messaggio, const [Scelta('Conferma', true, principale: true)]);
  return risposta == true;
}

/// Esegue [operazione] solo dopo che l'utente ha confermato con [chiediConferma]
Future<void> seConfermato(
    BuildContext context, String titolo, String messaggio, Future<void> Function() operazione) async {
  if (await chiediConferma(context, titolo, messaggio)) {
    await operazione();
  }
}

/// Dialog informativo con il solo pulsante Ok
Future<void> avvisa(BuildContext context, String titolo, String messaggio) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(titolo),
      content: Text(messaggio),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Ok'))],
    ),
  );
}

/// Pannello dal basso con [contenuto] scorrevole, alto al massimo [altezzaMassima] dello schermo
/// e sopra la tastiera, se è aperta
Future<T?> mostraPannelloDalBasso<T>(
  BuildContext context, {
  required List<Widget> Function(BuildContext pannello) contenuto,
  double altezzaMassima = 0.75,
  EdgeInsets padding = EdgeInsets.zero,
  bool maniglia = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    showDragHandle: maniglia,
    builder: (pannello) {
      final schermo = MediaQuery.of(pannello);
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: schermo.viewInsets.bottom),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: schermo.size.height * altezzaMassima),
            child: ListView(shrinkWrap: true, padding: padding, children: contenuto(pannello)),
          ),
        ),
      );
    },
  );
}

/// Chiede un testo non vuoto, per i nomi di schede e giornate.
/// Restituisce il testo senza spazi iniziali e finali, oppure null se il dialog viene annullato
Future<String?> chiediTesto(BuildContext context, String titolo, {String initial = ''}) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => TextPrompt(title: titolo, initial: initial),
  );
}

class TextPrompt extends StatefulWidget {
  final String title;
  final String initial;

  const TextPrompt({super.key, required this.title, required this.initial});

  @override
  State<TextPrompt> createState() => _TextPromptState();
}

class _TextPromptState extends State<TextPrompt> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _valida(String? valore) {
    if ((valore ?? '').trim().isEmpty) {
      return 'Inserisci un valore';
    }
    return null;
  }

  void _conferma() {
    if (_form.currentState!.validate()) {
      Navigator.pop(context, _controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _form,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          maxLength: Plan.lunghezzaNome,
          validator: _valida,
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
        FilledButton(onPressed: _conferma, child: const Text('Salva')),
      ],
    );
  }
}
