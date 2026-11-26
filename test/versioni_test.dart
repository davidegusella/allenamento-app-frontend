import 'package:allenamentofrontend/models/post.dart';
import 'package:allenamentofrontend/models/workout.dart';
import 'package:allenamentofrontend/pages/plans_page.dart';
import 'package:allenamentofrontend/pages/post_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dati_di_prova.dart';
import 'server_di_prova.dart';

/// Risposte per l'importazione del post 9, versione nuova della copia 1 (importata dal post 5)
Map<String, Object?> risposteImportazione() {
  return {
    'GET /api/posts/9/comments': [],
    'POST /api/posts/9/import?replace=1': forza(importedFrom: 'marco'),
    'POST /api/posts/9/import': forza(importedFrom: 'marco'),
    'GET /api/plans': [forza(importedFrom: 'marco')],
    'GET /api/posts/per-te': [],
  };
}

Post versioneNuova() {
  return Post.fromJson(postDiProva(9, 'marco', forza(), myCopyPlanId: 1, myCopyPostId: 5));
}

void main() {
  testWidgets('Importing a post I already have says which copy I have', (tester) async {
    final store = storeDiProva({'GET /api/posts/5/comments': [], 'GET /api/posts/9/comments': []}, []);

    await tester.pumpWidget(appDiProva(store, PostPage(post: versioneNuova())));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Importa nelle mie schede'));
    await tester.pumpAndSettle();
    expect(find.text('Hai una versione precedente di questa scheda'), findsOneWidget);
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();

    final stessa = Post.fromJson(postDiProva(5, 'marco', forza(), myCopyPlanId: 1, myCopyPostId: 5));
    await tester.pumpWidget(appDiProva(store, PostPage(key: UniqueKey(), post: stessa)));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Importa nelle mie schede'));
    await tester.pumpAndSettle();
    expect(find.text('Hai già importato questa scheda'), findsOneWidget);
  });

  testWidgets('With a copy, Import asks whether to replace it', (tester) async {
    final richieste = <Map<String, dynamic>>[];
    final store = storeDiProva(risposteImportazione(), richieste);

    await tester.pumpWidget(appDiProva(store, PostPage(post: versioneNuova())));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Importa nelle mie schede'));
    await tester.pumpAndSettle();
    expect(find.textContaining('kg compresi'), findsOneWidget);
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();
    expect(chiavi(richieste).where((c) => c.toString().contains('import')), isEmpty);

    await tester.tap(find.byTooltip('Importa nelle mie schede'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sostituisci la mia copia'));
    await tester.pumpAndSettle();
    expect(chiavi(richieste), contains('POST /api/posts/9/import?replace=1'));
    expect(find.text('Copia sostituita'), findsOneWidget);
  });

  testWidgets('With a copy, Import as new creates another copy', (tester) async {
    final richieste = <Map<String, dynamic>>[];
    final store = storeDiProva(risposteImportazione(), richieste);

    await tester.pumpWidget(appDiProva(store, PostPage(post: versioneNuova())));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Importa nelle mie schede'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Importa come nuova'));
    await tester.pumpAndSettle();

    expect(chiavi(richieste), contains('POST /api/posts/9/import'));
    expect(chiavi(richieste), isNot(contains('POST /api/posts/9/import?replace=1')));
    expect(find.text('Scheda importata nelle tue schede'), findsOneWidget);
  });

  testWidgets('A copy with a new version links to the new post', (tester) async {
    telefonoPiccolo(tester);
    final richieste = <Map<String, dynamic>>[];
    final store = storeDiProva({
      'GET /api/posts/9': postDiProva(9, 'marco', forza(), myCopyPlanId: 1, myCopyPostId: 5),
      'GET /api/posts/9/comments': [],
    }, richieste);
    store.impostaPerTest(
        plans: Plan.listaDaJson([
      schedaDiProva(1, 'Forza', [[]], importedFrom: 'marco', importedPostId: 5, newVersionPostId: 9),
      schedaDiProva(2, 'Mia', [[]]),
    ]));

    await tester.pumpWidget(appDiProva(store, const Scaffold(body: PlansPage())));
    expect(find.text('Nuova versione di @marco disponibile'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Nuova versione di @marco disponibile'));
    await tester.pumpAndSettle();

    expect(chiavi(richieste).first, 'GET /api/posts/9');
    expect(find.byType(PostPage), findsOneWidget);
    expect(find.text('Forza'), findsWidgets);
  });
}
