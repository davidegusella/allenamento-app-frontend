import 'package:flutter/material.dart';

/// Campo per scrivere un testo breve con il pulsante di invio, usato da commenti e chat.
/// Il pulsante si abilita appena c'è del testo e il campo si svuota dopo un invio riuscito.
class CampoInvio extends StatefulWidget {
  final String suggerimento;

  /// Tooltip del pulsante, per esempio "Invia commento"
  final String tooltip;
  final int lunghezzaMassima;

  /// Riceve il testo senza spazi iniziali e finali; restituisce true se l'invio è riuscito
  final Future<bool> Function(String testo) onInvia;

  const CampoInvio({
    super.key,
    required this.suggerimento,
    required this.tooltip,
    required this.lunghezzaMassima,
    required this.onInvia,
  });

  @override
  State<CampoInvio> createState() => _CampoInvioState();
}

class _CampoInvioState extends State<CampoInvio> {
  final testo = TextEditingController();
  bool invio = false;

  @override
  void initState() {
    super.initState();
    testo.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    testo.dispose();
    super.dispose();
  }

  Future<void> invia() async {
    setState(() => invio = true);
    final riuscito = await widget.onInvia(testo.text.trim());
    if (!mounted) {
      return;
    }
    setState(() => invio = false);
    if (riuscito) {
      testo.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vuoto = testo.text.trim().isEmpty;
    return TextField(
      controller: testo,
      maxLength: widget.lunghezzaMassima,
      minLines: 1,
      maxLines: 4,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        hintText: widget.suggerimento,
        suffixIcon: IconButton(
          tooltip: widget.tooltip,
          icon: const Icon(Icons.send),
          onPressed: vuoto || invio ? null : invia,
        ),
      ),
    );
  }
}
