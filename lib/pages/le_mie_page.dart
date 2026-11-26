import 'package:flutter/material.dart';

import 'bacheca_page.dart';
import 'exercise_catalog_page.dart';
import 'plans_page.dart';

/// Voce "Le mie" della barra in basso: tutto ciò che è mio, diviso in tre schede interne.
/// Si passa dall'una all'altra toccando l'etichetta o scorrendo di lato.
class LeMiePage extends StatelessWidget {
  const LeMiePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 3,
      child: Column(
        children: [
          // Il bordo fa da binario alla pillola lilla della scheda scelta
          Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: DecoratedBox(
              decoration: ShapeDecoration(shape: StadiumBorder(side: BorderSide(color: Colors.white12))),
              child: Padding(
                padding: EdgeInsets.all(4),
                child: TabBar(tabs: [Tab(text: 'Schede'), Tab(text: 'Bacheca'), Tab(text: 'Esercizi')]),
              ),
            ),
          ),
          Expanded(child: TabBarView(children: [PlansPage(), BachecaPage(), ExerciseCatalogPage()])),
        ],
      ),
    );
  }
}
