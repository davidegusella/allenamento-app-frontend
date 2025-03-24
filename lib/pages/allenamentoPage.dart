import 'package:flutter/material.dart';
import 'package:allenamentofrontend/services/apiService.dart';
import 'package:allenamentofrontend/models/allenamento.dart';
import 'package:allenamentofrontend/pages/eserciziPage.dart';
import 'package:allenamentofrontend/widgets/navbar/navbarWidget.dart';
import 'package:allenamentofrontend/widgets/header/headerWidget.dart';

class AllenamentoPage extends StatefulWidget {
  final ApiService apiService = ApiService();

  @override
  allenamentoPageState createState() => allenamentoPageState();
}

class allenamentoPageState extends State<AllenamentoPage> {
  late Future<List<Allenamento>> allenamentiFuture;
  Map<int, bool> completamentoAllenamenti = {};
  bool isLoading = false;
  int selectedIndex = 0;

  // Imposta lo stato in base a quale bottone è stato cliccato
  void clickNavbar(int index) {
    setState(() {
      selectedIndex = index;
    });
    switch (index) {
      case 0:
        aggiungiAllenamento(); // Nuovo allenamento
        break;
      case 1:
        caricaAllenamenti(); // Refresh
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    caricaAllenamenti();
  }

  Future<void> caricaAllenamenti() async {
    setState(() => isLoading = true);

    try {
      List<Allenamento> allenamenti = await widget.apiService.getAllAllenamenti();
      Map<int, bool> tempCompletamenti = {};

      for (var allenamento in allenamenti) {
        tempCompletamenti[allenamento.id] = allenamento.completato;
      }

      setState(() {
        completamentoAllenamenti = tempCompletamenti;
        allenamentiFuture = Future.value(allenamenti);
      });
    } catch (e) {
      print("Errore nel caricamento degli allenamenti: $e");
      setState(() {
        allenamentiFuture = Future.value([]);
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<bool> updateAllenamento(int allenamentoId) async {
    try {
      await widget.apiService.updateAllenamentoCompletato(allenamentoId);
      return true;
    } catch (e) {
      return false;
    }
  }

  void modificaNomeAllenamento(int allenamentoId) {
    TextEditingController nomeController = TextEditingController();
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                "Modifica Nome Allenamento",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (errorMessage != null)
                      Container(
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
                                errorMessage!,
                                style: TextStyle(color: Colors.red, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    TextField(
                      controller: nomeController,
                      decoration: InputDecoration(
                        hintText: "Inserisci nuovo nome",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                      textInputAction: TextInputAction.done,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Annulla",
                    style: TextStyle(color: Theme.of(context).colorScheme.primary),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: () async {
                    String nuovoNome = nomeController.text.trim();

                    if (nuovoNome.isEmpty) {
                      setState(() => errorMessage = "❌ Il nome non può essere vuoto.");
                      return;
                    }

                    if (!isValidInput(nuovoNome)) {
                      setState(() => errorMessage = "❌ Caratteri non validi nel nome.");
                      return;
                    }

                    bool successo = await widget.apiService.aggiornaNomeAllenamento(allenamentoId, nuovoNome);

                    if (successo) {
                      Navigator.pop(context);
                      caricaAllenamenti();
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

  void aggiungiAllenamento() {
    TextEditingController nomeController = TextEditingController();
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                "Nuovo allenamento",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (errorMessage != null)
                      Container(
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
                                errorMessage!,
                                style: TextStyle(color: Colors.red, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    TextField(
                      controller: nomeController,
                      decoration: InputDecoration(
                        hintText: "Inserisci il nome",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                      textInputAction: TextInputAction.done,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Annulla",
                    style: TextStyle(color: Theme.of(context).colorScheme.primary),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: () async {
                    String nomeGiorno = nomeController.text.trim();

                    if (nomeGiorno.isEmpty) {
                      setState(() => errorMessage = "❌ Il nome non può essere vuoto.");
                      return;
                    }

                    if (!isValidInput(nomeGiorno)) {
                      setState(() => errorMessage = "❌ Caratteri non validi nel nome.");
                      return;
                    }

                    String? apiError = await widget.apiService.aggiungiAllenamento(nomeGiorno);

                    if (apiError == null) {
                      Navigator.pop(context);
                      caricaAllenamenti();
                    } else {
                      setState(() => errorMessage = apiError);
                    }
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

  // Metodo in grado di eliminare gli allenamenti
  void eliminaAllenamento(int allenamentoId) {
    String? errorMessage;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                "Elimina Allenamento",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Sei sicuro di voler eliminare questo allenamento?",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 12),
                  if (errorMessage != null)
                    Container(
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
                              errorMessage!,
                              style: TextStyle(color: Colors.red, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Annulla",
                    style: TextStyle(color: Theme.of(context).colorScheme.primary),
                  ),
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
                      await widget.apiService.eliminaAllenamento(allenamentoId);
                      Navigator.pop(context);
                      caricaAllenamenti();
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

  // Metodo in grado di controllare la validità dell'input
  bool isValidInput(String input) {
    return RegExp(r"^[a-zA-Z0-9 ]+$").hasMatch(input);
  }

  // Build UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder<List<Allenamento>>(
          future: allenamentiFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting || isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Errore durante il recupero degli allenamenti'));
            }

            var allenamenti = snapshot.data ?? [];
            return CustomScrollView(
              slivers: [
                const Header(title: "Allenamenti"),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      var allenamento = allenamenti[index];
                      bool isCompletato = completamentoAllenamenti[allenamento.id] ?? false;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EserciziPage(allenamentoId: allenamento.id),
                              ),
                            );
                            bool updatedStatus = await updateAllenamento(allenamento.id);
                            setState(() {
                              completamentoAllenamenti[allenamento.id] = updatedStatus;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isCompletato ? Colors.green : Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              title: Text(
                                allenamento.nomeGiorno ?? "Allenamento ${allenamento.id}",
                                style: const TextStyle(color: Colors.white),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.black),
                                    onPressed: () => modificaNomeAllenamento(allenamento.id),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                                    onPressed: () => eliminaAllenamento(allenamento.id),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: allenamenti.length,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: selectedIndex,
        onItemTapped: clickNavbar,
      ),
    );
  }
}
