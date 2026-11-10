import 'package:flutter/material.dart';

import '../models/glucose_record.dart';

class DailyDetailPage extends StatelessWidget {
  const DailyDetailPage({required this.date, required this.records, super.key});

  final DateTime date;
  final List<GlucoseRecord> records;

  static const _ink = Color(0xFF141B2B);
  static const _primary = Color(0xFF0037B0);
  static const _secondary = Color(0xFF585F67);
  static const _surface = Color(0xFFF9F9FF);
  static const _surfaceLow = Color(0xFFF1F3FF);
  static const _error = Color(0xFFBA1A1A);

  String get _formattedDate {
    const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    return '${date.year}年${date.month}月${date.day}日（${weekdays[date.weekday - 1]}）';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Calendar',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _ink,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 20),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: _primary,
              child: Icon(Icons.person_outline, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              children: [
                _buildContextBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildDateSummary(),
                        const SizedBox(height: 20),
                        if (records.isEmpty)
                          _buildEmptyState()
                        else ...[
                          for (
                            var index = 0;
                            index < records.length;
                            index++
                          ) ...[
                            if (index > 0) const SizedBox(height: 16),
                            _buildRecordCard(context, records[index]),
                          ],
                        ],
                        const SizedBox(height: 20),
                        _buildBottomActions(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContextBar(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios, size: 18),
            label: const Text('カレンダー'),
            style: TextButton.styleFrom(foregroundColor: _primary),
          ),
          const Row(
            children: [
              Icon(Icons.calendar_today, color: _secondary, size: 18),
              SizedBox(width: 6),
              Text('日次詳細', style: TextStyle(color: _secondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _formattedDate,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${records.length}件の記録',
              style: const TextStyle(
                color: _primary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          '測定日時の古い順（昇順）に表示しています。',
          style: TextStyle(color: _secondary, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.event_busy_outlined, size: 40, color: _secondary),
          const SizedBox(height: 12),
          Text('この日の記録はありません', style: TextStyle(color: _secondary)),
        ],
      ),
    );
  }

  Widget _buildRecordCard(BuildContext context, GlucoseRecord record) {
    final time =
        '${record.recordedAt.hour.toString().padLeft(2, '0')}:'
        '${record.recordedAt.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.schedule, color: _secondary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    time,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  record.mealTiming.label,
                  style: const TextStyle(
                    color: _primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${record.bloodSugarMgDl}',
                style: const TextStyle(
                  color: _ink,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'mg/dL',
                style: TextStyle(color: _secondary, fontSize: 14),
              ),
            ],
          ),
          if (record.memo.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes, color: _secondary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(record.memo)),
                ],
              ),
            ),
          ],
          if (record.photoPaths.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '食事の写真 (${record.photoPaths.length}枚)',
              style: const TextStyle(color: _secondary, fontSize: 13),
            ),
            const SizedBox(height: 8),
            _buildPhotoGallery(record.photoPaths),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showMockActionNotice(context, '編集'),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('編集'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: _ink,
                    backgroundColor: Colors.white,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _showMockActionNotice(context, '削除'),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('削除'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(104, 48),
                  foregroundColor: _error,
                  backgroundColor: const Color(0xFFFFDAD6),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGallery(List<String> photoPaths) {
    if (photoPaths.length == 1) {
      return Align(
        alignment: Alignment.centerLeft,
        child: SizedBox.square(dimension: 96, child: _photo(photoPaths.first)),
      );
    }
    return Row(
      children: [
        for (var index = 0; index < photoPaths.length; index++) ...[
          if (index > 0) const SizedBox(width: 8),
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: _photo(photoPaths[index]),
            ),
          ),
        ],
      ],
    );
  }

  Widget _photo(String path) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFFDCE2F7),
          alignment: Alignment.center,
          child: const Icon(Icons.restaurant, color: _secondary),
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _surfaceLow,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: _secondary, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '新規記録の入力はカレンダー画面から行えます。',
                  style: TextStyle(color: _secondary, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.calendar_month),
          label: const Text('カレンダーへ戻る'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFDCE3EC),
            foregroundColor: _ink,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  void _showMockActionNotice(BuildContext context, String action) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('記録の$actionは今後対応予定です。')));
  }
}
