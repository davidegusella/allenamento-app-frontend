import '../utils/formato.dart';
import 'workout.dart';

/// Commento a un post della bacheca (CommentoResponseDto)
class Commento {
  /// Come PostComment.LUNGHEZZA_MASSIMA nel backend
  static const lunghezzaMassima = 500;

  final int id;

  /// Username di chi l'ha scritto
  final String author;
  final String text;
  final DateTime createdAt;

  Commento.fromJson(Json json)
      : id = json['id'],
        author = json['author'],
        text = json['text'],
        createdAt = dataLocale(json['createdAt']);

  static List<Commento> listaDaJson(dynamic lista) {
    return convertiLista(lista, Commento.fromJson);
  }

  String get data {
    return dataItaliana(createdAt);
  }
}
