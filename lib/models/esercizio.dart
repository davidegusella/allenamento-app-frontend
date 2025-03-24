class Esercizio {
  final int id;
  final String nome;
  int serie;
  final int ripetizioni;
  final bool completato;
  final String descrizione;

  Esercizio({
    required this.id,
    required this.nome,
    required this.serie,
    required this.ripetizioni,
    required this.completato,
    required this.descrizione,
  });

  factory Esercizio.fromJson(Map<String, dynamic> json) {
    return Esercizio(
      id: json['id'],
      nome: json['nome'] ?? '',
      serie: json['serie'] ?? 0,
      ripetizioni: json['ripetizioni'] ?? 0,
      completato: json['completato'] ?? false,
      descrizione: json['descrizione'] ?? '',
    );
  }

  // ✅ Metodo copyWith corretto
  Esercizio copyWith({
    int? id,
    String? nome,
    int? serie,
    int? ripetizioni,
    bool? completato,
    String? descrizione,
  }) {
    return Esercizio(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      serie: serie ?? this.serie,
      ripetizioni: ripetizioni ?? this.ripetizioni,
      completato: completato ?? this.completato,
      descrizione: descrizione ?? this.descrizione,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'serie': serie,
      'ripetizioni': ripetizioni,
      'completato': completato,
      'descrizione': descrizione,
    };
  }
}
