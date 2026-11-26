import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/chat_store.dart';
import '../providers/workout_store.dart';
import '../widgets/dialoghi.dart';
import '../widgets/operazioni.dart';
import '../widgets/pannelli.dart';
import 'account_page.dart';
import 'chat_list_page.dart';
import 'classifica_page.dart';
import 'le_mie_page.dart';
import 'per_te_page.dart';

/// Pagina principale con la barra in basso: Le mie (schede, bacheca ed esercizi), Per te, Classifica e
/// Messaggi, con il numero dei messaggi non letti.
///
/// Le pagine aperte con apriPagina vanno in un Navigator interno, sopra la barra, che resta sempre visibile.
/// Toccando una voce, anche quella già selezionata, si torna alla sua pagina iniziale
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  /// Una chiave nuova ricrea il Navigator interno vuoto, con la pagina della voce scelta
  GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  Widget _paginaSelezionata() {
    return switch (_index) {
      0 => const LeMiePage(),
      1 => const PerTePage(),
      2 => const ClassificaPage(),
      _ => const ChatListPage(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final nonLetti = context.watch<ChatStore>().totaleNonLetti;
    // Il tasto indietro di Android chiude la pagina aperta nel Navigator interno, non l'app
    final pagine = NavigatorPopHandler(
      onPopWithResult: (risultato) => _navigatorKey.currentState?.maybePop(),
      child: Navigator(
        key: _navigatorKey,
        onGenerateRoute: (impostazioni) {
          return MaterialPageRoute(builder: (routeContext) => PaginaVoce(child: _paginaSelezionata()));
        },
      ),
    );

    return Scaffold(
      body: pagine,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (valore) {
          setState(() {
            _index = valore;
            _navigatorKey = GlobalKey<NavigatorState>();
          });
        },
        destinations: [
          const NavigationDestination(icon: Icon(Icons.view_agenda_outlined), label: 'Le mie'),
          const NavigationDestination(icon: Icon(Icons.explore_outlined), label: 'Per te'),
          const NavigationDestination(icon: Icon(Icons.emoji_events_outlined), label: 'Classifica'),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: nonLetti > 0,
              label: Text('$nonLetti'),
              child: const Icon(Icons.chat_bubble_outline),
            ),
            label: 'Messaggi',
          ),
        ],
      ),
    );
  }
}

/// Pagina iniziale di una voce della barra in basso: nell'intestazione il logo e il menu dell'account,
/// sotto l'avviso con "Riprova" se l'ultimo caricamento è fallito
class PaginaVoce extends StatelessWidget {
  final Widget child;

  const PaginaVoce({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WorkoutStore>();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        title: const Logo(dimensione: 48, tondo: true),
        actions: [MenuAccount(username: store.utente?.username ?? '')],
      ),
      body: Column(
        children: [
          if (store.error != null)
            MaterialBanner(
              content: Text(store.error!),
              actions: [TextButton(onPressed: () => esegui(context, store.ricarica), child: const Text('Riprova'))],
            ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Icona dell'account in alto a destra: il menu mostra lo username e le voci "Account" ed "Esci"
class MenuAccount extends StatelessWidget {
  final String username;

  const MenuAccount({super.key, required this.username});

  /// La pagina iniziale mostra di nuovo l'accesso
  Future<void> _esci(BuildContext context) {
    final store = context.read<WorkoutStore>();
    return seConfermato(context, 'Uscire dall\'account?', 'Per rientrare servono email e password.', store.esci);
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Account',
      icon: const Icon(Icons.account_circle_outlined),
      onSelected: (voce) {
        if (voce == 'account') {
          apriPagina(context, const AccountPage());
        } else if (voce == 'esci') {
          _esci(context);
        }
      },
      itemBuilder: (menuContext) {
        return [
          // Voce non selezionabile: chi è collegato
          PopupMenuItem<String>(enabled: false, child: Text('@$username')),
          const PopupMenuDivider(),
          const PopupMenuItem<String>(
            value: 'account',
            child: ListTile(
                contentPadding: EdgeInsets.zero, leading: Icon(Icons.manage_accounts_outlined), title: Text('Account')),
          ),
          const PopupMenuItem<String>(
            value: 'esci',
            child: ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.logout), title: Text('Esci')),
          ),
        ];
      },
    );
  }
}
