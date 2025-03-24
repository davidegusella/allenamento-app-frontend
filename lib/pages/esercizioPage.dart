import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:allenamentofrontend/models/esercizio.dart';
import 'package:allenamentofrontend/services/apiService.dart';
import '../providers/timer/serieTimeProvider.dart';

class EsercizioDetailPage extends StatefulWidget {
  final Esercizio esercizio;

  EsercizioDetailPage({required this.esercizio});

  @override
  _EsercizioDetailPageState createState() => _EsercizioDetailPageState();
}

class _EsercizioDetailPageState extends State<EsercizioDetailPage> {
  final ApiService apiService = ApiService();
  int serieRimanenti = 0; // Contatore delle serie rimanenti
  int ripetizioni = 0;

  @override
  void initState() {
    super.initState();
    _fetchSerie();
  }

  // Recupera il numero iniziale di serie dal database
  void _fetchSerie() async {
    try {
      final esercizioAggiornato = await apiService.getEsercizioById(widget.esercizio.id);
      setState(() {
        serieRimanenti = esercizioAggiornato.serie;
        ripetizioni = esercizioAggiornato.ripetizioni;
      });
    } catch (e) {
      print("Errore nel recupero delle serie: $e");
    }
  }

  void _decrementaSerie() async {
    if (serieRimanenti > 0) {
      setState(() {
        serieRimanenti--;
      });

      // Se le serie arrivano a 0, segna l'esercizio come completato
      if (serieRimanenti == 0) {
        await apiService.updateEsercizioCompletato(widget.esercizio.id);
        Navigator.pop(context, true); // 🔹 Torna indietro e segnala il cambiamento
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final timeProvider = Provider.of<TimeProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text("Dettagli esercizio"),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Ripetizioni: $ripetizioni",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),),
            // Contatore delle serie rimanenti
            Text(
              "Serie Rimanenti: $serieRimanenti",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Pulsante per decrementare le serie
            ElevatedButton(
              onPressed: _decrementaSerie,
              child: Text("Decrementa Serie"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 30),

            // Timer con progresso circolare
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 280,
                  width: 280,
                  child: CircularProgressIndicator(
                    backgroundColor: Colors.white,
                    value: timeProvider.initialTime > 0
                        ? timeProvider.remainingTime / timeProvider.initialTime
                        : 0,
                    strokeWidth: 8,
                  ),
                ),
                GestureDetector(
                  onTap: () => _showTimePicker(context, timeProvider),
                  child: Text(
                    _formatTime(timeProvider.remainingTime),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 45),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Pulsanti di controllo timer
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: timeProvider.isRunning
                      ? timeProvider.pauseTimer
                      : timeProvider.startTimer,
                  child: Container(
                    height: 50,
                    width: 50,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue,
                    ),
                    child: Icon(
                      timeProvider.isRunning ? Icons.pause : Icons.play_arrow,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: timeProvider.resetTimer,
                  child: Container(
                    height: 50,
                    width: 50,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue,
                    ),
                    child: const Icon(
                      Icons.stop,
                      size: 35,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // Mostra il CupertinoTimePicker per selezionare il tempo del timer
  void _showTimePicker(BuildContext context, TimeProvider timerProvider) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          color: Colors.white,
          height: 300,
          child: CupertinoTimerPicker(
            mode: CupertinoTimerPickerMode.hms,
            initialTimerDuration:
            Duration(seconds: timerProvider.remainingTime),
            onTimerDurationChanged: (Duration newDuration) {
              if (newDuration.inSeconds > 0) {
                timerProvider.setTime(newDuration.inSeconds);
              }
            },
          ),
        );
      },
    );
  }

  // Converte i secondi in formato HH:MM:SS
  String _formatTime(int totalSecond) {
    int hours = totalSecond ~/ 3600;
    int minutes = (totalSecond % 3600) ~/ 60;
    int seconds = totalSecond % 60;
    return "${hours.toString().padLeft(2, "0")}:${minutes.toString().padLeft(2, "0")}:${seconds.toString().padLeft(2, "0")}";
  }
}
