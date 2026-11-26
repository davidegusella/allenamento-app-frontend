import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/workout_store.dart';
import '../widgets/campi_account.dart';
import '../widgets/campi_form.dart';
import '../widgets/operazioni.dart';
import '../widgets/pannelli.dart';
import 'recupero_password_page.dart';
import 'registrazione_page.dart';

/// Accesso con email e password, all'avvio senza un utente collegato e dopo l'uscita dall'account.
/// Se l'accesso riesce la pagina iniziale mostra la home
class AccessoPage extends StatefulWidget {
  const AccessoPage({super.key});

  @override
  State<AccessoPage> createState() => _AccessoPageState();
}

class _AccessoPageState extends State<AccessoPage> with OperazioneInCorso {
  final _form = GlobalKey<FormState>();
  final _campoEmail = GlobalKey<FormFieldState<String>>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _accedi() async {
    if (busy || !_form.currentState!.validate()) {
      return;
    }
    final store = context.read<WorkoutStore>();
    await eseguiBloccando(() => store.accedi(_email.text.trim(), _password.text));
  }

  /// La nuova password vale per l'email scritta nel campo, che deve essere valida
  Future<void> _passwordDimenticata() async {
    if (!_campoEmail.currentState!.validate()) {
      return;
    }
    final aggiornata = await apriPagina<bool>(context, RecuperoPasswordPage(email: _email.text.trim()));
    if (aggiornata == true && mounted) {
      _password.clear();
      mostraMessaggio(context, 'Password aggiornata: accedi con la nuova password');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: _form,
        // AutofillGroup permette al telefono di proporre email e password salvate
        child: AutofillGroup(
          child: LayoutAccount(
            children: [
              const Center(child: Logo(dimensione: 96, tondo: true)),
              const SizedBox(height: 24),
              Text('Accedi', style: Theme.of(context).textTheme.headlineLarge, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              CampoEmail(controller: _email, chiaveCampo: _campoEmail),
              const SizedBox(height: 16),
              CampoPassword(
                controller: _password,
                validator: (valore) => (valore ?? '').isEmpty ? 'Inserisci la password' : null,
                onInvio: _accedi,
              ),
              const SizedBox(height: 24),
              PulsanteInvio(testo: 'Accedi', testoAttesa: 'Accesso…', busy: busy, onPressed: _accedi),
              const SizedBox(height: 12),
              TextButton(
                onPressed: busy ? null : _passwordDimenticata,
                child: const Text('Password dimenticata?'),
              ),
              TextButton(
                onPressed: busy ? null : () => apriPagina(context, const RegistrazionePage()),
                child: const Text('Non hai un account? Registrati'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
