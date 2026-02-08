import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/statistics_model.dart';
import '../../data/repositories/statistics_repository.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  String _formatAmount(double amount) {
    if (amount == amount.roundToDouble()) {
      return amount.toInt().toString();
    }
    String formatted = amount.toStringAsFixed(2);
    if (formatted.endsWith('0')) {
      formatted = formatted.substring(0, formatted.length - 1);
    }
    if (formatted.endsWith('.')) {
      formatted = formatted.substring(0, formatted.length - 1);
    }
    return formatted;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statisticsDataProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Статистика'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Ошибка: $error')),
        data: (stats) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(statisticsDataProvider),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader('Финансовая воронка'),
                const SizedBox(height: 12),
                _buildPipeline(stats.pipeline),
                const SizedBox(height: 24),
                _buildHeader('Источники проектов'),
                const SizedBox(height: 12),
                _buildSourceChips(stats.sources),
                const SizedBox(height: 24),
                _buildHeader('Типы объектов'),
                const SizedBox(height: 12),
                _buildObjectTypeStats(stats.objectTypes),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1F2937),
      ),
    );
  }

  Widget _buildPipeline(PipelineData pipeline) {
    return Column(
      children: [
        _buildPipelineCard(
          'Оплачено',
          pipeline.paid,
          const Color(0xFF10B981), // Green
          Icons.check_circle_rounded,
        ),
        const SizedBox(height: 8),
        _buildPipelineCard(
          'Ожидает оплаты',
          pipeline.pending,
          const Color(0xFFF59E0B), // Amber
          Icons.pending_actions_rounded,
        ),
        const SizedBox(height: 8),
        _buildPipelineCard(
          'В работе',
          pipeline.inWork,
          const Color(0xFF3B82F6), // Blue
          Icons.engineering_rounded,
        ),
      ],
    );
  }

  Widget _buildPipelineCard(
      String title, CurrencyAmount amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.1), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${_formatAmount(amount.usd)} \$',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    if (amount.byn > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        '| ${_formatAmount(amount.byn)} р',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceChips(List<SourceData> sources) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: sources
          .map((s) =>
              _buildStatChip(s.name, s.count, s.usd, s.byn, Colors.indigo))
          .toList(),
    );
  }

  Widget _buildObjectTypeStats(List<ObjectTypeData> types) {
    return Column(
      children: types.map((t) => _buildTypeRow(t)).toList(),
    );
  }

  Widget _buildTypeRow(ObjectTypeData type) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              type.name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${type.count} объв.',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ),
          const Spacer(),
          Text(
            '~${_formatAmount(type.usd / type.count)} \$',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(
      String name, int count, double usd, double byn, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(width: 6),
              CircleAvatar(
                radius: 8,
                backgroundColor: color.withOpacity(0.1),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                      fontSize: 9, color: color, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${_formatAmount(usd)} \$',
            style: TextStyle(
                fontSize: 12, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
