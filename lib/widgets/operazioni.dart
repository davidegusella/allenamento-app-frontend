import 'package:flutter/material.dart';

/// Mostra [testo] nella SnackBar in basso; non fa nulla se la pagina è già chiusa
void mostraMessaggio(BuildContext context, String testo, {Duration durata = const Duration(seconds: 4)}) {
  if (!context.mounted) {
    return;
  }
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(testo), duration: durata));
}

/// Il testo dell'errore è il suo toString(), per [ApiFailure] il messaggio del backend
void mostraErrore(BuildContext context, Object errore) {
  mostraMessaggio(context, errore.toString(), durata: const Duration(seconds: 6));
}

/// Esegue [operazione] e, se fallisce, ne mostra l'errore. Restituisce true se è riuscita
Future<bool> esegui(BuildContext context, Future<void> Function() operazione) async {
  try {
    await operazione();
    return true;
  } catch (e) {
    if (context.mounted) {
      mostraErrore(context, e);
    }
    return false;
  }
}

/// Esegue [operazione] con [esegui] appena la pagina è disegnata: in initState non si possono ancora
/// mostrare SnackBar
void eseguiDopoIlPrimoFrame(BuildContext context, Future<void> Function() operazione) {
  WidgetsBinding.instance.addPostFrameCallback((tempo) {
    if (context.mounted) {
      esegui(context, operazione);
    }
  });
}

/// Per gli State che disabilitano i pulsanti mentre un'operazione verso il server è in corso,
/// così non partono richieste doppie
mixin OperazioneInCorso<T extends StatefulWidget> on State<T> {
  bool busy = false;

  /// Esegue [operazione] se non ce n'è già un'altra in corso. Restituisce true se è riuscita
  Future<bool> eseguiBloccando(Future<void> Function() operazione) async {
    if (busy) {
      return false;
    }
    setState(() => busy = true);
    final riuscita = await esegui(context, operazione);
    if (mounted) {
      setState(() => busy = false);
    }
    return riuscita;
  }

  /// Funzione per onPressed: null, cioè pulsante disabilitato, durante un'operazione o se non [abilitato]
  VoidCallback? azione(Future<void> Function() operazione, {bool abilitato = true}) {
    if (busy || !abilitato) {
      return null;
    }
    return () => eseguiBloccando(operazione);
  }
}

/// Apre [pagina] sopra quella corrente; il Future termina con il valore passato a Navigator.pop
Future<T?> apriPagina<T>(BuildContext context, Widget pagina) {
  return Navigator.push(context, MaterialPageRoute<T>(builder: (routeContext) => pagina));
}
