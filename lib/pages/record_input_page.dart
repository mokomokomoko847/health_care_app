import 'dart:io';

import 'package:flutter/material.dart';

import '../models/glucose_record.dart';
import '../models/glucose_record_validator.dart';
import '../services/photo_picker_service.dart';

class RecordInputPage extends StatefulWidget {
  const RecordInputPage({super.key, this.photoPickerService});

  final PhotoPickerService? photoPickerService;

  @override
  State<RecordInputPage> createState() => _RecordInputPageState();
}

class _RecordInputPageState extends State<RecordInputPage> {
  final TextEditingController _bloodSugarController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  late final PhotoPickerService _photoPickerService;

  DateTime _selectedDateTime = DateTime.now();
  MealTiming? _selectedMealTiming = MealTiming.beforeMeal;
  List<String> _photoPaths = <String>[];
  List<String> _validationErrors = <String>[];
  GlucoseRecord? _lastSavedRecord;

  @override
  void initState() {
    super.initState();
    _photoPickerService = widget.photoPickerService ?? PhotoPickerService();
  }

  @override
  void dispose() {
    _bloodSugarController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: '日時を選択',
      cancelText: 'キャンセル',
      confirmText: 'OK',
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      helpText: '時刻を選択',
      cancelText: 'キャンセル',
      confirmText: 'OK',
    );

    if (selectedTime == null) {
      return;
    }

    setState(() {
      _selectedDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
    });
  }

  Future<void> _addPhotoFromCamera() async {
    await _addPhoto(_photoPickerService.pickFromCamera);
  }

  Future<void> _addPhotoFromGallery() async {
    await _addPhoto(_photoPickerService.pickFromGallery);
  }

  // 写真追加の上限チェックと、取得後の状態更新を1か所にまとめる。
  Future<void> _addPhoto(Future<String?> Function() picker) async {
    if (_photoPaths.length >= GlucoseRecordValidator.maxPhotoCount) {
      _showMessage('写真は3枚まで追加できます。');
      return;
    }

    final pickedPath = await picker();

    if (pickedPath == null || !mounted) {
      return;
    }

    setState(() {
      _photoPaths = <String>[..._photoPaths, pickedPath];
    });
  }

  void _removePhoto(String path) {
    setState(() {
      _photoPaths = _photoPaths
          .where((photoPath) => photoPath != path)
          .toList();
    });
  }

  void _saveRecord() {
    final validationResult = GlucoseRecordValidator.validate(
      recordedAt: _selectedDateTime,
      bloodSugarText: _bloodSugarController.text,
      mealTiming: _selectedMealTiming,
      memo: _memoController.text,
      photoPaths: _photoPaths,
    );

    setState(() {
      _validationErrors = validationResult.errors;
    });

    if (!validationResult.isValid) {
      _showMessage('入力内容を確認してください。');
      return;
    }

    final record = GlucoseRecord(
      recordedAt: _selectedDateTime,
      bloodSugarMgDl: int.parse(_bloodSugarController.text.trim()),
      mealTiming: _selectedMealTiming!,
      memo: _memoController.text.trim(),
      photoPaths: _photoPaths,
    );

    setState(() {
      _lastSavedRecord = record;
    });

    _showMessage('記録内容を保存準備できました。');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('血糖記録入力')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildIntroCard(),
          const SizedBox(height: 16),
          _buildDateTimeSection(),
          const SizedBox(height: 16),
          _buildBloodSugarSection(),
          const SizedBox(height: 16),
          _buildMealTimingSection(),
          const SizedBox(height: 16),
          _buildMemoSection(),
          const SizedBox(height: 16),
          _buildPhotoSection(),
          if (_validationErrors.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildErrorSection(),
          ],
          const SizedBox(height: 24),
          FilledButton(onPressed: _saveRecord, child: const Text('記録を保存')),
          if (_lastSavedRecord != null) ...[
            const SizedBox(height: 24),
            _buildSavedRecordCard(_lastSavedRecord!),
          ],
        ],
      ),
    );
  }

  Widget _buildIntroCard() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('この画面では、日時・血糖値・食前食後・メモ・写真を入力して記録内容を確認できます。'),
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return _SectionCard(
      title: '日時',
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(_formatDateTime(_selectedDateTime)),
        subtitle: const Text('初期値は現在日時です。'),
        trailing: const Icon(Icons.calendar_today),
        onTap: _pickDateTime,
      ),
    );
  }

  Widget _buildBloodSugarSection() {
    return _SectionCard(
      title: '血糖値',
      child: TextField(
        controller: _bloodSugarController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: '血糖値',
          suffixText: 'mg/dL',
          hintText: '0〜600の整数を入力',
        ),
      ),
    );
  }

  Widget _buildMealTimingSection() {
    return _SectionCard(
      title: '測定タイミング',
      child: SegmentedButton<MealTiming>(
        segments: const [
          ButtonSegment<MealTiming>(
            value: MealTiming.beforeMeal,
            label: Text('食前'),
          ),
          ButtonSegment<MealTiming>(
            value: MealTiming.afterMeal,
            label: Text('食後'),
          ),
        ],
        selected: _selectedMealTiming == null
            ? <MealTiming>{}
            : <MealTiming>{_selectedMealTiming!},
        onSelectionChanged: (selectedValues) {
          setState(() {
            _selectedMealTiming = selectedValues.isEmpty
                ? null
                : selectedValues.first;
          });
        },
      ),
    );
  }

  Widget _buildMemoSection() {
    return _SectionCard(
      title: 'メモ',
      child: TextField(
        controller: _memoController,
        maxLength: GlucoseRecordValidator.maxMemoLength,
        maxLines: 3,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: '補足があれば入力してください',
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return _SectionCard(
      title: '食事写真',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '追加済み: ${_photoPaths.length} / ${GlucoseRecordValidator.maxPhotoCount}枚',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: _addPhotoFromCamera,
                icon: const Icon(Icons.photo_camera),
                label: const Text('カメラで撮影'),
              ),
              OutlinedButton.icon(
                onPressed: _addPhotoFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('写真を選択'),
              ),
            ],
          ),
          if (_photoPaths.isEmpty) ...[
            const SizedBox(height: 12),
            const Text('まだ写真は追加されていません。'),
          ] else ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _photoPaths
                  .map(
                    (path) => _PhotoPreviewCard(
                      path: path,
                      onRemove: () => _removePhoto(path),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorSection() {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _validationErrors
              .map(
                (error) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(error),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  // 保存ボタンで組み立てられた記録を画面に出し、入力結果を確認しやすくする。
  Widget _buildSavedRecordCard(GlucoseRecord record) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '保存内容の確認',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('日時: ${_formatDateTime(record.recordedAt)}'),
            Text('血糖値: ${record.bloodSugarMgDl} mg/dL'),
            Text('測定タイミング: ${record.mealTiming.label}'),
            Text('メモ: ${record.memo.isEmpty ? '未入力' : record.memo}'),
            Text('写真枚数: ${record.photoPaths.length}枚'),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${dateTime.year}/$month/$day $hour:$minute';
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _PhotoPreviewCard extends StatelessWidget {
  const _PhotoPreviewCard({required this.path, required this.onRemove});

  final String path;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(path),
              width: 110,
              height: 110,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 110,
                  height: 110,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onRemove, child: const Text('削除')),
        ],
      ),
    );
  }
}
