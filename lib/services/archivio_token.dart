import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Dove l'app conserva il token di accesso tra un avvio e l'altro, così non si rifà l'accesso ogni volta.
/// L'app usa [ArchivioTokenSicuro], i test [ArchivioTokenInMemoria]: lì il portachiavi del telefono non esiste
abstract class ArchivioToken {
  /// null se non c'è un token salvato
  Future<String?> leggi();

  Future<void> salva(String token);

  Future<void> cancella();
}

/// Portachiavi del telefono (Keychain su iPhone, Keystore su Android), che protegge il token dalle altre app.
/// Nel browser il token è salvato cifrato nel localStorage
class ArchivioTokenSicuro implements ArchivioToken {
  static const String _chiave = 'token_accesso';

  final FlutterSecureStorage _archivio = const FlutterSecureStorage();

  @override
  Future<String?> leggi() {
    return _archivio.read(key: _chiave);
  }

  @override
  Future<void> salva(String token) {
    return _archivio.write(key: _chiave, value: token);
  }

  @override
  Future<void> cancella() {
    return _archivio.delete(key: _chiave);
  }
}

/// Per i test: il token resta solo in memoria
class ArchivioTokenInMemoria implements ArchivioToken {
  String? token;

  ArchivioTokenInMemoria([this.token]);

  @override
  Future<String?> leggi() async {
    return token;
  }

  @override
  Future<void> salva(String nuovo) async {
    token = nuovo;
  }

  @override
  Future<void> cancella() async {
    token = null;
  }
}
