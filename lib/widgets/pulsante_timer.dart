import 'package:flutter/material.dart';

/// Pulsante tondo del timer, come nell'app Timer dell'iPhone:
/// cerchio scuro del colore del pulsante, con un anello sottile intorno
class PulsanteTimer extends StatelessWidget {
  final String testo;
  final Color colore;

  /// Se è null il pulsante è disabilitato e viene mostrato più chiaro
  final VoidCallback? onPressed;

  const PulsanteTimer({super.key, required this.testo, required this.colore, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    double opacita = 1;
    if (onPressed == null) {
      opacita = 0.4;
    }

    return Opacity(
      opacity: opacita,
      child: SizedBox(
        width: 84,
        height: 84,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            shape: const CircleBorder(),
            padding: EdgeInsets.zero,
            backgroundColor: colore.withValues(alpha: 0.25),
            foregroundColor: colore,
            side: BorderSide(color: colore.withValues(alpha: 0.6), width: 2),
          ),
          child: Text(testo, style: const TextStyle(fontSize: 15)),
        ),
      ),
    );
  }
}
