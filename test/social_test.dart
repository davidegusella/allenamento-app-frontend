import 'package:allenamentofrontend/models/post.dart';
import 'package:allenamentofrontend/pages/bacheca_page.dart';
import 'package:allenamentofrontend/pages/per_te_page.dart';
import 'package:allenamentofrontend/pages/post_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dati_di_prova.dart';
import 'server_di_prova.dart';

void main() {
  testWidgets('The heart sends PUT, then DELETE, and updates the count', (tester) async {
    final richieste = <Map<String, dynamic>>[];
    final store = storeDiProva({
      'GET /api/posts/per-te': [postDiProva(5, 'marco', forza(), likeCount: 2)],
      'PUT /api/posts/5/like': postDiProva(5, 'marco', forza(), likeCount: 3, likedByMe: true),
      'DELETE /api/posts/5/like': postDiProva(5, 'marco', forza(), likeCount: 2),
    }, richieste);

    await tester.pumpWidget(appDiProva(store, const Scaffold(body: PerTePage())));
    await tester.pumpAndSettle();
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.byTooltip('Mi piace'));
    await tester.pumpAndSettle();
    expect(richieste.last['chiave'], 'PUT /api/posts/5/like');
    expect(find.text('3'), findsOneWidget);

    await tester.tap(find.byTooltip('Togli mi piace'));
    await tester.pumpAndSettle();
    expect(richieste.last['chiave'], 'DELETE /api/posts/5/like');
    expect(find.text('2'), findsOneWidget);
    expect(find.byTooltip('Mi piace'), findsOneWidget);
  });

  testWidgets('My own posts show the likes but the heart cannot be tapped', (tester) async {
    final richieste = <Map<String, dynamic>>[];
    final store = storeDiProva({'GET /api/posts/6/comments': []}, richieste);
    final post = Post.fromJson(postDiProva(6, 'davide', forza(), likeCount: 4));

    await tester.pumpWidget(appDiProva(store, PostPage(post: post)));
    await tester.pumpAndSettle();

    expect(find.text('4'), findsOneWidget);
    await tester.tap(find.byTooltip('Mi piace'));
    await tester.pumpAndSettle();
    expect(chiavi(richieste), isNot(contains('PUT /api/posts/6/like')));
  });

  testWidgets('The most liked ranking of my posts shows positions on a small phone', (tester) async {
    telefonoPiccolo(tester);
    final richieste = <Map<String, dynamic>>[];
    final store = storeDiProva({
      'GET /api/posts/mine?ordine=IMPORTATE': [],
      'GET /api/posts/mine?ordine=PIACIUTE': [
        postDiProva(4, 'davide', schedaDiProva(2, 'Full body', [[]]), likeCount: 7),
        postDiProva(5, 'davide', forza(), likeCount: 1),
      ],
    }, richieste);

    await tester.pumpWidget(appDiProva(store, const Scaffold(body: BachecaPage())));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Più piaciute'));
    await tester.pumpAndSettle();

    expect(richieste.last['chiave'], 'GET /api/posts/mine?ordine=PIACIUTE');
    expect(find.text('1.'), findsOneWidget);
    expect(find.text('2.'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Comments can be written, and only mine can be deleted', (tester) async {
    final richieste = <Map<String, dynamic>>[];
    final store = storeDiProva({
      'GET /api/posts/5/comments': [
        commentoDiProva(1, 'marco', 'Provala con 3 minuti di recupero'),
        commentoDiProva(2, 'davide', 'Grazie!'),
      ],
      'POST /api/posts/5/comments': commentoDiProva(3, 'davide', 'Fatta oggi'),
      'DELETE /api/comments/2': null,
      'GET /api/posts/5': postDiProva(5, 'marco', forza(), commentCount: 1),
    }, richieste);
    final post = Post.fromJson(postDiProva(5, 'marco', forza()));

    await tester.pumpWidget(appDiProva(store, PostPage(post: post)));
    await tester.pumpAndSettle();

    expect(find.text('Provala con 3 minuti di recupero'), findsOneWidget);
    expect(find.text('@marco · 21/11/2026'), findsOneWidget);
    // Il cestino compare solo sul commento di davide, l'utente collegato
    expect(find.byTooltip('Elimina commento'), findsOneWidget);

    await tester.scrollUntilVisible(find.byType(TextField), 200, scrollable: find.byType(Scrollable).first);
    await tester.enterText(find.byType(TextField), '  Fatta oggi  ');
    await tester.pump();
    await tester.ensureVisible(find.byTooltip('Invia commento'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Invia commento'));
    await tester.pumpAndSettle();
    final invio = richieste.firstWhere((r) => r['chiave'] == 'POST /api/posts/5/comments');
    expect(invio['body'], {'text': 'Fatta oggi'});
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);

    await tester.ensureVisible(find.byTooltip('Elimina commento'));
    await tester.tap(find.byTooltip('Elimina commento'));
    await tester.pumpAndSettle();
    expect(find.text('Eliminare il commento?'), findsOneWidget);
    await tester.tap(find.text('Conferma'));
    await tester.pumpAndSettle();
    expect(chiavi(richieste), contains('DELETE /api/comments/2'));
    expect(richieste.last['chiave'], 'GET /api/posts/5');
  });

  testWidgets('My post can be deleted after confirmation; others cannot', (tester) async {
    final richieste = <Map<String, dynamic>>[];
    final store = storeDiProva({
      'GET /api/posts/6/comments': [],
      'GET /api/posts/5/comments': [],
      'DELETE /api/posts/6': null,
    }, richieste);
    final mio = postDiProva(6, 'davide', forza());
    store.bacheca[OrdineClassifica.importate] = Post.listaDaJson([mio]);
    store.impostaPerTest(perTe: Post.listaDaJson([postDiProva(5, 'marco', forza())]));

    await tester.pumpWidget(appDiProva(store, PostPage(post: Post.fromJson(postDiProva(5, 'marco', forza())))));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Elimina post'), findsNothing);

    // Il proprio post si apre sopra una pagina vuota, per controllare che si chiuda dopo l'eliminazione
    await apriSopra(tester, store, PostPage(post: Post.fromJson(mio)));

    await tester.tap(find.byTooltip('Elimina post'));
    await tester.pumpAndSettle();
    expect(find.text('Eliminare il post?'), findsOneWidget);
    await tester.tap(find.text('Conferma'));
    await tester.pumpAndSettle();

    expect(chiavi(richieste), contains('DELETE /api/posts/6'));
    expect(find.byType(PostPage), findsNothing);
    expect(find.text('Post eliminato'), findsOneWidget);
    expect(store.bacheca[OrdineClassifica.importate], isEmpty);
    expect(store.perTe.map((post) => post.id), [5]);
  });
}
