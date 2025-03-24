import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/allenamento.dart';
import '../models/esercizio.dart';

class ApiService {
  final String baseUrl = "http://172.16.229.76:8080/api";  // Usa l'IP locale della tua macchina

  // Ottieni tutti gli allenamenti
  Future<List<Allenamento>> getAllAllenamenti() async {
    final response = await http.get(Uri.parse('$baseUrl/allenamenti'));

    if (response.statusCode == 200) {
      List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((data) => Allenamento.fromJson(data)).toList();
    } else {
      throw Exception('Errore durante il recupero degli allenamenti');
    }
  }

  // Metodo per ottenere un allenamento specifico dato l'id
  Future<Allenamento> getAllenamentoById(int allenamentoId) async {
    final response = await http.get(Uri.parse('$baseUrl/allenamenti/$allenamentoId'));

    if (response.statusCode == 200) {
      return Allenamento.fromJson(json.decode(response.body));
    } else {
      throw Exception('Errore durante il recupero dell\'allenamento');
    }
  }

  // Metodo per ottenere un esercizio specifico (usato per preservare i dati esistenti)
  Future<Esercizio> getEsercizioById(int esercizioId) async {
    final response = await http.get(Uri.parse('$baseUrl/esercizi/$esercizioId'));

    if (response.statusCode == 200) {
      return Esercizio.fromJson(json.decode(response.body));
    } else {
      throw Exception('Errore durante il recupero dell\'esercizio');
    }
  }

  // Metodo per ottenere gli esercizi di un allenamento
  Future<List<Esercizio>> getEserciziByAllenamentoId(int allenamentoId) async {
    final response = await http.get(Uri.parse('$baseUrl/esercizi/allenamento/$allenamentoId'));
    if (response.statusCode == 200) {
      List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((data) => Esercizio.fromJson(data)).toList();
    } else {
      throw Exception('Errore durante il recupero degli esercizi');
    }
  }

  // 🔹 Inserisci un nuovo esercizio
  Future<Esercizio> aggiungiEsercizio(Esercizio esercizio) async {
    final response = await http.post(
      Uri.parse('$baseUrl/esercizi'),
      headers: {"Content-Type": "application/json"},
      body: json.encode(esercizio.toJson()),
    );

    if (response.statusCode == 201) {
      return Esercizio.fromJson(json.decode(response.body));
    } else {
      throw Exception('Errore durante l\'inserimento dell\'esercizio');
    }
  }

  // 🔹 Elimina un esercizio
  Future<void> eliminaEsercizio(int esercizioId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/esercizi/$esercizioId'),
    );

    if (response.statusCode != 200) {
      throw Exception('Errore durante l\'eliminazione dell\'esercizio');
    }
  }

  // 🔹 Modifica i dati di un esercizio (nome, serie, ripetizioni, descrizione)
  Future<bool> updateDatiEsercizio(int id, Map<String, Object> map, {
    required int esercizioId,
    String? nuovoNome,
    int? nuoveSerie,
    int? nuoveRipetizioni,
    String? nuovaDescrizione,
  }) async {
    final Map<String, dynamic> updates = {};

    if (nuovoNome != null) updates["nome"] = nuovoNome;
    if (nuoveSerie != null) updates["serie"] = nuoveSerie;
    if (nuoveRipetizioni != null) updates["ripetizioni"] = nuoveRipetizioni;
    if (nuovaDescrizione != null) updates["descrizione"] = nuovaDescrizione;

    if (updates.isEmpty) return false; // Nessun dato da aggiornare

    final response = await http.put(
      Uri.parse('$baseUrl/esercizi/$esercizioId'),
      headers: {"Content-Type": "application/json"},
      body: json.encode(updates),
    );

    return response.statusCode == 200;
  }

  // Metodo per aggiornare uno o più campi di un esercizio (in modo sicuro, preservando dati esistenti)
  Future<void> updateEsercizio(int esercizioId, Map<String, dynamic> updates) async {
    // Recupera lo stato attuale dal backend
    final esercizioCorrente = await getEsercizioById(esercizioId);

    // Crea l'oggetto aggiornato preservando i dati esistenti
    final updatedEsercizio = {
      'id': esercizioCorrente.id,
      'nome': esercizioCorrente.nome,
      'serie': updates['serie'] ?? esercizioCorrente.serie,
      'ripetizioni': updates['ripetizioni'] ?? esercizioCorrente.ripetizioni,
      'completato': updates['completato'] ?? esercizioCorrente.completato,
      // Aggiungi altri campi se il tuo modello ne prevede
    };

    final response = await http.put(
      Uri.parse('$baseUrl/esercizi/$esercizioId'),
      headers: {"Content-Type": "application/json"},
      body: json.encode(updatedEsercizio),
    );

    if (response.statusCode != 200) {
      throw Exception('Errore durante l\'aggiornamento dell\'esercizio');
    }
  }

  // Metodo per aggiornare solo lo stato di completamento
  Future<Esercizio> updateEsercizioCompletato(int esercizioId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/esercizi/$esercizioId'),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"completato": true}),
    );

    if (response.statusCode == 200) {
      return Esercizio.fromJson(json.decode(response.body));
    } else {
      throw Exception('Errore durante l\'aggiornamento dell\'esercizio');
    }
  }

  // Verifica se tutti gli esercizi di un allenamento sono completati
  Future<bool> checkAllExercisesCompleted(int allenamentoId) async {
    final response = await http.get(Uri.parse('$baseUrl/allenamenti/$allenamentoId/completato'));

    if (response.statusCode == 200) {
      return response.body == 'true';
    } else {
      throw Exception('Errore durante il controllo degli esercizi');
    }
  }

  // Aggiorna l'allenamento come completato
  Future<void> updateAllenamentoCompletato(int allenamentoId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/allenamenti/$allenamentoId'));

    if (response.statusCode != 200) {
      throw Exception('Errore durante l\'aggiornamento dell\'allenamento');
    }
  }

  // 🔹 Aggiunge un nuovo allenamento
  Future<String?> aggiungiAllenamento(String nomeGiorno) async {
    final response = await http.post(
      Uri.parse('$baseUrl/allenamenti'),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"nomeGiorno": nomeGiorno, "completato": false}),
    );

    if (response.statusCode == 201) {
      return null; // ✅ Inserimento riuscito, nessun errore
    } else if (response.statusCode == 400) {
      return json.decode(response.body)['message']; // ❌ Errore validazione
    } else {
      return "Errore durante l'inserimento";
    }
  }

  // Elimina un allenamento
  Future<void> eliminaAllenamento(int allenamentoId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/allenamenti/$allenamentoId'),
    );

    if (response.statusCode != 200) {
      throw Exception('Errore durante l\'eliminazione dell\'allenamento');
    }
  }

  // Modifica il nome di un allenamento
  Future<bool> aggiornaNomeAllenamento(int allenamentoId, String nuovoNome) async {
    final response = await http.put(
      Uri.parse('$baseUrl/allenamenti/modificaNome/$allenamentoId'),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"nomeGiorno": nuovoNome}),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }



  // Aggiorna l'allenamento come incompleto
  Future<void> updateAllenamentoIncompleto(int allenamentoId) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/allenamenti/$allenamentoId/completato'),
      headers: {"Content-Type": "application/json"},
      body: json.encode({'completato': false}),
    );

    if (response.statusCode != 200) {
      throw Exception('Errore durante l\'aggiornamento dell\'allenamento');
    }
  }
}
