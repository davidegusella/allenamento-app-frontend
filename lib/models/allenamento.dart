class Allenamento {
  final int id;
  final String nomeGiorno;
  bool completato;

  Allenamento({required this.id, required this.nomeGiorno, this.completato = false});

  factory Allenamento.fromJson(Map<String, dynamic> json) {
    return Allenamento(
      id: json['id'],
      nomeGiorno: json['nomeGiorno'],
      completato: json['completato'],
    );
  }

  // ✅ Metodo copyWith per creare una nuova istanza con campi modificati
  Allenamento copyWith({
    int? id,
    String? nomeGiorno,
    bool? completato,
  }) {
    return Allenamento(
      id: id ?? this.id,
      nomeGiorno: nomeGiorno ?? this.nomeGiorno,
      completato: completato ?? this.completato,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nomeGiorno': nomeGiorno,
      'completato': completato,
    };
  }
}