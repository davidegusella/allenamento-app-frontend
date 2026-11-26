import '../utils/formato.dart';
import 'workout.dart';

/// Classifiche dei post, nella Bacheca (solo i miei) e nella Classifica (di tutti),
/// con il valore atteso dal backend (GET /posts/mine?ordine=... e GET /posts/classifica?ordine=...)
enum OrdineClassifica {
  importate('IMPORTATE', 'Più importate'),
  piaciute('PIACIUTE', 'Più piaciute');

  final String parametro;
  final String etichetta;

  const OrdineClassifica(this.parametro, this.etichetta);
}

/// Rapporto fra il post e le copie che l'utente collegato ha già della stessa scheda
enum StatoCopia {
  nessuna(null),
  questa('Hai già importato questa scheda'),
  precedente('Hai una versione precedente di questa scheda'),
  successiva('Hai già una versione più recente di questa scheda');

  /// Testo da mostrare sotto il pulsante Importa; null se non c'è nessuna copia
  final String? avviso;

  const StatoCopia(this.avviso);
}

/// Post della bacheca: copia fissa di una scheda al momento della pubblicazione (PostResponseDto)
class Post {
  final int id;

  /// Username di chi ha pubblicato
  final String author;
  final DateTime createdAt;

  /// Persone diverse che hanno importato il post
  final int importCount;

  /// Persone diverse che hanno messo like
  final int likeCount;
  final int commentCount;

  /// true se l'utente collegato ha messo like
  final bool likedByMe;

  /// La copia più recente che l'utente collegato ha di questa scheda, di qualsiasi versione; null se non ne ha
  final int? myCopyPlanId;

  /// Il post da cui viene quella copia: un id più piccolo è una versione precedente
  final int? myCopyPostId;
  final Plan plan;

  Post.fromJson(Json json)
      : id = json['id'],
        author = json['author'],
        createdAt = dataLocale(json['createdAt']),
        importCount = json['importCount'],
        likeCount = json['likeCount'],
        commentCount = json['commentCount'],
        likedByMe = json['likedByMe'],
        myCopyPlanId = json['myCopyPlanId'],
        myCopyPostId = json['myCopyPostId'],
        plan = Plan.fromJson(comeJson(json['plan']));

  static List<Post> listaDaJson(dynamic lista) {
    return convertiLista(lista, Post.fromJson);
  }

  String get data {
    return dataItaliana(createdAt);
  }

  StatoCopia get copia {
    final postCopia = myCopyPostId;
    if (postCopia == null) {
      return StatoCopia.nessuna;
    }
    if (postCopia == id) {
      return StatoCopia.questa;
    }
    // Gli id dei post crescono: un post con id più piccolo è stato pubblicato prima
    return postCopia < id ? StatoCopia.precedente : StatoCopia.successiva;
  }

  String get importazioni {
    return conteggio(importCount, 'importazione', 'importazioni');
  }
}
