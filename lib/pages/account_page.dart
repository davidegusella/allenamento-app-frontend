import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/workout_store.dart';
import '../widgets/campi_account.dart';
import '../widgets/campi_form.dart';
import '../widgets/dialoghi.dart';
import '../widgets/operazioni.dart';
import '../widgets/pannelli.dart';

/// Account dal menu in alto: username ed email, password ed eliminazione
class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> with OperazioneInCorso {
  // Due form separati: salvare i dati non deve controllare i campi della password, e viceversa
  final _formDati = GlobalKey<FormState>();
  final _formPassword = GlobalKey<FormState>();
  late final _username = TextEditingController(text: context.read<WorkoutStore>().utente?.username ?? '');
  late final _email = TextEditingController(text: context.read<WorkoutStore>().utente?.email ?? '');
  final _password = TextEditingController();
  final _ripetuta = TextEditingController();

  @override
  void dispose() {
    for (final campo in [_username, _email, _password, _ripetuta]) {
      campo.dispose();
    }
    super.dispose();
  }

  Future<void> _salvaDati() async {
    if (!_formDati.currentState!.validate()) {
      return;
    }
    final store = context.read<WorkoutStore>();
    if (await eseguiBloccando(() => store.modificaAccount(_username.text.trim(), _email.text.trim())) && mounted) {
      mostraMessaggio(context, 'Account aggiornato');
    }
  }

  Future<void> _cambiaPassword() async {
    if (!_formPassword.currentState!.validate()) {
      return;
    }
    final store = context.read<WorkoutStore>();
    if (await eseguiBloccando(() => store.cambiaPassword(_password.text)) && mounted) {
      _password.clear();
      _ripetuta.clear();
      mostraMessaggio(context, 'Password cambiata');
    }
  }

  /// Senza utente collegato l'app torna alla pagina di accesso
  Future<void> _eliminaAccount() {
    final store = context.read<WorkoutStore>();
    return seConfermato(
      context,
      'Eliminare l\'account?',
      'Spariscono le tue schede con lo storico, i tuoi post, like e commenti. '
          'Le copie importate dagli altri restano. Non si può annullare.',
      () => eseguiBloccando(store.eliminaAccount),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rosso = Theme.of(context).colorScheme.error;
    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: LayoutAccount(
        children: [
          Form(
            key: _formDati,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CampoUsername(controller: _username),
                const SizedBox(height: 8),
                CampoEmail(controller: _email),
                const SizedBox(height: 24),
                PulsanteInvio(testo: 'Salva', busy: busy, onPressed: _salvaDati),
              ],
            ),
          ),
          const SizedBox(height: 40),
          const Intestazione('Password'),
          Form(
            key: _formPassword,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CampiNuovaPassword(password: _password, ripetuta: _ripetuta, onInvio: _cambiaPassword),
                const SizedBox(height: 24),
                PulsanteInvio(testo: 'Cambia password', busy: busy, onPressed: _cambiaPassword),
              ],
            ),
          ),
          const SizedBox(height: 40),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: rosso, side: BorderSide(color: rosso)),
            onPressed: busy ? null : _eliminaAccount,
            icon: const Icon(Icons.delete_forever_outlined),
            label: const Text('Elimina account'),
          ),
        ],
      ),
    );
  }
}
