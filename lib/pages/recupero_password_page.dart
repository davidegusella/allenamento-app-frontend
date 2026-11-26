import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/workout_store.dart';
import '../theme/app_theme.dart';
import '../widgets/campi_account.dart';
import '../widgets/campi_form.dart';
import '../widgets/operazioni.dart';

/// "Password dimenticata?": la nuova password, scritta due volte, per l'email scritta nella pagina Accedi.
/// Si chiude con true se la password è stata cambiata
class RecuperoPasswordPage extends StatefulWidget {
  final String email;

  const RecuperoPasswordPage({super.key, required this.email});

  @override
  State<RecuperoPasswordPage> createState() => _RecuperoPasswordPageState();
}

class _RecuperoPasswordPageState extends State<RecuperoPasswordPage> with OperazioneInCorso {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _ripetuta = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    _ripetuta.dispose();
    super.dispose();
  }

  Future<void> _cambiaPassword() async {
    if (busy || !_form.currentState!.validate()) {
      return;
    }
    final store = context.read<WorkoutStore>();
    if (await eseguiBloccando(() => store.reimpostaPassword(widget.email, _password.text)) && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Form(
        key: _form,
        child: LayoutAccount(
          children: [
            Text('Nuova password', style: Theme.of(context).textTheme.headlineLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(widget.email, textAlign: TextAlign.center, style: testoSecondario),
            const SizedBox(height: 24),
            CampiNuovaPassword(password: _password, ripetuta: _ripetuta, onInvio: _cambiaPassword),
            const SizedBox(height: 24),
            PulsanteInvio(testo: 'Cambia password', busy: busy, onPressed: _cambiaPassword),
          ],
        ),
      ),
    );
  }
}
