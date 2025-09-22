import 'package:flutter/material.dart';
import 'package:voice_ai_app/theme/app_colors.dart';
import 'package:voice_ai_app/theme/app_text_styles.dart';

class VHIScoreDistributionChart extends StatelessWidget {
  final int mild;
  final int moderate;
  final int severe;

  const VHIScoreDistributionChart({
    Key? key,
    required this.mild,
    required this.moderate,
    required this.severe,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final total = mild + moderate + severe;
    final maxValue = [mild, moderate, severe].reduce((a, b) => a > b ? a : b);

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('VHI Score Distribution', style: AppTextStyles.bodyBold),
            const SizedBox(height: 16),

            // Bar chart
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildBar('Mild', mild, maxValue, Colors.green),
                  _buildBar('Moderate', moderate, maxValue, Colors.orange),
                  _buildBar('Severe', severe, maxValue, Colors.red),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _LegendItem(color: Colors.green, label: 'Mild: $mild'),
                _LegendItem(color: Colors.orange, label: 'Moderate: $moderate'),
                _LegendItem(color: Colors.red, label: 'Severe: $severe'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(String label, int value, int maxValue, Color color) {
    // Convert to double explicitly
    final heightFactor =
        maxValue > 0 ? value.toDouble() / maxValue.toDouble() : 0.0;

    return Column(
      children: [
        Text(value.toString(), style: AppTextStyles.bodyText),
        const SizedBox(height: 4),
        Container(
          width: 40,
          height: 80 * heightFactor, // Now heightFactor is double
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.bodyText),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({Key? key, required this.color, required this.label})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.bodyText),
      ],
    );
  }
}

class DataTypeDistributionChart extends StatelessWidget {
  final Map<String, dynamic> stats;

  const DataTypeDistributionChart({Key? key, required this.stats})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dataTypes = [
      _ChartData('Users', stats['totalUsers'] ?? 0, AppColors.primary),
      _ChartData('Demographics', stats['totalDemographics'] ?? 0, Colors.blue),
      _ChartData('VHI', stats['totalVHI'] ?? 0, Colors.green),
      _ChartData('Oral Cancer', stats['totalOralCancer'] ?? 0, Colors.orange),
      _ChartData('GRBAS', stats['totalGRBAS'] ?? 0, Colors.purple),
      _ChartData('Recordings', stats['totalVoiceRecordings'] ?? 0, Colors.red),
    ];

    // Sort by value descending
    dataTypes.sort((a, b) => b.value.compareTo(a.value));

    // Fixed the fold method to properly find the max value
    final maxValue = dataTypes.fold<int>(
      0,
      (int max, _ChartData item) => item.value > max ? item.value : max,
    );

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Data Type Distribution', style: AppTextStyles.bodyBold),
            const SizedBox(height: 16),

            // Horizontal bar chart
            Column(
              children: dataTypes.map((data) {
                return _buildDataTypeRow(data, maxValue, context);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTypeRow(
      _ChartData data, int maxValue, BuildContext context) {
    // Convert to double explicitly
    final percentage =
        maxValue > 0 ? data.value.toDouble() / maxValue.toDouble() : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              data.label,
              style: AppTextStyles.bodyText,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: data.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Container(
                  height: 20,
                  width: percentage * (MediaQuery.of(context).size.width - 150),
                  decoration: BoxDecoration(
                    color: data.color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        data.value.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartData {
  final String label;
  final int value;
  final Color color;

  _ChartData(this.label, this.value, this.color);
}
