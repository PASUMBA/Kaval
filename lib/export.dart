import 'dart:typed_data';

import 'package:excel/excel.dart' hide Border;
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import 'backend.dart';
import 'download_stub.dart' if (dart.library.js_interop) 'download_web.dart';
import 'models.dart';
import 'store.dart';

/// Officer export: Posts, Reports and one sheet per post with its detection
/// log (from the backend events/<postId>, falling back to in-app history).
Future<String> exportExcel(KavalStore store, {DateTimeRange? range}) async {
  bool inRange(DateTime? t) =>
      range == null ||
      (t != null &&
          !t.isBefore(range.start) &&
          t.isBefore(range.end.add(const Duration(days: 1))));
  final fmt = DateFormat('yyyy-MM-dd HH:mm:ss');
  final ex = Excel.createExcel();
  ex.rename('Sheet1', 'Posts');
  final posts = ex['Posts'];
  posts.appendRow([
    for (final h in [
      'Post ID', 'Name', 'Range', 'Status', 'Battery %', 'Issue',
      'Last detection', 'Confidence %', 'Last detection time', 'Link'
    ])
      TextCellValue(h)
  ]);
  for (final w in store.watchers) {
    final d = w.lastDetection;
    posts.appendRow([
      TextCellValue(w.id),
      TextCellValue(w.name),
      TextCellValue(w.range),
      TextCellValue(w.status.name.toUpperCase()),
      IntCellValue(w.battery),
      TextCellValue(w.issue),
      TextCellValue(d?.label ?? ''),
      d == null ? TextCellValue('') : IntCellValue((d.confidence * 100).round()),
      TextCellValue(d == null ? '' : fmt.format(d.time)),
      TextCellValue(w.isDemo ? 'Demo' : w.baseUrl ?? ''),
    ]);
  }

  Map<String, List<Map<String, dynamic>>> events = {};
  try {
    events = await Backend.fetchEvents();
  } catch (_) {}
  var reports = store.reports;
  try {
    reports = await Backend.fetchReports();
  } catch (_) {}

  final rs = ex['Reports'];
  rs.appendRow([
    for (final h in ['Time', 'Post', 'Post name', 'Type', 'Reporter', 'Phone', 'Note'])
      TextCellValue(h)
  ]);
  reports = reports.where((r) => inRange(r.time)).toList();
  for (final r in reports) {
    final w = store.watchers.where((w) => w.id == r.watcherId).firstOrNull;
    rs.appendRow([
      TextCellValue(fmt.format(r.time)),
      TextCellValue(r.watcherId),
      TextCellValue(w?.name ?? ''),
      TextCellValue(r.type),
      TextCellValue(r.reporter),
      TextCellValue(r.phone),
      TextCellValue(r.note),
    ]);
  }

  for (final w in store.watchers) {
    final sh = ex[w.id];
    sh.appendRow([
      for (final h in ['Time', 'Post', 'Type', 'Confidence %', 'Source'])
        TextCellValue(h)
    ]);
    final ev = events[w.id];
    if (ev != null && ev.isNotEmpty) {
      for (final e in ev) {
        final t = DateTime.tryParse(e['time']?.toString() ?? '')?.toLocal();
        if (!inRange(t)) continue;
        final c = (e['confidence'] ?? 0).toDouble();
        sh.appendRow([
          TextCellValue(t == null ? '' : fmt.format(t)),
          TextCellValue(w.id),
          TextCellValue((e['type'] ?? '').toString()),
          IntCellValue((c <= 1 ? c * 100 : c).round()),
          TextCellValue((e['source'] ?? 'camera').toString()),
        ]);
      }
    } else {
      for (final Detection h in w.history) {
        if (!inRange(h.time)) continue;
        sh.appendRow([
          TextCellValue(fmt.format(h.time)),
          TextCellValue(w.id),
          TextCellValue(h.type),
          IntCellValue((h.confidence * 100).round()),
          TextCellValue(h.source),
        ]);
      }
    }
  }

  final bytes = ex.encode();
  if (bytes == null) throw Exception('Could not build the Excel file');
  final tag = range == null
      ? 'all'
      : '${DateFormat('yyyyMMdd').format(range.start)}-${DateFormat('yyyyMMdd').format(range.end)}';
  final name = 'kaval_$tag.xlsx';
  const mime =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
  if (await downloadBytes(bytes, name, mime)) return name;
  await SharePlus.instance.share(ShareParams(
    files: [
      XFile.fromData(Uint8List.fromList(bytes), mimeType: mime, name: name)
    ],
    fileNameOverrides: [name],
    text: 'Kaval export · ${store.watchers.length} posts · ${reports.length} reports',
  ));
  return name;
}
