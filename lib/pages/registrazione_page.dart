import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/workout_store.dart';
import '../widgets/campi_account.dart';
import '../widgets/campi_form.dart';
import '../widgets/operazioni.dart';

/// Nuovo account: username, email, password e conferma. Si apre dalla pagina di accesso;
/// dopo la registrazione l'utente è già collegato e si torna alla pagina iniziale, che mostra la home
class RegistrazionePage extends StatefulWidget {
  const RegistrazionePage({super.key});

  @override
  State<RegistrazionePage> createState() => _RegistrazionePageState();
}

class _RegistrazionePageState extends State<RegistrazionePage> with OperazioneInCorso {
  final _form = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _conferma = TextEditingController();

  @override
  void dispose() {
    for (final campo in [_username, _email, _password, _conferma]) {
      campo.dispose();
    }
    super.dispose();
  }

  Future<void> _registrati() async {
    if (busy || !_form.currentState!.validate()) {
      return;
    }
    final store = context.read<WorkoutStore>();
    final registrato =
        await eseguiBloccando(() => store.registrati(_username.text.trim(), _email.text.trim(), _password.text));
    if (registrato && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crea un account')),
      body: Form(
        key: _form,
        child: AutofillGroup(
          child: LayoutAccount(
            children: [
              CampoUsername(controller: _username),
              const SizedBox(height: 8),
              CampoEmail(controller: _email),
              const SizedBox(height: 16),
              CampiNuovaPassword(
                password: _password,
                ripetuta: _conferma,
                etichetta: 'Password',
                etichettaRipetuta: 'Conferma password',
                onInvio: _registrati,
              ),
              const SizedBox(height: 24),
              PulsanteInvio(testo: 'Crea account', testoAttesa: 'Creazione…', busy: busy, onPressed: _registrati),
            ],
          ),
        ),
      ),
    );
  }
}
