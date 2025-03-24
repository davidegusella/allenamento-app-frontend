import 'package:flutter/material.dart';
import 'package:allenamentofrontend/services/apiService.dart';
import 'package:allenamentofrontend/models/esercizio.dart';
import 'package:allenamentofrontend/pages/esercizioPage.dart';
import 'package:allenamentofrontend/widgets/header/headerWidget.dart';
import 'package:allenamentofrontend/widgets/navbar/navbarWidget.dart';


class EserciziPage extends StatefulWidget {
  final int allenamentoId;

  EserciziPage({required this.allenamentoId});

  @override
  _EserciziPageState createState() => _EserciziPageState();
}

class _EserciziPageState extends State<EserciziPage> {
  final ApiService apiService = ApiService();
  late Future<List<Esercizio>> eserciziFuture;
  Map<int, bool> expandedEsercizi = {};

  // Flag per sapere se ci sono stati cambiamenti
  bool hasChanged = false;

  @override
  void initState() {
    super.initState();
    eserciziFuture = apiService.getEserciziByAllenamentoId(widget.allenamentoId);
  }

  void refreshEsercizi() {
    setState(() {
      eserciziFuture = apiService.getEserciziByAllenamentoId(widget.allenamentoId);
    });
  }

  // Segna un esercizio come completato e registra che c'è stato un cambiamento
  void markEsercizioAsCompleted(int esercizioId) async {
    try {
      await apiService.updateEsercizioCompletato(esercizioId);

      setState(() {
        // ✅ Modifica direttamente lo stato locale senza chiamare l'API
        eserciziFuture = eserciziFuture.then((esercizi) {
          return esercizi.map((esercizio) {
            if (esercizio.id == esercizioId) {
              return esercizio.copyWith(completato: true); // Usa un metodo di copia nel modello
            }
            return esercizio;
          }).toList();
        });

        hasChanged = true;
      });

      checkAllEserciziCompletati();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante l\'aggiornamento dell\'esercizio')),
      );
    }
  }

  void _modificaEsercizio(Esercizio esercizio) {
    TextEditingController nomeController = TextEditingController(text: esercizio.nome);
    TextEditingController serieController = TextEditingController(text: esercizio.serie.toString());
    TextEditingController ripetizioniController = TextEditingController(text: esercizio.ripetizioni.toString());
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                "Modifica Esercizio",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (errorMessage != null)
                      _buildErrorMessage(errorMessage ?? ""),
                    _buildTextField("Nome", nomeController),
                    SizedBox(height: 10),
                    _buildTextField("Serie", serieController, isNumeric: true),
                    SizedBox(height: 10),
                    _buildTextField("Ripetizioni", ripetizioniController, isNumeric: true),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Annulla", style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                ),
                ElevatedButton(
                  style: _buildActionButtonStyle(),
                  onPressed: () async {
                    String nome = nomeController.text.trim();
                    int? serie = int.tryParse(serieController.text.trim());
                    int? ripetizioni = int.tryParse(ripetizioniController.text.trim());

                    if (nome.isEmpty || serie == null || ripetizioni == null) {
                      setState(() => errorMessage = "❌ Tutti i campi devono essere validi.");
                      return;
                    }

                    bool successo = await apiService.updateDatiEsercizio(
                      esercizio.id,
                      {"nome": nome, "serie": serie, "ripetizioni": ripetizioni}, esercizioId: esercizio.id,
                    );

                    if (successo) {
                      Navigator.pop(context);
                      refreshEsercizi();
                    } else {
                      setState(() => errorMessage = "❌ Errore durante la modifica.");
                    }
                  },
                  child: Text("Modifica"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _aggiungiEsercizio() {
    TextEditingController nomeController = TextEditingController();
    TextEditingController serieController = TextEditingController();
    TextEditingController ripetizioniController = TextEditingController();
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                "Nuovo Esercizio",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (errorMessage != null)
                      _buildErrorMessage(errorMessage ?? ""),
                    _buildTextField("Nome", nomeController),
                    SizedBox(height: 10),
                    _buildTextField("Serie", serieController, isNumeric: true),
                    SizedBox(height: 10),
                    _buildTextField("Ripetizioni", ripetizioniController, isNumeric: true),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Annulla", style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                ),
                ElevatedButton(
                  style: _buildActionButtonStyle(),
                  onPressed: () async {
                    String nome = nomeController.text.trim();
                    int? serie = int.tryParse(serieController.text.trim());
                    int? ripetizioni = int.tryParse(ripetizioniController.text.trim());

                    if (nome.isEmpty || serie == null || ripetizioni == null) {
                      setState(() => errorMessage = "❌ Tutti i campi devono essere validi.");
                      return;
                    }

                    await apiService.aggiungiEsercizio(
                      Esercizio(
                        id: 0,
                        nome: nome,
                        serie: serie,
                        ripetizioni: ripetizioni,
                        completato: false,
                        descrizione: "",
                      ),
                    );

                    Navigator.pop(context);
                    refreshEsercizi();
                  },
                  child: Text("Aggiungi"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _eliminaEsercizio(int esercizioId) {
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                "Elimina Esercizio",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Sei sicuro di voler eliminare questo esercizio?",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 12),
                  if (errorMessage != null)
                    _buildErrorMessage(errorMessage ?? ""),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Annulla", style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: () async {
                    try {
                      await apiService.eliminaEsercizio(esercizioId);
                      Navigator.pop(context);
                      refreshEsercizi();
                    } catch (e) {
                      setState(() => errorMessage = "❌ Errore durante l'eliminazione.");
                    }
                  },
                  child: Text("Elimina"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      padding: EdgeInsets.all(8),
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumeric = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    );
  }

  ButtonStyle _buildActionButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    );
  }


  // Controlla se tutti gli esercizi sono completati e aggiorna lo stato dell'allenamento
  void checkAllEserciziCompletati() async {
    final esercizi = await apiService.getEserciziByAllenamentoId(widget.allenamentoId);
    bool allCompleted = esercizi.every((esercizio) => esercizio.completato);

    if (allCompleted) {
      await apiService.updateAllenamentoCompletato(widget.allenamentoId);
      setState(() {

        // Registra il cambiamento
        hasChanged = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, hasChanged);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: FutureBuilder<List<Esercizio>>(
            future: eserciziFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Center(child: Text('Errore durante il recupero degli esercizi'));
              }

              var esercizi = snapshot.data ?? [];

              return CustomScrollView(
                slivers: [
                  const Header(title: "Esercizi"),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        var esercizio = esercizi[index];
                        bool isCompleted = esercizio.completato;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EsercizioDetailPage(esercizio: esercizio),
                                ),
                              );

                              if (result == true) {
                                setState(() => hasChanged = true);
                                refreshEsercizi();
                                checkAllEserciziCompletati();
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: esercizio.completato ? Colors.green : Colors.blue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                title: Text(
                                  esercizio.nome,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Serie: ${esercizio.serie}',
                                      style: const TextStyle(color: Colors.white70),
                                    ),
                                    Text(
                                      'Ripetizioni: ${esercizio.ripetizioni}',
                                      style: const TextStyle(color: Colors.white70),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.black),
                                      onPressed: () => _modificaEsercizio(esercizio),
                                      tooltip: 'Modifica esercizio',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                                      onPressed: () => _eliminaEsercizio(esercizio.id),
                                      tooltip: 'Elimina esercizio',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                        },
                      childCount: esercizi.length,
                    ),
                  ),
                  SliverToBoxAdapter(child: SizedBox(height: 80)), // spazio extra prima della navbar
                ],
              );
            },
          ),
        ),
        bottomNavigationBar: CustomBottomNavBar(
          selectedIndex: 1,
          onItemTapped: (index) {
            if (index == 0) {
              _aggiungiEsercizio();
            } else {
              refreshEsercizi();
            }
          },
        ),
      ),
    );
  }
}
