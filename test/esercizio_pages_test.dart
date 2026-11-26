import 'package:allenamentofrontend/models/workout.dart';
import 'package:allenamentofrontend/pages/esercizio_page.dart';
import 'package:allenamentofrontend/pages/modifica_esercizio_page.dart';
import 'package:allenamentofrontend/pages/nuovo_esercizio_page.dart';
import 'package:allenamentofrontend/providers/workout_store.dart';
import 'package:allenamentofrontend/services/avviso_timer.dart';
import 'package:allenamentofrontend/widgets/timer_recupero.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dati_di_prova.dart';
import 'server_di_prova.dart';

/// Store che accetta le modifiche agli esercizi; la rilettura delle schede risponde con una lista vuota
WorkoutStore storeEsercizi(List<Map<String, dynamic>> richieste) {
  return storeDiProva({
    'GET /api/plans': [],
    'POST /api/days/7/exercises': {},
    'PUT /api/exercises/5': {},
  }, richieste);
}

/// Avviso finto: invece di usare altoparlante e schermo del telefono registra cosa chiede il timer
class AvvisoFinto extends AvvisoTimer {
  bool allarmeAttivo = false;

  @override
  Future<void> schermoAcceso(bool acceso) async {
    schermoTenutoAcceso = acceso;
  }

  @override
  Future<void> suonaAllarme() async {
    allarmeAttivo = true;
  }

  @override
  Future<void> fermaAllarme() async {
    allarmeAttivo = false;
  }

  @override
  Future<void> chiudi() async {
    allarmeAttivo = false;
    schermoTenutoAcceso = false;
  }
}

/// Apre [pagina] sopra una pagina vuota, così può tornare indietro dopo il salvataggio
Future<void> apri(WidgetTester tester, WorkoutStore store, Widget pagina) async {
  telefonoPiccolo(tester, altezza: 1400);
  await apriSopra(tester, store, pagina);
}

void main() {
  testWidgets('New exercise: name and load are typed, target weight is required', (tester) async {
    final richieste = <Map<String, dynamic>>[];
    await apri(tester, storeEsercizi(richieste), const NuovoEsercizioPage(dayId: 7));

    // Nessuna scritta informativa e nessun elenco di esercizi già esistenti
    expect(find.textContaining('prossimi allenamenti'), findsNothing);
    expect(find.text('Crea un nuovo esercizio'), findsNothing);

    await tester.enterText(find.widgetWithText(TextFormField, 'Nome dell\'esercizio'), 'Panca piana');
    await tester.tap(find.text('Salva esercizio'));
    await tester.pumpAndSettle();
    // Senza carico previsto non si salva
    expect(richieste, isEmpty);
    expect(find.textContaining('Peso non valido'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Carico previsto (kg totali)'), '20,5');
    await tester.enterText(find.widgetWithText(TextFormField, 'Note tecniche'), 'Scapole addotte');
    await tester.tap(find.text('Salva esercizio'));
    await tester.pumpAndSettle();

    expect(modifiche(richieste).single['chiave'], 'POST /api/days/7/exercises');
    expect(modifiche(richieste).single['body'], {
      'name': 'Panca piana',
      'weightMode': 'TOTAL',
      'setCount': 3,
      'repsMin': 8,
      'repsMax': 10,
      'targetWeight': 20.5,
      'restSeconds': 120,
      'notes': 'Scapole addotte',
    });
    // Dopo il salvataggio si torna alla pagina precedente
    expect(find.text('Apri'), findsOneWidget);
  });

  testWidgets('Edit exercise: one row per set, add and delete sets, save last values', (tester) async {
    final richieste = <Map<String, dynamic>>[];
    final exercise = Exercise.fromJson(esercizioDiProva(5, 'Squat', serie: 2, reps: 8, kg: 60));
    await apri(tester, storeEsercizi(richieste), ModificaEsercizioPage(exercise: exercise));

    // Una riga per ogni serie, con gli ultimi valori salvati
    expect(find.text('Serie 1'), findsOneWidget);
    expect(find.text('Serie 2'), findsOneWidget);
    expect(find.text('60'), findsNWidgets(2));

    // Il nome è modificabile e parte da quello attuale
    final campoNome = find.widgetWithText(TextFormField, 'Nome dell\'esercizio');
    expect(tester.widget<TextFormField>(campoNome).controller!.text, 'Squat');
    await tester.enterText(campoNome, 'Squat bulgaro');

    // Prima serie cambiata e terza serie aggiunta, che copia i valori dell'ultima
    final campi = find.widgetWithText(TextFormField, 'Ripetizioni');
    await tester.enterText(campi.at(0), '10');
    await tester.enterText(find.widgetWithText(TextFormField, 'kg totali').at(0), '62,5');
    await tester.tap(find.text('Aggiungi serie'));
    await tester.pumpAndSettle();
    expect(find.text('Serie 3'), findsOneWidget);

    // Seconda serie eliminata
    await tester.tap(find.byTooltip('Elimina serie').at(1));
    await tester.pumpAndSettle();
    expect(find.text('Serie 3'), findsNothing);

    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();

    expect(modifiche(richieste).single['chiave'], 'PUT /api/exercises/5');
    expect(modifiche(richieste).single['body'], {
      'name': 'Squat bulgaro',
      'restSeconds': 120,
      'notes': 'Nota tecnica',
      'sets': [
        {'reps': 10, 'weight': 62.5},
        {'reps': 8, 'weight': 60},
      ],
    });
  });

  testWidgets('Exercise page: sets without add or delete, iPhone style rest timer', (tester) async {
    final richieste = <Map<String, dynamic>>[];
    final exercise = Exercise.fromJson(esercizioDiProva(5, 'Squat', serie: 2, reps: 8, kg: 60));
    await apri(tester, storeEsercizi(richieste), EsercizioPage(exercise: exercise, avviso: AvvisoFinto()));

    // Le serie ci sono, ma non si possono aggiungere né eliminare
    expect(find.text('Serie 1'), findsOneWidget);
    expect(find.text('Serie 2'), findsOneWidget);
    expect(find.text('Aggiungi serie'), findsNothing);
    expect(find.byTooltip('Elimina serie'), findsNothing);
    // Al posto del campo "Recupero in secondi" c'è il timer con le rotelle
    expect(find.widgetWithText(TextFormField, 'Recupero in secondi'), findsNothing);
    expect(find.byType(CupertinoTimerPicker), findsOneWidget);
    final rotelle = tester.widget<CupertinoTimerPicker>(find.byType(CupertinoTimerPicker));
    expect(rotelle.initialTimerDuration, const Duration(seconds: 120));

    // Avvio: compare il conto alla rovescia
    await tester.tap(find.text('Avvia'));
    await tester.pump();
    expect(find.text('2:00'), findsOneWidget);
    expect(find.byType(CupertinoTimerPicker), findsNothing);
    // Lo scorrere dei secondi non si controlla: il timer usa l'orologio vero (DateTime.now)
    // per restare preciso in background, mentre i test usano un tempo simulato

    // Pausa e ripresa
    await tester.tap(find.text('Pausa'));
    await tester.pump();
    expect(find.text('Riprendi'), findsOneWidget);
    await tester.tap(find.text('Riprendi'));
    await tester.pump();
    expect(find.text('Pausa'), findsOneWidget);

    // Annulla: tornano le rotelle
    await tester.tap(find.text('Annulla'));
    await tester.pump();
    expect(find.byType(CupertinoTimerPicker), findsOneWidget);

    // Nuovi valori: nome, recupero e nota restano quelli memorizzati
    await tester.enterText(find.byType(TextFormField).at(0), '10');
    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();
    expect(modifiche(richieste).single['chiave'], 'PUT /api/exercises/5');
    expect(modifiche(richieste).single['body'], {
      'name': 'Squat',
      'restSeconds': 120,
      'notes': 'Nota tecnica',
      'sets': [
        {'reps': 10, 'weight': 60},
        {'reps': 8, 'weight': 60},
      ],
    });
    // Si resta sulla pagina, così il timer non si interrompe
    expect(find.text('Valori salvati'), findsOneWidget);
    expect(find.byType(EsercizioPage), findsOneWidget);
  });

  testWidgets('At zero the alarm rings until Stop, with the screen kept on', (tester) async {
    final avviso = AvvisoFinto();
    await tester.pumpWidget(
      appDiProva(WorkoutStore(), Scaffold(body: TimerRecupero(secondiIniziali: 1, avviso: avviso))),
    );

    await tester.tap(find.text('Avvia'));
    await tester.pump();
    // Durante il conto alla rovescia lo schermo resta acceso
    expect(avviso.schermoTenutoAcceso, isTrue);
    expect(avviso.allarmeAttivo, isFalse);

    // Il timer usa l'orologio vero: si aspetta davvero poco più di un secondo
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 1300)));
    await tester.pump(const Duration(milliseconds: 250));

    // L'allarme suona e resta acceso fino a Stop
    expect(avviso.allarmeAttivo, isTrue);
    expect(find.text('Tempo scaduto!'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    expect(avviso.allarmeAttivo, isTrue);

    await tester.tap(find.text('Stop'));
    await tester.pump();
    expect(avviso.allarmeAttivo, isFalse);
    expect(avviso.schermoTenutoAcceso, isFalse);
    // Tornano le rotelle con la durata iniziale
    expect(find.byType(CupertinoTimerPicker), findsOneWidget);
  });
}
