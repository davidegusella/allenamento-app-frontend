import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/workout.dart';
import '../providers/workout_store.dart';
import '../theme/app_theme.dart';
import '../utils/formato.dart';
import '../widgets/elenco_aggiornabile.dart';
import '../widgets/pannelli.dart';

/// Storico di un esercizio: il grafico del carico più alto di ogni giorno e l'elenco delle sessioni.
/// Ogni giorno in cui si salvano i valori dell'esercizio diventa una sessione
class StoricoEsercizioPage extends StatefulWidget {
  final Exercise exercise;

  const StoricoEsercizioPage({super.key, required this.exercise});

  @override
  State<StoricoEsercizioPage> createState() => _StoricoEsercizioPageState();
}

class _StoricoEsercizioPageState extends State<StoricoEsercizioPage> {
  /// Dalla più recente; null finché non sono caricate
  List<Sessione>? _sessioni;

  Future<void> _carica() async {
    final caricate = await context.read<WorkoutStore>().caricaStorico(widget.exercise.id);
    if (mounted) {
      setState(() => _sessioni = caricate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final elenco = _sessioni;
    return Scaffold(
      appBar: AppBar(title: Text('Storico · ${widget.exercise.name}')),
      body: ElencoAggiornabile(
        carica: _carica,
        costruisci: (caricamento) => [
          if (elenco == null)
            const LinearProgressIndicator()
          else if (elenco.isEmpty)
            const EmptyState(
                'Nessuna sessione', 'Salva i valori dell\'esercizio: ogni giorno in cui salvi diventa una sessione.')
          else ...[
            // Con una sola sessione una linea non mostrerebbe nessun andamento
            if (elenco.length >= 2) Panel(child: GraficoProgressi(sessioni: elenco)),
            for (final sessione in elenco) PannelloSessione(sessione: sessione, weightMode: widget.exercise.weightMode),
          ],
        ],
      ),
    );
  }
}

/// Linea del carico più alto di ogni sessione, dalla più vecchia alla più recente
class GraficoProgressi extends StatelessWidget {
  /// Sessioni dalla più recente, come arrivano dal backend
  final List<Sessione> sessioni;

  const GraficoProgressi({super.key, required this.sessioni});

  @override
  Widget build(BuildContext context) {
    final colore = Theme.of(context).colorScheme.primary;
    final cronologiche = sessioni.reversed.toList();
    final punti = [
      for (int i = 0; i < cronologiche.length; i++) FlSpot(i.toDouble(), cronologiche[i].kgMassimo.toDouble()),
    ];

    // Sotto il grafico solo la prima e l'ultima data: tutte non ci starebbero
    Widget etichettaData(double valore, TitleMeta meta) {
      final indice = valore.toInt();
      if (valore != indice || (indice != 0 && indice != cronologiche.length - 1)) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(cronologiche[indice].data, style: testoSecondario.copyWith(fontSize: 11)),
      );
    }

    Widget etichettaKg(double valore, TitleMeta meta) {
      return Text(formattaNumero(valore), style: testoSecondario.copyWith(fontSize: 11));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kg più alti di ogni giorno', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              minY: 0,
              gridData: const FlGridData(drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              lineTouchData: const LineTouchData(enabled: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                bottomTitles: AxisTitles(
                  sideTitles:
                      SideTitles(showTitles: true, interval: 1, reservedSize: 24, getTitlesWidget: etichettaData),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: etichettaKg),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: punti,
                  color: colore,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(show: true, color: colore.withValues(alpha: 0.15)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Una sessione dello storico: la data e una riga per ogni serie
class PannelloSessione extends StatelessWidget {
  final Sessione sessione;
  final String weightMode;

  const PannelloSessione({super.key, required this.sessione, required this.weightMode});

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(sessione.data, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final (i, serie) in sessione.sets.indexed)
            Text(descriviSerie(i + 1, serie.reps, serie.weight, weightMode)),
        ],
      ),
    );
  }
}
