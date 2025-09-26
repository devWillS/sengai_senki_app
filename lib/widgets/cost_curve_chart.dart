import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:senkai_sengi/models/deck.dart';
import 'package:senkai_sengi/utils/master.dart';

class CostCurveChart extends StatelessWidget {
  const CostCurveChart({super.key, required this.deck});

  final Deck? deck;

  @override
  Widget build(BuildContext context) {
    final Map<int, int> costCounts = generateCostCounts();
    final costs = _buildCostSlots();
    final barGroups = costs
        .map(
          (cost) => BarChartGroupData(
            x: cost,
            barRods: [
              BarChartRodData(
                toY: (costCounts[cost] ?? 0).toDouble(),
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(0),
                width: 8,
              ),
            ],
            showingTooltipIndicators: const [0],
          ),
        )
        .toList();

    return Container(
      padding: EdgeInsets.only(top: 10),
      color: Colors.white,
      child: BarChart(
        BarChartData(
          gridData: FlGridData(show: false),
          barTouchData: _barTouchData(context),
          borderData: FlBorderData(
            border: const Border(
              top: BorderSide.none,
              right: BorderSide.none,
              left: BorderSide.none,
              bottom: BorderSide(width: 1),
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              axisNameWidget: SizedBox.shrink(),
              axisNameSize: 0,
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(fontSize: 8),
                  );
                },
                reservedSize: 12,
              ),
              axisNameSize: 0,
            ),
          ),
          groupsSpace: 10,
          barGroups: barGroups,
        ),
      ),
    );
  }

  BarTouchData _barTouchData(BuildContext context) {
    return BarTouchData(
      enabled: false,
      touchTooltipData: BarTouchTooltipData(
        getTooltipColor: (group) => Colors.transparent,
        tooltipPadding: EdgeInsets.zero,
        tooltipMargin: -2,
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          final value = rod.toY.round();
          if (value == 0) {
            return BarTooltipItem('', const TextStyle(fontSize: 0));
          }
          return BarTooltipItem(
            rod.toY.round() == 0 ? "" : rod.toY.round().toString(),
            TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 8,
            ),
          );
        },
      ),
    );
  }

  List<int> _buildCostSlots() => List<int>.generate(10, (index) => index + 1);

  Map<int, int> generateCostCounts() {
    if (deck == null) {
      return {};
    }

    final costCounts = <int, int>{};
    final masterCardList = Master().cardList;

    // メインデッキのコスト分析
    for (final entry in deck!.mainDeck) {
      final card = masterCardList.firstWhereOrNull((c) => c.id == entry.cardId);

      if (card != null && card.cost != null) {
        final cost = card.cost!;
        costCounts.update(
          cost,
          (value) => value + entry.count,
          ifAbsent: () => entry.count,
        );
      }
    }

    return costCounts;
  }
}
