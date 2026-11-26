import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'pages/accesso_page.dart';
import 'pages/connection_page.dart';
import 'pages/home_page.dart';
import 'providers/chat_store.dart';
import 'providers/workout_store.dart';
import 'theme/app_theme.dart';
import 'widgets/pannelli.dart';

/// Rende disponibili a tutte le pagine lo stato dei dati (WorkoutStore) e quello delle chat
/// (ChatStore, che segue l'utente collegato)
void main() {
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: creaStore),
      providerChat((context) => ChatStore()),
    ],
    child: const MyApp(),
  ));
}

/// Lo store, con il primo caricamento dei dati già avviato
WorkoutStore creaStore(BuildContext context) {
  return WorkoutStore()..avvia();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Allenamento App',
      locale: const Locale('it', 'IT'),
      supportedLocales: const [Locale('it', 'IT')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: graphiteTheme(),
      home: const SplashPage(),
    );
  }
}

/// Pagina di avvio: mentre il logo si ingrandisce l'app controlla il token salvato e carica i dati.
/// Poi mostra la home se l'utente è collegato, la pagina di connessione se il backend non risponde,
/// altrimenti l'accesso
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late final AnimationController _animazione = AnimationController(vsync: this, duration: const Duration(seconds: 1));

  // easeOutBack supera di poco la dimensione finale e torna indietro: il logo "rimbalza"
  late final Animation<double> _zoom = CurvedAnimation(parent: _animazione, curve: Curves.easeOutBack);
  bool _animazioneFinita = false;

  /// true se al disegno precedente l'utente era collegato
  bool _eraCollegato = false;

  @override
  void initState() {
    super.initState();
    _animazione.forward().then((valore) {
      if (mounted) {
        setState(() => _animazioneFinita = true);
      }
    });
  }

  @override
  void dispose() {
    _animazione.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WorkoutStore>();

    if (!_animazioneFinita || store.booting) {
      return Scaffold(body: Center(child: ScaleTransition(scale: _zoom, child: const Logo(dimensione: 160))));
    }

    final collegato = store.utente != null;
    // Uscendo dall'account (o con la sessione scaduta) da una pagina aperta sopra la home, quelle pagine
    // si chiudono e resta visibile l'accesso. Dopo il frame, perché durante build non si può navigare
    if (_eraCollegato && !collegato) {
      WidgetsBinding.instance.addPostFrameCallback((tempo) {
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      });
    }
    _eraCollegato = collegato;

    if (collegato) {
      return const HomePage();
    }
    if (store.error != null) {
      return const ConnectionPage();
    }
    return const AccessoPage();
  }
}
