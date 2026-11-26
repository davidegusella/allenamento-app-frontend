import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Riquadro con bordo arrotondato usato come "card" in tutte le pagine
class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const Panel({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Colors.white10),
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Messaggio mostrato quando una lista è vuota
class EmptyState extends StatelessWidget {
  final String title;
  final String detail;

  const EmptyState(this.title, this.detail, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        children: [
          const Icon(Icons.fitness_center, size: 40, color: Colors.white38),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(detail, textAlign: TextAlign.center, style: testoSecondario),
        ],
      ),
    );
  }
}

/// Titolo grande con un sottotitolo grigio, in cima alle pagine principali
class Intestazione extends StatelessWidget {
  /// null nelle schede interne di "Le mie", il cui nome fa già da titolo
  final String? titolo;
  final String? sottotitolo;

  const Intestazione(this.titolo, {super.key, this.sottotitolo});

  @override
  Widget build(BuildContext context) {
    final righe = <Widget>[];
    if (titolo != null) {
      righe.add(Text(
        titolo!,
        style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
      ));
    }
    if (sottotitolo != null) {
      if (righe.isNotEmpty) {
        righe.add(const SizedBox(height: 8));
      }
      righe.add(Text(sottotitolo!, style: testoSecondario));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: righe),
    );
  }
}

/// Pulsante con icona di [RigaAzioni]; con [onPressed] null è disabilitato
class AzionePannello {
  final String tooltip;
  final IconData icona;
  final VoidCallback? onPressed;

  const AzionePannello(this.tooltip, this.icona, this.onPressed);
}

/// "Sposta su" e "Sposta giù" dell'elemento [indice] di una lista lunga [totale]:
/// il primo non sale e l'ultimo non scende.
/// [sposta] riceve -1 o +1 e se il pulsante è abilitato, e restituisce la funzione del pulsante
List<AzionePannello> azioniSpostamento(
    int indice, int totale, VoidCallback? Function(int delta, bool abilitato) sposta) {
  return [
    AzionePannello('Sposta su', Icons.arrow_upward, sposta(-1, indice > 0)),
    AzionePannello('Sposta giù', Icons.arrow_downward, sposta(1, indice < totale - 1)),
  ];
}

/// Riga di pulsanti con icona distribuiti su tutta la larghezza
class RigaAzioni extends StatelessWidget {
  final List<AzionePannello> azioni;

  const RigaAzioni({super.key, required this.azioni});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        for (final azione in azioni)
          IconButton(tooltip: azione.tooltip, onPressed: azione.onPressed, icon: Icon(azione.icona, size: 20)),
      ],
    );
  }
}

/// Card di un elemento delle proprie liste (scheda, giornata, esercizio): titolo in grassetto,
/// sottotitolo, freccia per aprirlo, eventuali [extra] e sotto la [RigaAzioni].
/// Non conosce il server: le azioni arrivano dalla pagina
class PannelloConAzioni extends StatelessWidget {
  final String titolo;
  final String sottotitolo;
  final VoidCallback onApri;
  final List<AzionePannello> azioni;
  final List<Widget> extra;

  const PannelloConAzioni({
    super.key,
    required this.titolo,
    required this.sottotitolo,
    required this.onApri,
    required this.azioni,
    this.extra = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(titolo, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(sottotitolo),
            trailing: const Icon(Icons.chevron_right),
            onTap: onApri,
          ),
          ...extra,
          RigaAzioni(azioni: azioni),
        ],
      ),
    );
  }
}

/// Pagina di una scheda o di una giornata eliminata mentre era aperta
class PaginaEliminata extends StatelessWidget {
  final String titolo;
  final String messaggio;

  const PaginaEliminata({super.key, required this.titolo, required this.messaggio});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text(titolo)), body: Center(child: Text(messaggio)));
  }
}

/// Logo dell'app; [tondo] lo ritaglia nel cerchio usato nelle intestazioni
class Logo extends StatelessWidget {
  final double dimensione;
  final bool tondo;

  const Logo({super.key, required this.dimensione, this.tondo = false});

  @override
  Widget build(BuildContext context) {
    final immagine = Image.asset('lib/assets/iconwb.png', width: dimensione, height: tondo ? dimensione : null);
    return tondo ? ClipOval(child: immagine) : immagine;
  }
}

/// Icona con un numero accanto, come il cuore dei like e il fumetto dei commenti
class PulsanteConNumero extends StatelessWidget {
  final String tooltip;
  final Widget icona;
  final int numero;
  final VoidCallback? onPressed;

  const PulsanteConNumero({
    super.key,
    required this.tooltip,
    required this.icona,
    required this.numero,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(tooltip: tooltip, icon: icona, onPressed: onPressed),
        Text('$numero'),
      ],
    );
  }
}
