import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'operazioni.dart';

/// Lista che si carica con [carica] all'apertura e si aggiorna trascinandola verso il basso.
/// [costruisci] riceve true mentre il caricamento è in corso
class ElencoAggiornabile extends StatefulWidget {
  final Future<void> Function() carica;
  final List<Widget> Function(bool caricamento) costruisci;

  const ElencoAggiornabile({super.key, required this.carica, required this.costruisci});

  @override
  State<ElencoAggiornabile> createState() => _ElencoAggiornabileState();
}

class _ElencoAggiornabileState extends State<ElencoAggiornabile> {
  bool _caricamento = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((tempo) => _carica());
  }

  Future<void> _carica() async {
    if (!mounted) {
      return;
    }
    setState(() => _caricamento = true);
    await esegui(context, widget.carica);
    if (mounted) {
      setState(() => _caricamento = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _carica,
      child: ListView(
        // Si può trascinare anche quando la lista è corta
        physics: const AlwaysScrollableScrollPhysics(),
        padding: marginePagina,
        children: widget.costruisci(_caricamento),
      ),
    );
  }
}
