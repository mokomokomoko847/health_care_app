import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/glucose_record.dart';
import '../models/glucose_record_validator.dart';
import '../services/photo_picker_service.dart';
import '../repositories/glucose_record_repository.dart';

class RecordInputPage extends StatefulWidget {
  const RecordInputPage({
    super.key,
    this.photoPickerService,
    this.repository,
    this.userId,
  });

  final PhotoPickerService? photoPickerService;
  final GlucoseRecordRepository? repository;
  final String? userId;

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
  String? _recordId;
  bool _saving = false;
  bool _hasUnsavedChanges = false;

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

  void _markChanged() {
    if (_hasUnsavedChanges) return;
    setState(() => _hasUnsavedChanges = true);
  }

  Future<void> _handleBack() async {
    if (_saving) return;
    if (!_hasUnsavedChanges) {
      Navigator.of(context).maybePop();
      return;
    }

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('入力内容が保存されていません。戻りますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('戻る'),
          ),
        ],
      ),
    );

    if (shouldDiscard != true || !mounted) return;
    setState(() => _hasUnsavedChanges = false);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.of(context).maybePop();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, now.month, now.day),
      helpText: '測定日を選択',
      cancelText: 'キャンセル',
      confirmText: '次へ',
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      helpText: '測定時刻を選択',
      cancelText: 'キャンセル',
      confirmText: '決定',
    );

    if (selectedTime == null) {
      return;
    }

    final candidate = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );
    if (candidate.isAfter(DateTime.now())) {
      _showMessage('現在より未来の日時は選択できません。');
      return;
    }
    setState(() {
      _selectedDateTime = candidate;
      _hasUnsavedChanges = true;
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
      _hasUnsavedChanges = true;
    });
  }

  void _removePhoto(String path) {
    setState(() {
      _photoPaths = _photoPaths
          .where((photoPath) => photoPath != path)
          .toList();
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _saveRecord() async {
    if (_saving) return;
    final validationResult = GlucoseRecordValidator.validate(
      recordedAt: _selectedDateTime,
      bloodSugarText: _bloodSugarController.text,
      mealTiming: _selectedMealTiming,
      memo: _memoController.text,
      photoPaths: _photoPaths,
    );

    setState(() => _validationErrors = validationResult.errors);

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

    final repository = widget.repository;
    final userId = widget.userId;
    if (repository == null || userId == null) {
      _showMessage('保存先が設定されていません。ログインし直してください。');
      return;
    }
    if (_photoPaths.isNotEmpty) {
      _showMessage('写真のクラウド保存は準備中です。写真を外して保存してください。');
      return;
    }
    setState(() => _saving = true);
    try {
      _recordId ??= repository.newRecordId();
      await repository.create(userId, _recordId!, record);
      if (!mounted) return;
      setState(() {
        _hasUnsavedChanges = false;
        _saving = false;
      });
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('保存できませんでした'),
          content: Text(recordErrorMessage(error)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        ),
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving && !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _hasUnsavedChanges) _handleBack();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          title: const Text('記録入力'),
          titleTextStyle: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          leading: IconButton(
            tooltip: '戻る',
            onPressed: _saving ? null : _handleBack,
            icon: const Icon(Icons.chevron_left),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: AbsorbPointer(
                absorbing: _saving,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  children: [
                    _buildDateTimeSection(),
                    const SizedBox(height: 24),
                    _buildBloodSugarSection(),
                    const SizedBox(height: 24),
                    _buildMealTimingSection(),
                    const SizedBox(height: 24),
                    _buildMemoSection(),
                    const SizedBox(height: 24),
                    _buildPhotoSection(),
                    if (_validationErrors.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildErrorSection(),
                    ],
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: _saving ? null : _saveRecord,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1D4ED8),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(_saving ? '保存中…' : '記録を保存'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel(title: '測定日時', requiredField: true),
        const SizedBox(height: 8),
        Material(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: _pickDateTime,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Color(0xFF4B5563),
                      size: 21,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _formatDateTime(_selectedDateTime),
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Icon(Icons.expand_more, color: Color(0xFF4B5563)),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '現在より未来の日時は選択できません。',
          style: TextStyle(color: Color(0xFF4B5563), fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildBloodSugarSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: _FieldLabel(title: '血糖値', requiredField: true),
            ),
            const Text(
              '0〜600の整数',
              style: TextStyle(color: Color(0xFF4B5563), fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _bloodSugarController,
                  onChanged: (_) => _markChanged(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '未入力',
                    hintStyle: TextStyle(
                      color: Color(0xFF4B5563),
                      fontSize: 16,
                    ),
                    isDense: true,
                  ),
                ),
              ),
              const Text(
                'mg/dL',
                style: TextStyle(
                  color: Color(0xFF4B5563),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMealTimingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel(title: '測定タイミング', requiredField: true),
        const SizedBox(height: 8),
        SegmentedButton<MealTiming>(
          showSelectedIcon: false,
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
          selected: <MealTiming>{_selectedMealTiming!},
          onSelectionChanged: (selectedValues) {
            setState(() {
              _selectedMealTiming = selectedValues.first;
              _hasUnsavedChanges = true;
            });
          },
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? const Color(0xFF1D4ED8)
                  : const Color(0xFFF3F4F6),
            ),
            foregroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? Colors.white
                  : const Color(0xFF111827),
            ),
            side: const WidgetStatePropertyAll(BorderSide.none),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMemoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: _FieldLabel(title: 'メモ', requiredField: false),
            ),
            Text(
              '${_memoController.text.length}/${GlucoseRecordValidator.maxMemoLength}',
              style: const TextStyle(color: Color(0xFF4B5563), fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _memoController,
          onChanged: (_) => setState(() => _hasUnsavedChanges = true),
          maxLength: GlucoseRecordValidator.maxMemoLength,
          maxLines: 3,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF3F4F6),
            hintText: '例：昼食後に散歩',
            contentPadding: const EdgeInsets.all(14),
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1D4ED8), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: _FieldLabel(title: '食事写真', requiredField: false),
            ),
            Text(
              '${_photoPaths.length}/${GlucoseRecordValidator.maxPhotoCount}枚',
              style: const TextStyle(color: Color(0xFF4B5563), fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _PhotoActionButton(
                icon: Icons.photo_camera,
                label: 'カメラで撮影',
                onPressed: widget.repository == null
                    ? _addPhotoFromCamera
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PhotoActionButton(
                icon: Icons.image_outlined,
                label: '写真を選択',
                onPressed: widget.repository == null
                    ? _addPhotoFromGallery
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: List<Widget>.generate(3, (index) {
            final path = index < _photoPaths.length ? _photoPaths[index] : null;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index == 2 ? 0 : 8),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: path == null
                      ? _emptyPhotoSlot(index + 1)
                      : _PhotoPreviewCard(
                          path: path,
                          onRemove: () => _removePhoto(path),
                        ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          widget.repository == null
              ? '最大3枚まで登録できます（0枚でも保存可能）'
              : '写真付きの保存は準備中です。現在は写真なしで保存できます。',
          style: const TextStyle(color: Color(0xFF4B5563), fontSize: 14),
        ),
      ],
    );
  }

  Widget _emptyPhotoSlot(int number) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add, color: Color(0xFF4B5563), size: 24),
          const SizedBox(height: 2),
          Text(
            '$number枚目',
            style: const TextStyle(color: Color(0xFF4B5563), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _validationErrors
            .map(
              (error) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  error,
                  style: const TextStyle(color: Color(0xFFB91C1C)),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    const weekdays = <String>['月', '火', '水', '木', '金', '土', '日'];
    final weekday = weekdays[dateTime.weekday - 1];
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${dateTime.year}年$month月$day日（$weekday） $hour:$minute';
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.title, required this.requiredField});

  final String title;
  final bool requiredField;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: requiredField
                ? const Color(0xFF1D4ED8)
                : const Color(0xFFDCE3EC),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            requiredField ? '必須' : '任意',
            style: TextStyle(
              color: requiredField ? Colors.white : const Color(0xFF4B5563),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _PhotoPreviewCard extends StatelessWidget {
  const _PhotoPreviewCard({required this.path, required this.onRemove});

  final String path;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            File(path),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: const Color(0xFFF3F4F6),
              alignment: Alignment.center,
              child: const Icon(Icons.broken_image_outlined),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton.filledTonal(
              tooltip: '写真を削除',
              onPressed: onRemove,
              icon: const Icon(Icons.close, size: 18),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoActionButton extends StatelessWidget {
  const _PhotoActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: FilledButton.tonalIcon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFF3F4F6),
          foregroundColor: const Color(0xFF111827),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
