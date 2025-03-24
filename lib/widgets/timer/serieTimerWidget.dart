import 'package:flutter/material.dart';
import '../../models/esercizio.dart';

class TimerPage extends StatefulWidget {
  final Esercizio esercizio;
  TimerPage({required this.esercizio});

  @override
  _TimerPageState createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  int _remainingTime = 0;
  bool _isRunning = false;
  late int _totalTime;
  late int _totalTimeInSeconds;
  late int _remainingMinutes;
  late int _remainingSeconds;

  @override
  void initState() {
    super.initState();
    // Calcola il tempo in secondi per il timer
    _totalTime = widget.esercizio.ripetizioni * 10; // Imposta il tempo per ripetizione
    _remainingTime = _totalTime;
    _remainingMinutes = _remainingTime ~/ 60;
    _remainingSeconds = _remainingTime % 60;
  }

  void startTimer() {
    setState(() {
      _isRunning = true;
    });
    Future.delayed(Duration(seconds: 1), updateTimer);
  }

  void updateTimer() {
    if (_remainingTime > 0) {
      setState(() {
        _remainingTime--;
        _remainingMinutes = _remainingTime ~/ 60;
        _remainingSeconds = _remainingTime % 60;
      });
      Future.delayed(Duration(seconds: 1), updateTimer);
    } else {
      setState(() {
        _isRunning = false;
      });
      // Timer scaduto, notificare l'utente
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tempo scaduto!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.esercizio.nome)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Serie: ${widget.esercizio.serie}', style: TextStyle(fontSize: 24)),
            Text('Ripetizioni: ${widget.esercizio.ripetizioni}', style: TextStyle(fontSize: 24)),
            SizedBox(height: 20),
            Text('Tempo rimanente: $_remainingMinutes min $_remainingSeconds sec',
                style: TextStyle(fontSize: 24)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isRunning ? null : startTimer, // Disabilita il bottone quando il timer è in corso
              child: Text(_isRunning ? 'In corso...' : 'Inizia il timer'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: widget.esercizio.serie > 0
                  ? () {
                setState(() {
                  widget.esercizio.serie--;
                });
                if (widget.esercizio.serie == 0) {
                  // Segnala come completato e aggiorna il bottone
                  // Chiamata al backend per aggiornare l'esercizio
                  markEsercizioAsCompleted(widget.esercizio.id);
                }
              }
                  : null, // Disabilita quando le serie sono a zero
              child: Text('Decrementa Serie'),
            ),
          ],
        ),
      ),
    );
  }

  void markEsercizioAsCompleted(int esercizioId) {
    // Logica per segnare l'esercizio come completato
  }
}
