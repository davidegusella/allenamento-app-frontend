import 'workout.dart';

/// Utente collegato (UtenteResponseDto). I limiti sono quelli delle costanti di AppUser nel backend
class Utente {
  static const lunghezzaUsername = 30;
  static const lunghezzaEmail = 254;
  static const passwordMin = 8;
  static const passwordMax = 64;

  final int id;

  /// Nome pubblico, sempre in minuscolo
  final String username;
  final String email;

  Utente.fromJson(Json json)
      : id = json['id'] as int,
        username = json['username'] as String,
        email = json['email'] as String;
}
