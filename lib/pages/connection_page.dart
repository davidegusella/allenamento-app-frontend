import 'package:flutter/material.dart';

import '../widgets/pannelli.dart';

/// Pagina mostrata all'avvio se il backend non risponde: solo logo e messaggio
class ConnectionPage extends StatelessWidget {
  const ConnectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Logo(dimensione: 160),
            const SizedBox(height: 24),
            Text('Backend non raggiungibile', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}
