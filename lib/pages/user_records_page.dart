import 'package:flutter/material.dart';

import '../models/glucose_record.dart';
import '../repositories/glucose_record_repository.dart';
import 'calendar_page.dart';
import 'daily_detail_page.dart';

/// 月ごとの取得結果を画面内で保持し、ユーザーが変わる際はKeyで破棄する。
class UserCalendarPage extends StatefulWidget {
  const UserCalendarPage({
    super.key,
    required this.userId,
    required this.repository,
    required this.onDateSelected,
    required this.onCreateRecord,
    required this.onLogout,
  });

  final String userId;
  final GlucoseRecordRepository repository;
  final ValueChanged<DateTime> onDateSelected;
  final Future<void> Function() onCreateRecord;
  final Future<void> Function() onLogout;

  @override
  State<UserCalendarPage> createState() => _UserCalendarPageState();
}

class _UserCalendarPageState extends State<UserCalendarPage> {
  DateTime _month = DateTime.now();
  Set<DateTime> _dates = {};
  String? _error;
  bool _loading = true;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _dates = {};
      _error = null;
    });
    try {
      final records = await widget.repository.loadRange(
        widget.userId,
        DateTime(_month.year, _month.month),
        DateTime(_month.year, _month.month + 1),
      );
      // 月切替後に届いた古いリクエストで表示を上書きしない。
      if (!mounted || request != _request) return;
      setState(() {
        _dates = records.map((record) {
          final date = record.recordedAt;
          return DateTime(date.year, date.month, date.day);
        }).toSet();
        _loading = false;
      });
    } catch (error) {
      if (!mounted || request != _request) return;
      setState(() {
        _error = recordErrorMessage(error);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => CalendarPage(
    recordedDates: _dates,
    isLoading: _loading,
    loadError: _error,
    onRetry: _load,
    onMonthChanged: (month) {
      _month = month;
      _load();
    },
    onDateSelected: widget.onDateSelected,
    onCreateRecord: () async {
      await widget.onCreateRecord();
      if (mounted) _load();
    },
    onLogout: widget.onLogout,
  );
}

class UserDailyDetailPage extends StatefulWidget {
  const UserDailyDetailPage({
    super.key,
    required this.userId,
    required this.date,
    required this.repository,
  });

  final String userId;
  final DateTime date;
  final GlucoseRecordRepository repository;

  @override
  State<UserDailyDetailPage> createState() => _UserDailyDetailPageState();
}

class _UserDailyDetailPageState extends State<UserDailyDetailPage> {
  late Future<List<GlucoseRecord>> _records;

  @override
  void initState() {
    super.initState();
    _records = _load();
  }

  Future<List<GlucoseRecord>> _load() {
    final date = widget.date;
    return widget.repository.loadRange(
      widget.userId,
      DateTime(date.year, date.month, date.day),
      DateTime(date.year, date.month, date.day + 1),
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<GlucoseRecord>>(
    future: _records,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done &&
          !snapshot.hasError) {
        return DailyDetailPage(date: widget.date, records: snapshot.data!);
      }
      return Scaffold(
        appBar: AppBar(title: const Text('日次詳細')),
        body: Center(
          child: snapshot.hasError
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(recordErrorMessage(snapshot.error!)),
                    TextButton(
                      onPressed: () => setState(() => _records = _load()),
                      child: const Text('再試行'),
                    ),
                  ],
                )
              : const CircularProgressIndicator(),
        ),
      );
    },
  );
}
