import 'package:allenamentofrontend/models/post.dart';
import 'package:allenamentofrontend/models/workout.dart';
import 'package:allenamentofrontend/pages/bacheca_page.dart';
import 'package:allenamentofrontend/pages/classifica_page.dart';
import 'package:allenamentofrontend/pages/per_te_page.dart';
import 'package:allenamentofrontend/pages/plans_page.dart';
import 'package:allenamentofrontend/pages/post_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dati_di_prova.dart';
import 'server_di_prova.dart';

void main() {
  testWidgets('Per te shows the posts of others with like, comments and import on the card', (tester) async {
    telefonoPiccolo(tester);
    final richieste = <Map<String, dynamic>>[];
    final store = storeDiProva({
      'GET /api/posts/per-te': [
        postDiProva(5, 'marco', forza(), importCount: 1, commentCount: 2),
        postDiProva(4, 'giulia', schedaDiProva(2, 'Full body', [[], []]), importCount: 3),
      ],
    }, richieste);

    await tester.pumpWidget(appDiProva(store, const Scaffold(body: PerTePage())));
    await tester.pumpAndSettle();

    expect(richieste.single['chiave'], 'GET /api/posts/per-te');
    expect(find.text('@marco · 20/11/2026\n1 giornata · 1 importazione'), findsOneWidget);
    expect(find.text('@giulia · 20/11/2026\n2 giornate · 3 importazioni'), findsOneWidget);
    expect(find.text('1.'), findsNothing);
    expect(find.byTooltip('Mi piace'), findsNWidgets(2));
    expect(find.byTooltip('Commenti'), findsNWidgets(2));
    expect(find.text('Importa'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('The Bacheca ranks my posts with positions, without Import', (tester) async {
    telefonoPiccolo(tester);
    final richieste = <Map<String, dynamic>>[];
    final store = storeDiProva({
      'GET /api/posts/mine?ordine=IMPORTATE': [
        postDiProva(4, 'davide', schedaDiProva(2, 'Full body', [[], []]), importCount: 3),
        postDiProva(5, 'davide', forza(), importCount: 0),
      ],
      'GET /api/posts/mine?ordine=PIACIUTE': [],
    }, richieste);

    await tester.pumpWidget(appDiProva(store, const Scaffold(body: BachecaPage())));
    await tester.pumpAndSettle();

    expect(richieste.single['chiave'], 'GET /api/posts/mine?ordine=IMPORTATE');
    expect(find.text('Recenti'), findsNothing);
    expect(tester.getTopLeft(find.text('Full body')).dy, lessThan(tester.getTopLeft(find.text('Forza')).dy));
    expect(find.text('1.'), findsOneWidget);
    expect(find.text('2.'), findsOneWidget);
    expect(find.text('Importa'), findsNothing);

    await tester.tap(find.text('Più piaciute'));
    await tester.pumpAndSettle();
    expect(richieste.last['chiave'], 'GET /api/posts/mine?ordine=PIACIUTE');
    expect(find.text('Nessuna tua scheda pubblicata'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('The Classifica ranks the posts of everyone, by likes first', (tester) async {
    telefonoPiccolo(tester);
    final richieste = <Map<String, dynamic>>[];
    final store = storeDiProva({
      'GET /api/posts/classifica?ordine=PIACIUTE': [
        postDiProva(4, 'marco', schedaDiProva(2, 'Full body', [[], []]), likeCount: 7),
        postDiProva(5, 'davide', forza(), likeCount: 3),
      ],
      'GET /api/posts/classifica?ordine=IMPORTATE': [],
    }, richieste);

    await tester.pumpWidget(appDiProva(store, const Scaffold(body: ClassificaPage())));
    await tester.pumpAndSettle();

    expect(richieste.single['chiave'], 'GET /api/posts/classifica?ordine=PIACIUTE');
    expect(tester.getTopLeft(find.text('Full body')).dy, lessThan(tester.getTopLeft(find.text('Forza')).dy));
    expect(find.text('1.'), findsOneWidget);
    expect(find.text('2.'), findsOneWidget);
    // Il proprio post non si importa e non riceve like: solo quelli degli altri
    expect(find.text('Importa'), findsOneWidget);

    await tester.tap(find.text('Più importate'));
    await tester.pumpAndSettle();
    expect(richieste.last['chiave'], 'GET /api/posts/classifica?ordine=IMPORTATE');
    expect(find.text('Ancora nessuna scheda in classifica'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('From the card I can import and comment without opening the post', (tester) async {
    telefonoPiccolo(tester);
    final richieste = <Map<String, dynamic>>[];
    final store = storeDiProva({
      'GET /api/posts/per-te': [postDiProva(5, 'marco', forza())],
      'POST /api/posts/5/import': forza(importedFrom: 'marco'),
      'GET /api/plans': [forza(importedFrom: 'marco')],
      'GET /api/posts/5/comments': [],
      'POST /api/posts/5/comments': commentoDiProva(3, 'davide', 'Bella'),
      'GET /api/posts/5': postDiProva(5, 'marco', forza(), commentCount: 1),
    }, richieste);

    await tester.pumpWidget(appDiProva(store, const Scaffold(body: PerTePage())));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Importa'));
    await tester.pumpAndSettle();
    expect(chiavi(richieste), contains('POST /api/posts/5/import'));
    expect(find.text('Scheda importata nelle tue schede'), findsOneWidget);
    expect(find.byType(PostPage), findsNothing);

    await tester.tap(find.byTooltip('Commenti'));
    await tester.pumpAndSettle();
    expect(find.text('Nessun commento'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Bella');
    await tester.pump();
    await tester.tap(find.byTooltip('Invia commento'));
    await tester.pumpAndSettle();

    expect(chiavi(richieste), contains('POST /api/posts/5/comments'));
    expect(store.perTe.single.commentCount, 1);
    expect(find.byType(PostPage), findsNothing);
  });

  testWidgets('A post of someone else can be imported, with sets and kg visible', (tester) async {
    final richieste = <Map<String, dynamic>>[];
    final store = storeDiProva({
      'POST /api/posts/5/import': forza(importedFrom: 'marco'),
      'GET /api/posts/5/comments': [],
      'GET /api/plans': [forza(importedFrom: 'marco')],
      'GET /api/posts/per-te': [postDiProva(5, 'marco', forza(), importCount: 1)],
    }, richieste);
    final post = Post.fromJson(postDiProva(5, 'marco', forza()));

    await tester.pumpWidget(appDiProva(store, PostPage(post: post)));

    expect(find.text('@marco'), findsOneWidget);
    expect(find.text('Serie 1: 10 × 20 kg per lato'), findsOneWidget);
    expect(find.textContaining('0 importazioni'), findsOneWidget);

    await tester.tap(find.byTooltip('Importa nelle mie schede'));
    await tester.pumpAndSettle();

    expect(chiavi(richieste), contains('POST /api/posts/5/import'));
    expect(find.text('Scheda importata nelle tue schede'), findsOneWidget);
    // Il contatore si aggiorna con "Per te" ricaricata
    expect(find.textContaining('1 importazione'), findsOneWidget);
    expect(store.plans.single.importedFrom, 'marco');
  });

  testWidgets('My own posts cannot be imported', (tester) async {
    final store = storeDiProva({'GET /api/posts/6/comments': []}, []);
    final post = Post.fromJson(postDiProva(6, 'davide', forza()));

    await tester.pumpWidget(appDiProva(store, PostPage(post: post)));

    expect(find.byTooltip('Importa nelle mie schede'), findsNothing);
  });

  testWidgets('Publishing asks for confirmation; imported plans show their author', (tester) async {
    telefonoPiccolo(tester);
    final richieste = <Map<String, dynamic>>[];
    final store = storeDiProva({
      'POST /api/plans/1/publish': postDiProva(9, 'davide', forza()),
      'GET /api/posts/mine?ordine=IMPORTATE': [postDiProva(9, 'davide', forza())],
      'GET /api/posts/mine?ordine=PIACIUTE': [postDiProva(9, 'davide', forza())],
    }, richieste);
    store.impostaPerTest(
        plans: Plan.listaDaJson([
      forza(),
      schedaDiProva(3, 'Presa da Marco', [[]], importedFrom: 'marco'),
    ]));

    await tester.pumpWidget(appDiProva(store, const Scaffold(body: PlansPage())));

    expect(find.textContaining('da @marco'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // La scheda senza esercizi non si può pubblicare
    final pubblica = find.ancestor(of: find.byTooltip('Pubblica'), matching: find.byType(IconButton));
    expect(tester.widget<IconButton>(pubblica.last).onPressed, isNull);

    await tester.tap(pubblica.first);
    await tester.pumpAndSettle();
    expect(find.text('Pubblicare Forza?'), findsOneWidget);
    expect(richieste, isEmpty);

    await tester.tap(find.text('Conferma'));
    await tester.pumpAndSettle();

    expect(richieste.first['chiave'], 'POST /api/plans/1/publish');
    expect(find.text('Scheda pubblicata'), findsOneWidget);
    expect(store.bacheca[OrdineClassifica.importate]!.single.id, 9);
  });

  testWidgets('Deleting a plan warns about its posts and reloads the Bacheca', (tester) async {
    final richieste = <Map<String, dynamic>>[];
    final store = storeDiProva({
      'DELETE /api/plans/1': null,
      'GET /api/plans': [],
      'GET /api/posts/mine?ordine=IMPORTATE': [],
      'GET /api/posts/mine?ordine=PIACIUTE': [],
    }, richieste);
    store.impostaPerTest(plans: Plan.listaDaJson([forza()]));
    store.bacheca[OrdineClassifica.importate] = Post.listaDaJson([postDiProva(9, 'davide', forza())]);

    await tester.pumpWidget(appDiProva(store, const Scaffold(body: PlansPage())));
    await tester.tap(find.byTooltip('Elimina scheda'));
    await tester.pumpAndSettle();
    expect(find.textContaining('tutti i post'), findsOneWidget);
    await tester.tap(find.text('Conferma'));
    await tester.pumpAndSettle();

    expect(chiavi(richieste), containsAll(['DELETE /api/plans/1', 'GET /api/posts/mine?ordine=IMPORTATE']));
    expect(store.bacheca[OrdineClassifica.importate], isEmpty);
    expect(store.plans, isEmpty);
  });
}
