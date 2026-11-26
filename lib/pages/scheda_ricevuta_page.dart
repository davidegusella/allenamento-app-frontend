import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat.dart';
import '../models/workout.dart';
import '../providers/chat_store.dart';
import '../providers/workout_store.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/dialoghi.dart';
import '../widgets/operazioni.dart';
import '../widgets/pulsante_importa.dart';
import '../widgets/vista_scheda.dart';
import 'post_page.dart';

/// Apre la scheda inviata nel messaggio: un post nella sua pagina, una scheda personale in [SchedaRicevutaPage].
/// Se nel frattempo è stata eliminata compare un avviso
Future<void> apriSchedaInviata(BuildContext context, Messaggio messaggio) async {
  final scheda = messaggio.scheda!;
  final postId = scheda.postId;
  await conAvvisoEliminata(context, () async {
    final Widget pagina;
    if (postId != null) {
      pagina = PostPage(post: await context.read<WorkoutStore>().caricaPost(postId));
    } else {
      pagina = SchedaRicevutaPage(
          messaggio: messaggio, plan: await context.read<ChatStore>().caricaSchedaRicevuta(messaggio.id));
    }
    if (context.mounted) {
      apriPagina(context, pagina);
    }
  });
}

/// Esegue [operazione]; se la scheda non esiste più (404) mostra [SchedaInviata.avvisoEliminata] in un dialog,
/// gli altri errori nella SnackBar come [esegui]
Future<void> conAvvisoEliminata(BuildContext context, Future<void> Function() operazione) async {
  await esegui(context, () async {
    try {
      await operazione();
    } on ApiFailure catch (e) {
      if (e.status != 404) {
        rethrow;
      }
      if (context.mounted) {
        await avvisa(context, 'Scheda eliminata', SchedaInviata.avvisoEliminata);
      }
    }
  });
}

/// Scheda personale ricevuta in chat, in sola lettura e com'è adesso; chi l'ha ricevuta la può importare
class SchedaRicevutaPage extends StatefulWidget {
  final Messaggio messaggio;
  final Plan plan;

  const SchedaRicevutaPage({super.key, required this.messaggio, required this.plan});

  @override
  State<SchedaRicevutaPage> createState() => _SchedaRicevutaPageState();
}

class _SchedaRicevutaPageState extends State<SchedaRicevutaPage> with OperazioneInCorso {
  Future<void> _importa() async {
    final store = context.read<WorkoutStore>();
    var importata = false;
    await conAvvisoEliminata(context, () async {
      await store.importaDaChat(widget.messaggio.id);
      importata = true;
    });
    if (importata && mounted) {
      mostraMessaggio(context, messaggioImportata);
    }
  }

  @override
  Widget build(BuildContext context) {
    final contenuto = <Widget>[
      Text('Inviata da @${widget.messaggio.scheda!.autore}', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 16),
      VistaScheda(plan: widget.plan),
    ];
    if (!widget.messaggio.mio) {
      contenuto.add(const SizedBox(height: 8));
      contenuto.add(FilledButton.icon(
        onPressed: azione(_importa),
        icon: const Icon(Icons.download_outlined),
        label: const Text('Importa nelle mie schede'),
      ));
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.plan.name)),
      body: ListView(padding: marginePagina, children: contenuto),
    );
  }
}
