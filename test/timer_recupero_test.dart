import 'package:allenamentofrontend/providers/workout_store.dart';
import 'package:allenamentofrontend/widgets/timer_recupero.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'server_di_prova.dart';

/// Se la finestra diventa larga zero (browser ridimensionato o ridotto a icona)
/// le rotelle non devono generare errori di disegno, e devono ricomparire
/// quando la finestra torna normale
void main() {
  testWidgets('Timer picker survives a zero-width window', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      appDiProva(WorkoutStore(), const Scaffold(body: TimerRecupero(secondiIniziali: 120))),
    );
    expect(find.byType(CupertinoTimerPicker), findsOneWidget);

    tester.view.physicalSize = const Size(0, 800);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(CupertinoTimerPicker), findsNothing);

    tester.view.resetPhysicalSize();
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(CupertinoTimerPicker), findsOneWidget);
  });
}
