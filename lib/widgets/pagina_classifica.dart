import 'package:flutter/material.dart';

import '../models/post.dart';
import 'elenco_post.dart';
import 'pannelli.dart';

/// Classifiche "Più importate" e "Più piaciute", comuni a Bacheca e Classifica:
/// cambiano il titolo e da dove arrivano i post
class PaginaClassifica extends StatefulWidget {
  /// null dentro "Le mie", dove il titolo è il nome della scheda interna
  final String? titolo;
  final String sottotitolo;

  /// Post caricati per ogni ordine
  final Map<OrdineClassifica, List<Post>> post;
  final Future<void> Function(OrdineClassifica ordine) carica;
  final EmptyState vuoto;
  final OrdineClassifica iniziale;

  const PaginaClassifica({
    super.key,
    this.titolo,
    required this.sottotitolo,
    required this.post,
    required this.carica,
    required this.vuoto,
    this.iniziale = OrdineClassifica.importate,
  });

  @override
  State<PaginaClassifica> createState() => _PaginaClassificaState();
}

class _PaginaClassificaState extends State<PaginaClassifica> {
  late OrdineClassifica _ordine = widget.iniziale;

  @override
  Widget build(BuildContext context) {
    final scelto = _ordine;

    // La chiave cambia con l'ordine: l'elenco viene ricreato e carica la classifica scelta
    return ElencoPost(
      key: ValueKey(scelto),
      intestazione: [
        Intestazione(widget.titolo, sottotitolo: widget.sottotitolo),
        SegmentedButton<OrdineClassifica>(
          segments: [
            for (final valore in OrdineClassifica.values) ButtonSegment(value: valore, label: Text(valore.etichetta)),
          ],
          selected: {scelto},
          showSelectedIcon: false,
          onSelectionChanged: (scelta) => setState(() => _ordine = scelta.first),
        ),
        const SizedBox(height: 16),
      ],
      post: widget.post[scelto]!,
      carica: () => widget.carica(scelto),
      vuoto: widget.vuoto,
      conPosizione: true,
    );
  }
}
