import 'package:flutter/material.dart';

import '../models/workout.dart';
import '../theme/app_theme.dart';
import '../utils/formato.dart';

/// Form scorrevole delle pagine con molti campi.
/// Non è una ListView: costruirebbe solo i campi visibili e il form non potrebbe validare gli altri;
/// in più i widget fuori dallo schermo (come il timer) non vengono ricreati scorrendo
class FormScorrevole extends StatelessWidget {
  final GlobalKey<FormState> chiave;
  final List<Widget> children;

  const FormScorrevole({super.key, required this.chiave, required this.children});

  @override
  Widget build(BuildContext context) {
    return Form(
      key: chiave,
      child: SingleChildScrollView(
        padding: marginePagina,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      ),
    );
  }
}

/// Campo per un numero intero tra [minimo] e [massimo]
class CampoIntero extends StatelessWidget {
  final String etichetta;
  final TextEditingController controller;
  final int minimo;
  final int massimo;

  const CampoIntero({
    super.key,
    required this.etichetta,
    required this.controller,
    required this.minimo,
    required this.massimo,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: etichetta),
      validator: (valore) => validaIntero(valore, minimo, massimo),
    );
  }
}

class CampoNomeEsercizio extends StatelessWidget {
  final TextEditingController controller;

  const CampoNomeEsercizio({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLength: Exercise.lunghezzaNome,
      decoration: const InputDecoration(labelText: 'Nome dell\'esercizio'),
      validator: validaNome,
    );
  }
}

class CampoRecupero extends StatelessWidget {
  final TextEditingController controller;

  const CampoRecupero({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return CampoIntero(
      etichetta: 'Recupero in secondi',
      controller: controller,
      minimo: 0,
      massimo: Exercise.recuperoMassimo,
    );
  }
}

class CampoNote extends StatelessWidget {
  final TextEditingController controller;

  const CampoNote({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: 4,
      maxLength: Exercise.lunghezzaNote,
      decoration: const InputDecoration(labelText: 'Note tecniche'),
    );
  }
}

/// Pulsante principale di un form: mentre si aspetta il server è disabilitato e mostra [testoAttesa],
/// così non si invia due volte
class PulsanteInvio extends StatelessWidget {
  final String testo;
  final String testoAttesa;
  final bool busy;
  final VoidCallback onPressed;

  const PulsanteInvio({
    super.key,
    required this.testo,
    this.testoAttesa = 'Salvataggio…',
    required this.busy,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(onPressed: busy ? null : onPressed, child: Text(busy ? testoAttesa : testo));
  }
}
