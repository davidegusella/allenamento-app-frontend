/// Formattazione e validazione dei dati mostrati e inseriti nell'app.
library;

/// Modalità di carico del backend (WeightMode)
const List<String> modalitaPeso = ['TOTAL', 'PER_SIDE', 'PER_DUMBBELL'];

/// Come la colonna DECIMAL(8,2) del backend
const num caricoMassimo = 999999.99;

/// Per esempio "kg per lato" per PER_SIDE
String etichettaCarico(String mode) {
  return switch (mode) {
    'PER_SIDE' => 'kg per lato',
    'PER_DUMBBELL' => 'kg per manubrio',
    _ => 'kg totali',
  };
}

/// Numero con la virgola decimale, senza decimali se è intero: 20 e non 20,0. Vuoto se [n] è null
String formattaNumero(num? n) {
  if (n == null) {
    return '';
  }
  final testo = n == n.roundToDouble() ? n.toInt().toString() : n.toString();
  return testo.replaceAll('.', ',');
}

/// Per esempio "05" per 5
String dueCifre(int n) {
  return n.toString().padLeft(2, '0');
}

/// Per esempio "17/10/2026"
String dataItaliana(DateTime data) {
  return '${dueCifre(data.day)}/${dueCifre(data.month)}/${data.year}';
}

/// Per esempio "09:05"
String ora(DateTime data) {
  return '${dueCifre(data.hour)}:${dueCifre(data.minute)}';
}

/// Tempo del timer, per esempio "1:30" oppure "1:02:30" oltre l'ora.
/// I secondi sono arrotondati per eccesso: con 1,3 secondi mancanti si vede ancora 2
String durataTimer(Duration tempo) {
  final totaleSecondi = (tempo.inMilliseconds / 1000).ceil();
  final ore = totaleSecondi ~/ 3600;
  final minuti = (totaleSecondi % 3600) ~/ 60;
  final secondi = dueCifre(totaleSecondi % 60);
  if (ore > 0) {
    return '$ore:${dueCifre(minuti)}:$secondi';
  }
  return '$minuti:$secondi';
}

/// Giorni di calendario tra [data] e [adesso]: 0 oggi, 1 ieri.
/// Il confronto è in UTC, così il cambio dell'ora legale non sposta il conto
int giorniFa(DateTime data, DateTime adesso) {
  final giorno = DateTime.utc(data.year, data.month, data.day);
  return DateTime.utc(adesso.year, adesso.month, adesso.day).difference(giorno).inDays;
}

/// Quando è arrivato l'ultimo messaggio di una chat, come nell'elenco di WhatsApp:
/// "09:05" se è di oggi, "Ieri", altrimenti la data
String oraOData(DateTime data, {DateTime? adesso}) {
  return switch (giorniFa(data, adesso ?? DateTime.now())) {
    0 => ora(data),
    1 => 'Ieri',
    _ => dataItaliana(data),
  };
}

/// Orario di un messaggio nella chat: "09:05" se è di oggi, altrimenti anche la data
String orarioMessaggio(DateTime data, {DateTime? adesso}) {
  if (giorniFa(data, adesso ?? DateTime.now()) == 0) {
    return ora(data);
  }
  return '${dataItaliana(data)} ${ora(data)}';
}

/// Per esempio "Serie 1: 10 × 20 kg per lato"
String descriviSerie(int numero, int reps, num weight, String weightMode) {
  return 'Serie $numero: $reps × ${formattaNumero(weight)} ${etichettaCarico(weightMode)}';
}

/// Per esempio "1 importazione" oppure "3 importazioni"
String conteggio(int quanti, String singolare, String plurale) {
  if (quanti == 1) {
    return '1 $singolare';
  }
  return '$quanti $plurale';
}

/// "8" se [min] e [max] coincidono, altrimenti "8–10"
String rangeRipetizioni(int min, int max) {
  if (min == max) {
    return '$min';
  }
  return '$min–$max';
}

/// Il peso scritto dall'utente, con la virgola o il punto; null se non è un numero
num? leggiPeso(String testo) {
  return num.tryParse(testo.trim().replaceAll(',', '.'));
}

/// Da usare solo dopo [validaPeso]
num parsePeso(String testo) {
  return leggiPeso(testo)!;
}

String? validaNome(String? valore) {
  if ((valore ?? '').trim().isEmpty) {
    return 'Inserisci il nome';
  }
  return null;
}

String? validaIntero(String? valore, int min, int max) {
  final n = int.tryParse(valore ?? '');
  if (n == null || n < min || n > max) {
    return 'Da $min a $max';
  }
  return null;
}

/// Al massimo 2 decimali, con la virgola o il punto; con [facoltativo] il campo vuoto è valido
String? validaPeso(String? valore, {bool facoltativo = false}) {
  final testo = (valore ?? '').trim().replaceAll(',', '.');
  if (testo.isEmpty && facoltativo) {
    return null;
  }
  final n = num.tryParse(testo);
  if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(testo) || n == null || n > caricoMassimo) {
    return 'Peso non valido (max 2 decimali)';
  }
  return null;
}
