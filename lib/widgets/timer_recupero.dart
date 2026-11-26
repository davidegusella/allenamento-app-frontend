import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../services/avviso_timer.dart';
import '../utils/formato.dart';
import 'pulsante_timer.dart';

/// Stati del timer, come nell'app Timer dell'iPhone
enum StatoTimer {
  /// Si sceglie la durata con le rotelle
  fermo,
  inCorso,
  inPausa,

  /// Tempo scaduto: l'allarme suona finché l'utente non preme Stop
  suona,
}

/// Timer di recupero in stile iPhone. Da fermo mostra le rotelle per scegliere la durata, che parte dal
/// recupero dell'esercizio; durante il conto alla rovescia un anello che si svuota con il tempo rimanente.
///
/// A zero suona un allarme che si ripete, con la vibrazione, finché l'utente non preme Stop: così se è
/// distratto se ne accorge comunque. Mentre il timer è avviato lo schermo resta acceso.
/// La durata scelta vale solo per questa schermata: il recupero si cambia dalla pagina di modifica
class TimerRecupero extends StatefulWidget {
  final int secondiIniziali;

  /// Suono, vibrazione e schermo; nei test una versione finta
  final AvvisoTimer? avviso;

  const TimerRecupero({super.key, required this.secondiIniziali, this.avviso});

  @override
  State<TimerRecupero> createState() => _TimerRecuperoState();
}

class _TimerRecuperoState extends State<TimerRecupero> {
  // Colori dei pulsanti dell'app Timer dell'iPhone
  static const Color verde = Color(0xFF30D158);
  static const Color arancione = Color(0xFFFF9F0A);
  static const Color grigio = Color(0xFF8E8E93);
  static const Color rosso = Color(0xFFFF453A);

  late final AvvisoTimer avviso;

  StatoTimer stato = StatoTimer.fermo;

  /// Durata scelta con le rotelle
  late Duration durata;

  /// Tempo rimanente del conto alla rovescia
  Duration rimanente = Duration.zero;

  /// Istante in cui il conto alla rovescia finisce: rispetto a togliere un secondo alla volta,
  /// il tempo resta corretto anche se l'app va in background per qualche secondo
  DateTime? fine;

  /// Ricalcola il tempo rimanente ogni 200 millisecondi
  Timer? ticker;

  @override
  void initState() {
    super.initState();
    durata = Duration(seconds: widget.secondiIniziali);
    avviso = widget.avviso ?? AvvisoTimer();
  }

  /// Uscendo dalla pagina l'allarme si spegne e lo schermo può di nuovo spegnersi
  @override
  void dispose() {
    ticker?.cancel();
    avviso.chiudi();
    super.dispose();
  }

  /// Conto alla rovescia dalla durata scelta
  void avvia() {
    if (durata == Duration.zero) {
      return;
    }
    rimanente = durata;
    riprendi();
  }

  /// Riparte dal tempo rimanente
  void riprendi() {
    fine = DateTime.now().add(rimanente);
    avviso.schermoAcceso(true);
    ticker?.cancel();
    ticker = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      aggiorna();
    });
    setState(() => stato = StatoTimer.inCorso);
  }

  /// In pausa non deve suonare nulla, quindi lo schermo può di nuovo spegnersi
  void pausa() {
    ticker?.cancel();
    avviso.schermoAcceso(false);
    setState(() {
      rimanente = fine!.difference(DateTime.now());
      stato = StatoTimer.inPausa;
    });
  }

  /// Ferma il timer o spegne l'allarme e torna alle rotelle, con la durata scelta prima
  void annulla() {
    ticker?.cancel();
    avviso.fermaAllarme();
    avviso.schermoAcceso(false);
    setState(() => stato = StatoTimer.fermo);
  }

  /// A zero suona l'allarme
  void aggiorna() {
    final mancante = fine!.difference(DateTime.now());
    if (mancante <= Duration.zero) {
      ticker?.cancel();
      avviso.suonaAllarme();
      setState(() {
        rimanente = Duration.zero;
        stato = StatoTimer.suona;
      });
      return;
    }
    setState(() => rimanente = mancante);
  }

  /// Rotelle per ore, minuti e secondi, con i colori del tema scuro.
  /// CupertinoTimerPicker divide per la larghezza delle colonne: con zero spazio (finestra del browser
  /// ridimensionata o ridotta a icona) il calcolo è infinito e non si può disegnare, quindi si salta
  Widget rotelle() {
    return LayoutBuilder(
      builder: (context, vincoli) {
        if (vincoli.maxWidth <= 0) {
          return const SizedBox(height: 216);
        }
        return CupertinoTheme(
          data: const CupertinoThemeData(brightness: Brightness.dark),
          child: SizedBox(
            width: vincoli.maxWidth,
            height: 216,
            child: CupertinoTimerPicker(
              mode: CupertinoTimerPickerMode.hms,
              initialTimerDuration: durata,
              onTimerDurationChanged: (valore) {
                setState(() => durata = valore);
              },
            ),
          ),
        );
      },
    );
  }

  /// Anello che si svuota con il tempo rimanente al centro
  Widget anello() {
    // Frazione di tempo rimanente: 1 all'inizio, 0 alla fine
    double frazione = 0;
    if (durata.inMilliseconds > 0) {
      frazione = rimanente.inMilliseconds / durata.inMilliseconds;
    }

    return SizedBox(
      width: 216,
      height: 216,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: frazione,
            strokeWidth: 8,
            color: arancione,
            backgroundColor: Colors.white12,
          ),
          Center(child: Column(mainAxisSize: MainAxisSize.min, children: testiAnello())),
        ],
      ),
    );
  }

  /// Il tempo rimanente e, quando l'allarme suona, "Tempo scaduto!"
  List<Widget> testiAnello() {
    final testi = <Widget>[
      Text(durataTimer(rimanente), style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w300)),
    ];
    if (stato == StatoTimer.suona) {
      testi.add(const Text('Tempo scaduto!', style: TextStyle(color: rosso, fontWeight: FontWeight.w600)));
    }
    return testi;
  }

  @override
  Widget build(BuildContext context) {
    // Il contenuto e il pulsante di destra cambiano in base allo stato
    Widget contenuto;
    PulsanteTimer pulsanteDestro;
    VoidCallback? azioneAnnulla = annulla;

    if (stato == StatoTimer.fermo) {
      contenuto = rotelle();
      pulsanteDestro = PulsanteTimer(testo: 'Avvia', colore: verde, onPressed: avvia);
      // Da fermo non c'è niente da annullare
      azioneAnnulla = null;
    } else if (stato == StatoTimer.inCorso) {
      contenuto = anello();
      pulsanteDestro = PulsanteTimer(testo: 'Pausa', colore: arancione, onPressed: pausa);
    } else if (stato == StatoTimer.suona) {
      contenuto = anello();
      // Stop spegne l'allarme e torna alle rotelle, come Annulla
      pulsanteDestro = PulsanteTimer(testo: 'Stop', colore: rosso, onPressed: annulla);
      azioneAnnulla = null;
    } else {
      contenuto = anello();
      pulsanteDestro = PulsanteTimer(testo: 'Riprendi', colore: verde, onPressed: riprendi);
    }

    return Column(
      children: [
        Text('Recupero', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Center(child: contenuto),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            PulsanteTimer(testo: 'Annulla', colore: grigio, onPressed: azioneAnnulla),
            pulsanteDestro,
          ],
        ),
      ],
    );
  }
}
