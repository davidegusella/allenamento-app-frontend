/// Campi delle pagine di accesso, registrazione e account, con le stesse regole del backend
/// (vedi le annotazioni di validazione): l'utente vede l'errore senza aspettare il server.
library;

import 'package:flutter/material.dart';

import '../models/utente.dart';

final RegExp formatoUsername = RegExp('^[a-zA-Z0-9_.]{3,${Utente.lunghezzaUsername}}\$');

/// Controllo semplice, qualcosa@qualcosa.qualcosa senza spazi: quello completo lo fa il backend
final RegExp formatoEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String? validaUsername(String? valore) {
  if (!formatoUsername.hasMatch((valore ?? '').trim())) {
    return 'Da 3 a ${Utente.lunghezzaUsername} caratteri tra lettere, numeri, . e _';
  }
  return null;
}

String? validaEmail(String? valore) {
  final testo = (valore ?? '').trim();
  if (testo.isEmpty) {
    return 'Inserisci l\'email';
  }
  if (testo.length > Utente.lunghezzaEmail || !formatoEmail.hasMatch(testo)) {
    return 'Email non valida';
  }
  return null;
}

String? validaPassword(String? valore) {
  final lunghezza = (valore ?? '').length;
  if (lunghezza < Utente.passwordMin || lunghezza > Utente.passwordMax) {
    return 'Da ${Utente.passwordMin} a ${Utente.passwordMax} caratteri';
  }
  return null;
}

/// Campo username con la @ davanti, come lo vedono gli altri
class CampoUsername extends StatelessWidget {
  final TextEditingController controller;

  /// false per lo username di un altro: il telefono non propone i dati dell'utente
  final bool mio;
  final String helperText;

  /// Errore ricevuto dal server, mostrato sotto il campo quando il formato è corretto
  final String? errore;
  final ValueChanged<String>? onChanged;

  const CampoUsername({
    super.key,
    required this.controller,
    this.mio = true,
    this.helperText = 'Il nome che gli altri vedranno',
    this.errore,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      autocorrect: false,
      autofocus: !mio,
      autofillHints: mio ? const [AutofillHints.newUsername] : null,
      maxLength: Utente.lunghezzaUsername,
      decoration: InputDecoration(
        labelText: 'Username',
        helperText: helperText,
        prefixText: '@',
        errorText: errore,
      ),
      validator: validaUsername,
      onChanged: onChanged,
    );
  }
}

/// Nuova password scritta due volte: il secondo campo controlla che coincida con il primo
class CampiNuovaPassword extends StatelessWidget {
  final TextEditingController password;
  final TextEditingController ripetuta;
  final String etichetta;
  final String etichettaRipetuta;
  final VoidCallback? onInvio;

  const CampiNuovaPassword({
    super.key,
    required this.password,
    required this.ripetuta,
    this.etichetta = 'Nuova password',
    this.etichettaRipetuta = 'Ripeti la nuova password',
    this.onInvio,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CampoPassword(controller: password, etichetta: etichetta, nuova: true, validator: validaPassword),
        const SizedBox(height: 16),
        CampoPassword(
          controller: ripetuta,
          etichetta: etichettaRipetuta,
          nuova: true,
          validator: (valore) => valore == password.text ? null : 'Le password non coincidono',
          onInvio: onInvio,
        ),
      ],
    );
  }
}

/// Campo email con la tastiera adatta e il suggerimento per il riempimento automatico
class CampoEmail extends StatelessWidget {
  final TextEditingController controller;

  /// Permette di validare solo questo campo, senza il resto del form
  final GlobalKey<FormFieldState<String>>? chiaveCampo;

  const CampoEmail({super.key, required this.controller, this.chiaveCampo});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: chiaveCampo,
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      autofillHints: const [AutofillHints.email],
      decoration: const InputDecoration(labelText: 'Email'),
      validator: validaEmail,
    );
  }
}

/// Campo password con l'occhio per mostrare o nascondere il testo
class CampoPassword extends StatefulWidget {
  final TextEditingController controller;
  final String etichetta;
  final FormFieldValidator<String>? validator;

  /// true nella registrazione: suggerisce al telefono di proporre una password nuova
  final bool nuova;

  /// Eseguita quando l'utente preme Invio sulla tastiera
  final VoidCallback? onInvio;

  const CampoPassword({
    super.key,
    required this.controller,
    this.etichetta = 'Password',
    this.validator,
    this.nuova = false,
    this.onInvio,
  });

  @override
  State<CampoPassword> createState() => _CampoPasswordState();
}

class _CampoPasswordState extends State<CampoPassword> {
  bool _nascosta = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _nascosta,
      autocorrect: false,
      enableSuggestions: false,
      autofillHints: [widget.nuova ? AutofillHints.newPassword : AutofillHints.password],
      onFieldSubmitted: (valore) => widget.onInvio?.call(),
      decoration: InputDecoration(
        labelText: widget.etichetta,
        suffixIcon: IconButton(
          tooltip: _nascosta ? 'Mostra password' : 'Nascondi password',
          icon: Icon(_nascosta ? Icons.visibility_off_outlined : Icons.visibility_outlined),
          onPressed: () => setState(() => _nascosta = !_nascosta),
        ),
      ),
      validator: widget.validator,
    );
  }
}

/// Contenitore delle pagine dell'account: contenuto centrato, largo al massimo 420 punti (utile nel browser)
/// e scorrevole quando compare la tastiera
class LayoutAccount extends StatelessWidget {
  final List<Widget> children;

  const LayoutAccount({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
          ),
        ),
      ),
    );
  }
}
